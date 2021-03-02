#import "MediaPlayer.h"
#import "Player/MediaPlayer.h"
#import <memory>
#import "Util/onceToken.h"
#import "Poller/EventPoller.h"
#import "Rtsp/UDPServer.h"
#import "MediaDecoder.h"
#import "AutoAudioPlayer.h"
#import "AudioDec/AudioDec.h"
#import "Util/ResourcePool.h"
#import "Util/RingBuffer.h"
#import <vector>
#import <deque>
#import <mutex>
#import "Thread/ThreadPool.h"
#import "Util/TimeTicker.h"
#import <atomic>
#import <math.h>
#import "WeakArray.h"
#import "mk_player.h"
#import "mk_thread.h"
using namespace std;
using namespace toolkit;
using namespace mediakit;
using namespace mediakit::Rtsp;

#define PCM_BUF_SIZE (1024*2)
//最大包长度 1 秒
#define MAX_BUF_SECOND (1)


struct PCM_PKT
{
    string data;
    uint32_t timeStamp;
};

static atomic_int g_yuvCount(0);
@implementation YuvFrame
-(id) initWithRef:(CVImageBufferRef)ref pts:(uint32_t)pts dts:(uint32_t)dts{
    self = [self init];
    if (self) {
        _frame  =   CVPixelBufferRetain(ref);
        _pts    =   pts;
        _dts    =   dts;
        //DebugL  <<
        g_yuvCount++;
    }
    return self;
}
-(void) dealloc{
    CVPixelBufferRelease(_frame);
    g_yuvCount--;
}
@end

static shared_ptr<ThreadPool> s_videoDecodeThread; //全局的视频渲染时钟
static shared_ptr<Ticker> s_screenIdleTicker;//熄屏定时器

static onceToken token([](){
    Logger::Instance().add(std::make_shared<ConsoleChannel>("stdout",LTrace));
    EventPoller::Instance();
    
    s_videoDecodeThread.reset(new ThreadPool(1)); //全局的视频渲染时钟
    s_screenIdleTicker.reset(new Ticker);//熄屏定时器
    
    mk_timer_create(mk_thread_from_pool(), 3*1000, [](void *user_data) -> uint64_t {
        if(s_screenIdleTicker->elapsedTime() > 3 * 1000){
            //熄灭屏幕
            if([UIApplication sharedApplication].idleTimerDisabled){
                [UIApplication sharedApplication].idleTimerDisabled = false;
            }
        }
        return 0;
    }, nullptr);
    
},[](){
    s_videoDecodeThread.reset();
    s_screenIdleTicker.reset();
    
//    UDPServer::Destory();
//    EventPoller::Destory();
//    Logger::Destory();
});

