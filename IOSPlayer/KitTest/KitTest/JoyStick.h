//
//  JoyStick.h
//  KitTest
//
//  Created by XYZHENU on 2020/9/6.
//  Copyright © 2020 jizan. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface JoyStick : UIView
-(void)setCallBack:(void(^)(CGFloat,CGFloat))callback;
@end

NS_ASSUME_NONNULL_END
