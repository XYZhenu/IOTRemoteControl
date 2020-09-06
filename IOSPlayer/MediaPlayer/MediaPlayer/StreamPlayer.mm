//
//  StreamPlayer.m
//  MediaPlayer
//
//  Created by XYZHENU on 2020/7/27.
//  Copyright © 2020 jizan. All rights reserved.
//

#import "StreamPlayer.h"
#import <mk_player.h>
#import <mk_thread.h>
@interface StreamPlayer ()
{
    mk_player _player;
    void* data_video;
    int len_video;
    uint32_t _pts;
    uint32_t _dts;
}
@end

@implementation StreamPlayer
- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.decoder = [[H264HwDecoder alloc] init];
        self.decoder.showType = H264HWDataType_Layer;
        self.decoder.displayLayer = [[AVSampleBufferDisplayLayer alloc] init];
        self.decoder.displayLayer.frame = self.bounds;
        self.decoder.displayLayer.position = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
        self.decoder.displayLayer.videoGravity = AVLayerVideoGravityResizeAspect;
        self.decoder.displayLayer.opaque = YES;
        [self.layer addSublayer:self.decoder.displayLayer];
        [self initPlayer];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.decoder.displayLayer.frame = self.bounds;
    self.decoder.displayLayer.position = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    self.decoder.displayLayer.videoGravity = AVLayerVideoGravityResizeAspect;
}

- (void) initPlayer {
    _player = mk_player_create();
    __weak typeof(self) weakSelf = self;
    mk_player_set_on_shutdown(_player, [](void *user_data,int err_code,const char *err_msg){
        StreamPlayer* weakSelf = (__bridge StreamPlayer*)user_data;
        if (!weakSelf) {
            return;
        }
        
        
    }, (__bridge void*)weakSelf);
    
    mk_player_set_on_data(_player, [](void *user_data,int track_type,int codec_id,void *data,int len,uint32_t dts,uint32_t pts){
        StreamPlayer* weakSelf = (__bridge StreamPlayer*)user_data;
        if (!weakSelf) {
            return;
        }
        
        switch (codec_id) {//0：H264，1：H265，2：AAC 3.G711A 4.G711U
            case 0:
                [weakSelf onVideoData:data len: len dts:dts pts:pts];
                break;
            default:
                break;
        }
        
    }, (__bridge void*)weakSelf);
    
    mk_player_set_on_result(_player, [](void *user_data,int err_code,const char *err_msg){
        StreamPlayer* weakSelf = (__bridge StreamPlayer*)user_data;
        if (!weakSelf) {
            return;
        }
        
        
    }, (__bridge void*)weakSelf);
}

-(void)onVideoData:(void*)data len:(int)len dts:(uint32_t)dts pts:(uint32_t)pts {
    __weak typeof(self) weakSelf = self;
    data_video = data;
    len_video = len;
    _dts = dts;
    _pts = pts;
    mk_async_do(mk_thread_from_pool(), [](void *user_data){
        StreamPlayer* weakSelf = (__bridge StreamPlayer*)user_data;
        if (!weakSelf) {
            return;
        }
        [weakSelf.decoder decodeH264VideoData:(uint8_t *)weakSelf->data_video videoSize:weakSelf->len_video dts:weakSelf->_dts pts:weakSelf->_pts];
    }, (__bridge void*)weakSelf);
}

- (void)dealloc
{
    mk_player_release(_player);
}

- (void)play:(NSString*)url {
    mk_player_play(_player, url.UTF8String);
}
@end