@implementation MediaPlayerOC
{
    mediakit::MediaPlayer::Ptr _rtxpPlayer;//rtmp/rtsp播放器
    mk_player _player;
    
    uint32_t _audioPktMS;//每个音频包的时长（单位毫秒）
    uint32_t _playedAudioStamp;//被播放音频的时间戳
    uint32_t _firstVideoStamp;//起始视频时间戳
    
    Ticker _systemStamp;//系统时间戳
    Ticker _onPorgressStamp;//记录上次触发onPorgress回调的时间戳
    
    shared_ptr<AudioDec> _aacDec;//aac软件解码器
    AutoAudioPlayer *_audioPlayer;//音频播放器
    RingBuffer<PCM_PKT>::Ptr _audioBuffer;//音频环形缓存
    RingBuffer<PCM_PKT>::RingReader::Ptr _audioReader;//音频环形缓存读取器
    
    recursive_mutex _mtx_mapYuv;//yuv视频缓存锁
    multimap<uint32_t,YuvFrame *> _mapYuv;//yuv视频缓存
    MediaDecoder *_h264Decoder;//h264硬件解码器
    
    NSString *_arg_url;
}
+(NSError *)toNSError:(const SockException &)ex{
    if(!ex){
        return nil;
    }
    return [NSError errorWithDomain:[NSString stringWithUTF8String:ex.what()] code:ex.getErrCode() userInfo:nil];
}
-(NSString *)url{
    return _arg_url;
}
-(id)init{
    self=[super init];
    if (self) {
        __weak typeof(self) weakSelf=self;
        
        _player = mk_player_create();
        
        mk_player_set_on_shutdown(_player, [](void *user_data,int err_code,const char *err_msg){
            MediaPlayerOC* weakSelf = (__bridge MediaPlayerOC*)user_data;
            if (!weakSelf) {
                return;
            }
            typeof(self) strongSelf = weakSelf;
            strongSelf->_playing = err_code==0;
            NSError *err = [NSError errorWithDomain:[NSString stringWithUTF8String:err_msg] code:err_code userInfo:nil];
            dispatch_async(dispatch_get_main_queue(), ^{
                if([strongSelf->_delegate respondsToSelector:@selector(mediaPlayer:onShutdown:)]){
                    [strongSelf->_delegate mediaPlayer:strongSelf onShutdown:err];
                }
            });
        }, (__bridge void*)weakSelf);
        
        mk_player_set_on_data(_player, [](void *user_data,int track_type,int codec_id,void *data,int len,uint32_t dts,uint32_t pts){
            MediaPlayerOC* weakSelf = (__bridge MediaPlayerOC*)user_data;
            if (!weakSelf || weakSelf.pause) {
                return;
            }
            typeof(self) strongSelf = weakSelf;
            switch (codec_id) {//0：H264，1：H265，2：AAC 3.G711A 4.G711U
                case 0:
                    
                    break;
                case 2:
                    if (!strongSelf.enableAudio) {
                        break;
                    }
                    
                default:
                    break;
            }
        }, (__bridge void*)weakSelf);
        
        _enableAudio=true;
        _pause=false;
       
        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidEnterBackgroundNotification
                                                          object:nil
                                                           queue:nil
                                                      usingBlock:^(NSNotification * _Nonnull note) {
                                                          if(!weakSelf){
                                                              return;
                                                          }
                                                          __strong typeof(self) strongSelf = weakSelf;
                                                          strongSelf.pause = true;
                                                          dispatch_async(dispatch_get_main_queue(), ^{
                                                              if([strongSelf->_delegate respondsToSelector:@selector(mediaPlayerOnAutoPaused:)]){
                                                                  [strongSelf->_delegate mediaPlayerOnAutoPaused:strongSelf];
                                                              }
                                                          });
            
        }];
    }
    return self;
}
-(void) onRecvAudio:(const AdtsFrame &)data{
    if (!self.enableAudio || self.pause) {
        return;
    }
    __weak typeof(self) weakSelf=self;
    s_videoDecodeThread->async([weakSelf,data](){
        if(!weakSelf){
            return;
        }
        typeof(self) strongSelf=weakSelf;
        [strongSelf onAAC:data];
    });
}
-(void) onRecvVideo:(const H264Frame &)data{
    if (self.pause) {
        return;
    }
    __weak typeof(self) weakSelf=self;
    s_videoDecodeThread->async([weakSelf,data](){
        if(!weakSelf){
            return;
        }
        typeof(self) strongSelf=weakSelf;
        [strongSelf onH264:data];
    });
}
-(void) onH264:(const H264Frame &)data{
    if(_pause){
        return;
    }
    [self tickProgress];
    if (!_h264Decoder && _player && data.type == 5) {
        NSData *sps=[NSData dataWithBytes:_rtxpPlayer->getSps().data()+4 length:_rtxpPlayer->getSps().length()-4];
        NSData *pps=[NSData dataWithBytes:_rtxpPlayer->getPps().data()+4 length:_rtxpPlayer->getPps().length()-4];
        _h264Decoder =[[MediaDecoder alloc] initH264DecoderWithSPS:sps PPS:pps];
        _h264Decoder.delegate=self;
        
        _h264Parser.inputH264(_rtxpPlayer->getSps(),0);
        _h264Parser.inputH264(_rtxpPlayer->getPps(),0);
    }
    if (_h264Decoder) {
        [self decodeOneFrame:data];
    }
}

