//
//  ViewController.m
//  KitTest
//
//  Created by XYZHENU on 2020/7/28.
//  Copyright © 2020 jizan. All rights reserved.
//

#import "ViewController.h"
#import <StreamPlayer.h>
#import "JoyStick.h"
@interface ViewController ()
@property (nonatomic,strong) StreamPlayer* player;
@property (nonatomic,strong) JoyStick* control;
@property (weak, nonatomic) IBOutlet UITextField *textField;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.player = [[StreamPlayer alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:self.player];
    self.control = [[JoyStick alloc] initWithFrame:CGRectMake(self.view.frame.size.width-100, self.view.frame.size.height-100, 100, 100)];
    [self.view addSubview:self.control];
    [self.control setCallBack:^(CGFloat x, CGFloat y) {
        
    }];
    self.textField.text = @"rtsp://192.168.1.4/live/test";
    // Do any additional setup after loading the view.
}
-(void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.player.frame = self.view.bounds;
    [self.view sendSubviewToBack:self.player];
    self.control.frame = CGRectMake(self.view.frame.size.width-100, self.view.frame.size.height-100, 100, 100);
}
- (IBAction)play:(id)sender {
    if(self.textField.text){
        [self.player play:self.textField.text];
    }
    
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
