#import "VC_rtmpPusher.h"
#import <thread>
#import <memory>
#include "Rtsp/RtspSession.h"
#include "Rtmp/RtmpSession.h"
#include "Rtmp/RtmpPusher.h"
#include "Http/HttpSession.h"
#include "Common/config.h"
#include "Util/logger.h"
#include "Device/PlayerProxy.h"
#include "Network/TcpServer.h"
#include "Network/sockutil.h"
#import "WaitingHUD.h"

using namespace std;
using namespace ZL::Http;
using namespace ZL::Rtsp;
using namespace ZL::Rtmp;
using namespace ZL::DEV;
using namespace ZL::Util;
using namespace ZL::Network;

@interface VC_rtmpPusher ()
@end

@implementation VC_rtmpPusher
{
    __weak IBOutlet UITextField *_txt_url;
    __weak IBOutlet UILabel *lb_message;
    std::shared_ptr<RtmpPusher> _rtmpPusher;
    std::shared_ptr<PlayerProxy> _player;
    TcpServer::Ptr rtspSrv;
    TcpServer::Ptr rtmpSrv;
    TcpServer::Ptr httpSrv;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    /*配置文件路径，否则没写hls文件的权限*/
    NSMutableString *str = [NSMutableString stringWithString:NSTemporaryDirectory()];
    [str appendString:@"httpRoot/"];
    mINI::Instance()[Config::Http::kRootPath] = [str UTF8String];
    mINI::Instance()[Config::Hls::kFilePath] = [str UTF8String];
    /*启动各种服务*/
    rtspSrv.reset(new TcpServer());
    rtmpSrv.reset(new TcpServer());
    httpSrv.reset(new TcpServer());
    try{
        rtspSrv->start<RtspSession>(mINI::Instance()[Config::Rtsp::kPort]);
        rtmpSrv->start<RtmpSession>(mINI::Instance()[Config::Rtmp::kPort]);
        httpSrv->start<HttpSession>(mINI::Instance()[Config::Http::kPort]);
    }catch(std::exception &ex){
        [UIView showToastInfo:[NSString stringWithFormat:@"%s",ex.what()]];
    }
    /*拉流*/
    _player.reset(new PlayerProxy(DEFAULT_VHOST,"live","push"));
    _player->play("rtsp://jizan.iok.la/live/1");
    _txt_url.text =@"rtmp://jizan.iok.la/live/push";
    /*拉流成功事件*/
    __weak typeof(self) weakSelf = self;
    NoticeCenter::Instance().addListener((__bridge void *)self, Config::Broadcast::kBroadcastMediaChanged, [weakSelf](BroadcastMediaChangedArgs){
        if(!bRegist || schema != RTMP_SCHEMA){
            return;
        }
        string ip = SockUtil::get_local_ip();
        dispatch_sync(dispatch_get_main_queue(), ^{
            [UIView showToastSuccess:[NSString stringWithFormat:@"拉流成功，请点击推流按钮开始推流！"]];
            __strong typeof(self) strongSelf = weakSelf;
            strongSelf->lb_message.text = [NSString stringWithFormat:
                               @"拉流成功,请用播放器打开:"
                               "\nrtsp://%s/live/push,"
                               "\nrtmp://%s/live/push,"
                               "\nhttp://%s/live/push.flv,"
                               "\nhttp://%s/live/push/hls.m3u8",
                               ip.data(),ip.data(),ip.data(),ip.data()];
        });
    });
}
-(void) dealloc{
    NoticeCenter::Instance().delListener((__bridge void *)self);
}
- (IBAction)click_push:(id)sender {
    /*推流*/
    _rtmpPusher.reset(new RtmpPusher(DEFAULT_VHOST,"live","push"));
    NSString *url = _txt_url.text;
    _rtmpPusher->setOnPublished([url](const SockException &ex){
        dispatch_sync(dispatch_get_main_queue(), ^{
            if(ex){
                 [UIView showToastInfo:[NSString stringWithFormat:@"推流失败:%s",ex.what()]];
            }else{
                 [UIView showToastSuccess:[NSString stringWithFormat:@"推流成功,请用播放器打开:%@",url]];
            }
        });
    });
    _rtmpPusher->setOnShutdown([](const SockException &ex){
        dispatch_sync(dispatch_get_main_queue(), ^{
            [UIView showToastInfo:[NSString stringWithFormat:@"已经停止推流:%s",ex.what()]];
        });
    });
    _rtmpPusher->publish([_txt_url.text UTF8String]);
}


@end