-(void)rePlay{
    if(_arg_url){
        [self play:_arg_url];
    }
}
-(void) setOption:(NSString *) key intValue:(int)val{
    (*_rtxpPlayer)[[key UTF8String]] = val;
}
-(void) setOption:(NSString *) key stringValue:(NSString *)val{
    (*_rtxpPlayer)[[key UTF8String]] = [val UTF8String];
}
-(void) play:(NSString *)url{
    
    [self teardown];
    _arg_url = url;
    
    __weak typeof(self) weakSelf = self;
    _rtxpPlayer->setOnPlayResult([weakSelf](const SockException &ex){
        if (!weakSelf) {
            return;
        }
        typeof(self) strongSelf = weakSelf;
        strongSelf->_playing = !ex;
        NSError *err = [MediaPlayerOC toNSError:ex];
        dispatch_async(dispatch_get_main_queue(), ^{
            if([strongSelf->_delegate respondsToSelector:@selector(mediaPlayer:onPlayResult:)]){
                [strongSelf->_delegate mediaPlayer:strongSelf onPlayResult:err];
            }
        });
    });
    _rtxpPlayer->play([url UTF8String]);
}

-(void)teardown{
    _rtxpPlayer->teardown();
    _playing = false;
    _pause=true;
    _h264Decoder=nil;
    _audioPlayer=nil;
    _aacDec.reset();
    _audioBuffer.reset();
    _pause=false;
    _playedAudioStamp=0;
    _firstVideoStamp=0;
    _audioPktMS = 0;
    _systemStamp.resetTime();
    lock_guard<recursive_mutex> lck(_mtx_mapYuv);
    _mapYuv.clear();
}
-(void)dealloc{
    [self teardown];
}

-(void)tickProgress{
    if( _onPorgressStamp.elapsedTime() > 300 && _rtxpPlayer->getDuration() > 0){
        _onPorgressStamp.resetTime();
        float progress = _rtxpPlayer->getProgress();
        dispatch_async(dispatch_get_main_queue(), ^{
            if([_delegate respondsToSelector:@selector(mediaPlayer:onProgress:)]){
                [_delegate mediaPlayer:self onProgress:progress];
            }
        });
    }
}

-(void) onAAC:(const AdtsFrame &)data{
    if(_pause){
        return;
    }
    [self tickProgress];
    if(!_aacDec){
        _aacDec.reset(new AudioDec());
        _aacDec->Init(data.data);
        _audioPktMS=1000*PCM_BUF_SIZE/(_aacDec->getChannels()*_aacDec->getSamplerate()*_aacDec->getSamplebit()/8);
        _audioBuffer.reset(new RingBuffer<PCM_PKT>(MAX_BUF_SECOND * 1000 / _audioPktMS));
        _audioReader=_audioBuffer->attach(false);
    }
    uint8_t *pcm;
    int pcmLen=_aacDec->InputData(data.data, data.aac_frame_length, &pcm);
    int offset=0;
    int i=0;
    while (pcmLen>=PCM_BUF_SIZE) {
        PCM_PKT pkt;
        pkt.data.assign((char *)pcm+offset,PCM_BUF_SIZE);
        pkt.timeStamp=data.timeStamp+_audioPktMS*(i++);
        _audioBuffer->write(pkt);
        pcmLen-=PCM_BUF_SIZE;
        offset+=PCM_BUF_SIZE;
    }
    
    if(!_audioPlayer){
        _audioPlayer=[[AutoAudioPlayer alloc] init];
        _audioPlayer.delegate=self;
        [_audioPlayer StartPlay];
    }
}

