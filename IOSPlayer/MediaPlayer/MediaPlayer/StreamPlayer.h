//
//  StreamPlayer.h
//  MediaPlayer
//
//  Created by XYZHENU on 2020/7/27.
//  Copyright © 2020 jizan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "H264HwDecoder.h"
NS_ASSUME_NONNULL_BEGIN

@interface StreamPlayer : UIView
@property (nonatomic,strong) H264HwDecoder* decoder;
- (void)play:(NSString*)url;
@end

NS_ASSUME_NONNULL_END
