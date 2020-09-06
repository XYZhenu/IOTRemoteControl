#import "VC_player.h"
#import <objc/runtime.h>
#import "GLView.h"
#import "WaitingHUD.h"
@interface VC_player ()

@end

@implementation VC_player
{
    __weak IBOutlet GLView *screen;
    MediaPlayerOC *_player;
    __weak IBOutlet UITextField *txt_url;
    __weak IBOutlet UISlider *slider;
    bool isSlidering;
    __weak IBOutlet NSLayoutConstraint *con_ration;
}
-(void)dealloc{
    [[MediaPlayerHelper Instance] removeDelegate:self withUrl:_player.url];
}
- (IBAction)onSliderComplete:(id)sender {
    _player.progress = slider.value;
    isSlidering = false;
}
- (IBAction)onSliderStart:(id)sender {
    isSlidering = true;
}

- (IBAction)click_play:(id)sender {
    _player = [[MediaPlayerOC alloc] init];
    _player.delegate = self;
    [_player play:txt_url.text];
    _player.pauseAuto = false;
}
-(void) mediaPlayer:(MediaPlayerOC *)player onProgress:(float)progress{
     slider.value = progress;
}
-(void) mediaPlayer:(MediaPlayerOC *)player onDrawFrame:(YuvFrame *)frame{
    [screen drawFrame:frame];
}
-(void) mediaPlayer:(MediaPlayerOC *)player onPlayResult:(NSError *)err{
    if (!err)  {
        [UIView showToastSuccess:@"播放成功"];
        slider.hidden = player.duration <=0;
        con_ration.constant = player.videoWidth / player.videoHeight;
        [screen updateConstraintsIfNeeded];
    }else{
        [UIView showToastInfo:[NSString stringWithFormat:@"%@",err]];
    }
}
-(void) mediaPlayer:(MediaPlayerOC *)player onShutdown:(NSError *)err{
    [UIView showToastInfo:[NSString stringWithFormat:@"停止播放:%@",err]];
    slider.hidden = true;
}
-(void) mediaPlayerOnAutoPaused:(MediaPlayerOC *)player{
}
- (void)viewDidLoad {
    [super viewDidLoad];
    txt_url.text =@"rtmp://120.76.24.28/live/test?token=1677193e-1244-49f2-8868-13b3fcc31b17";
    slider.hidden = true;
    slider.value = 0;
    [self click_play:nil];
}

- (IBAction)switch_pause:(UISwitch *)sender {
    _player.pause=sender.on;
}
- (IBAction)switch_audio:(UISwitch *)sender {
    _player.enableAudio=sender.on;
}

@end