-(int) videoHeight{
    return _rtxpPlayer->getVideoHeight();
}
-(int) videoWidth{
    return _rtxpPlayer->getVideoWidth();
}
-(float) videoFps{
    return _rtxpPlayer->getVideoFps();
}
-(int) audioSampleRate{
    return _rtxpPlayer->getAudioSampleRate();
}
-(int) audioSampleBit{
    return _rtxpPlayer->getAudioSampleBit();
}
-(int) audioChannel{
    return _rtxpPlayer->getAudioChannel();
}

-(bool) containAudio{
    return _rtxpPlayer->containAudio();
}
-(bool) containVideo{
    return _rtxpPlayer->containVideo();
}
-(bool) isInited{
    return _rtxpPlayer->isInited();
}
-(float)duration{
    return _rtxpPlayer->getDuration();
}
-(void)setProgress:(float)progress{
    {
        lock_guard<recursive_mutex> lck(_mtx_mapYuv);
        _mapYuv.clear();
        if(_audioReader){
            _audioReader->reset(false);
        }
    }
    [self setPause:false playerPause:false];
    _onPorgressStamp.resetTime();
    _rtxpPlayer->seekTo(progress);
}
-(float)progress{
    return _rtxpPlayer->getProgress();
}
-(void)setEnableAudio:(bool)enableAudio{
    if(_enableAudio == enableAudio){
        return;
    }
    _enableAudio=enableAudio;
    
    if(_pause && !_enableAudio){
        //暂停中开启声音无效
        return;
    }
    [_audioPlayer Pause:!_enableAudio];
}
-(void)setPause:(bool)pause playerPause:(bool) flag
{
    if(_pause == pause){
        return;
    }
    _pause=pause;
    if(flag){
        _rtxpPlayer->pause(pause);
    }
    
    if(_pause && !_enableAudio){
        //暂停中开启声音无效
        return;
    }
    [_audioPlayer Pause:!_enableAudio];
}
-(void)setPause:(bool)pause{
    [self setPause:pause playerPause:true];
}

-(int)getPCMBufferSize{
    return PCM_BUF_SIZE;
}
-(int)getPCMSampleBit{
    return _aacDec->getSamplebit();
}
-(int)getPCMSampleRate{
    return (int)_aacDec->getSamplerate();
}
-(int)getPCMChannel{
    return _aacDec->getChannels();
}
-(int)ReadPCM:(char *)buf Size:(int)bufsize{
    auto pkt=_audioReader->read();
    if (pkt) {
        _playedAudioStamp=pkt->timeStamp;
        memcpy(buf, pkt->data.data(), pkt->data.size());
        return (int)pkt->data.size();
    }
    return 0;
}

-(bool)decodeOneFrame:(const H264Frame &)data{
    _h264Parser.inputH264(data.data,data.timeStamp);
    auto naluType   =   _h264Parser.getNaluType();
    if(naluType != media::H264NALU::kIDRSlice && naluType != media::H264NALU::kNonIDRSlice){
        return false;
    }
    uint64_t ptr    =   _h264Parser.getPts() | ((uint64_t)data.timeStamp << 32);
    //DebugL << _h264Parser.getPts()  << " " << data.timeStamp;
    return [_h264Decoder decodeOneVideoFrame:(uint8_t *)data.data.data()
                                         len:data.data.size()
                                    userData:(void *)(ptr)];
}

- (void)onDecoded:(CVImageBufferRef )imageBuffer userData:(void *)userData{
    uint32_t pts                =   reinterpret_cast<uint64_t>(userData) & 0xFFFFFFFF;
    uint32_t dts                =   reinterpret_cast<uint64_t>(userData) >> 32;
    //DebugL << pts  << " " << dts;
    if (!_firstVideoStamp) {
        _firstVideoStamp=pts;
        __weak typeof(self) weakSelf=self;
        s_videoRenderTimer->CancelTask(reinterpret_cast<uint64_t>(self));
        s_videoRenderTimer->DoTaskDelay(reinterpret_cast<uint64_t>(self), 10, [weakSelf](){
            if(!weakSelf){
                return false;
            }
            typeof(self) strongSelf=weakSelf;
            [strongSelf onDrawFrame];
            return true;
        });
    }
    lock_guard<recursive_mutex> lck(_mtx_mapYuv);
    _mapYuv.emplace(pts,[[YuvFrame alloc] initWithRef:imageBuffer pts:pts dts:dts]);
    if (_mapYuv.rbegin()->second.pts - _mapYuv.begin()->second.pts >  1000 * MAX_BUF_SECOND) {
        _mapYuv.erase(_mapYuv.begin());
    }
}


-(void) onDrawFrame{
    //TimeTicker();
    if(_pause){
        return;
    }
    YuvFrame *headFrame;
    {
        lock_guard<recursive_mutex> lck(_mtx_mapYuv);
        if (_mapYuv.empty()) {
            return;
        }
        headFrame   = _mapYuv.begin()->second;//首帧
        _mapYuv.erase(_mapYuv.begin());// 消费第一帧
    }
    
    auto referencedStamp        = _playedAudioStamp;
    if (abs((int32_t)(_playedAudioStamp - headFrame.pts)) > MAX_BUF_SECOND * 1000) {
        //没有音频或则
        if(_systemStamp.elapsedTime() > 5 * 1000){
            //时间戳每5秒修正一次
            _firstVideoStamp    = headFrame.pts;
            _systemStamp.resetTime();
        }
        referencedStamp         = _firstVideoStamp+_systemStamp.elapsedTime();
    }
    if(headFrame.pts > referencedStamp + _audioPktMS/2){
        //不应该播放,重新放回列队
        lock_guard<recursive_mutex> lck(_mtx_mapYuv);
        _mapYuv.emplace(headFrame.pts,headFrame);
        return;
    }
    //播放图像
    _frame = headFrame;
    if([_delegate respondsToSelector:@selector(mediaPlayer:onDrawFrame:)]){
        [_delegate mediaPlayer:self onDrawFrame:headFrame];
    }
    if(_pauseAuto){
        _pauseAuto = false;
        self.pause = true;
        dispatch_async(dispatch_get_main_queue(), ^{
            if([_delegate respondsToSelector:@selector(mediaPlayerOnAutoPaused:)]){
                [_delegate mediaPlayerOnAutoPaused:self];
            }
        });
    }
    
    //禁止熄屏
    s_screenIdleTicker->resetTime();
    if(![UIApplication sharedApplication].idleTimerDisabled){
        [UIApplication sharedApplication].idleTimerDisabled = true;
    }
}

@end

@implementation MediaPlayerHelper
{
    NSMutableDictionary *_dic_player;
    NSMutableDictionary *_dic_delegate;
}
-(id) init{
    self = [super init];
    if (self) {
        _dic_player = [NSMutableDictionary dictionary];
        _dic_delegate = [NSMutableDictionary dictionary];
    }
    return self;
}
+(instancetype) Instance{
    static MediaPlayerHelper *instance = Nil;
    if(!instance){
        instance = [[MediaPlayerHelper alloc] init];
    }
    return instance;
}
-(MediaPlayerOC *)getPlayer:(NSString *) url{
    return _dic_player[url];
}
-(void) addDelegate:(id<MediaPlayerDelegate>) delegate withUrl:(NSString *)url{
    WeakArray *delegateList = _dic_delegate[url];
    if(!delegateList){
        //未找到代理列表，新建之并插入字典
        delegateList = [[WeakArray alloc] init];
        [_dic_delegate setObject:delegateList forKey:url];
    }
    //把代理加入代理列表
    [delegateList addObject:delegate];
    
    MediaPlayerOC *player  = _dic_player[url];
    if(player){
        //播放器已存在
        [self mediaPlayer:player onDrawFrame:player.frame];
        return;
    }
    
    //播放器未存在，则新建播放器
    player = [[MediaPlayerOC alloc] init];
    player.delegate = self;
    [player setOption:[NSString stringWithUTF8String:RtspPlayer::kRtpType] intValue:PlayerBase::eRtpType::RTP_TCP];
    [player play:url];
    //把新建的播放器插入字典
    [_dic_player setObject:player forKey:url];
}
-(void) removeDelegate:(id<MediaPlayerDelegate>) delegate withUrl:(NSString *)url{
    WeakArray *delegateList = _dic_delegate[url];
    if(!delegateList){
        //代理列表未找到则返回
        return;
    }
    //删除代理
    [delegateList removeObject:delegate];
    //找到代理的强引用列表
    NSArray *strongRef = delegateList.strongRef;
    if(strongRef.count){
        //如果代理列表还有强引用则返回
        return;
    }
    //该代理列表中未包含有效代理，则清空之
    [_dic_player removeObjectForKey:url];
    [_dic_delegate removeObjectForKey:url];
}
-(NSMutableArray *_Nonnull) getStrongDelegateList:(MediaPlayerOC *)player{
    if([[NSThread currentThread] isMainThread]){
        WeakArray *delegateList = _dic_delegate[ player.url];
        if(!delegateList){
            //未找到代理？这个逻辑不可达应该
            return nil;
        }
        //获取代理列表强引用列表
        return delegateList.strongRef;
    }
    __block NSMutableArray *strongArr;
    dispatch_sync(dispatch_get_main_queue(), ^{
        WeakArray *delegateList = _dic_delegate[ player.url];
        if(!delegateList){
            //未找到代理？这个逻辑不可达应该
            return;
        }
       strongArr = delegateList.strongRef;
    });
    return strongArr;
}
-(void) mediaPlayer:(MediaPlayerOC *)player onProgress:(float)progress{
    NSArray *strongArr = [self getStrongDelegateList:player];
    for (id<MediaPlayerDelegate> delegate in strongArr) {
        if([delegate respondsToSelector:@selector(mediaPlayer:onProgress:)]){
            [delegate mediaPlayer:player onProgress:progress];
        }
    }
}
-(void) mediaPlayer:(MediaPlayerOC *)player onShutdown:(NSError *)err{
    NSArray *strongArr = [self getStrongDelegateList:player];
    for (id<MediaPlayerDelegate> delegate in strongArr) {
        if([delegate respondsToSelector:@selector(mediaPlayer:onShutdown:)]){
            [delegate mediaPlayer:player onShutdown:err];
        }
    }
}
-(void) mediaPlayer:(MediaPlayerOC *)player onPlayResult:(NSError *)err{
    NSArray *strongArr = [self getStrongDelegateList:player];
    for (id<MediaPlayerDelegate> delegate in strongArr) {
        if([delegate respondsToSelector:@selector(mediaPlayer:onPlayResult:)]){
            [delegate mediaPlayer:player onPlayResult:err];
        }
    }
}
-(void) mediaPlayer:(MediaPlayerOC *)player onDrawFrame:(YuvFrame *)frame{
    NSMutableArray *strongArr = [self getStrongDelegateList:player];
    for (id<MediaPlayerDelegate> delegate in strongArr) {
        if([delegate respondsToSelector:@selector(mediaPlayer:onDrawFrame:)]){
            [delegate mediaPlayer:player onDrawFrame:frame];
        }
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
         [strongArr removeAllObjects];
    });
    
   
}
-(void) mediaPlayerOnAutoPaused:(MediaPlayerOC *)player{
    NSArray *strongArr = [self getStrongDelegateList:player];
    for (id<MediaPlayerDelegate> delegate in strongArr) {
        if([delegate respondsToSelector:@selector(mediaPlayerOnAutoPaused:)]){
            [delegate mediaPlayerOnAutoPaused:player];
        }
        
    }
}

@end
