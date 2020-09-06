//
//  JoyStick.m
//  KitTest
//
//  Created by XYZHENU on 2020/9/6.
//  Copyright © 2020 jizan. All rights reserved.
//

#import "JoyStick.h"

@interface JoyStick()

@property (nonatomic, strong) UIImageView *stickBgView;
@property (nonatomic, strong) UIImageView *stickView;
@property (nonatomic, strong) void(^callback)(CGFloat,CGFloat);
@end

@implementation JoyStick

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.userInteractionEnabled = YES;
        [self initView:frame];
    }
    return self;
}

- (void)initView:(CGRect)frame
{
    self.stickBgView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
    [self addSubview:self.stickBgView];
    [self.stickBgView.layer setMasksToBounds:YES];
    [self.stickBgView.layer setCornerRadius:frame.size.width/2];
    
    self.stickView = [[UIImageView alloc] initWithFrame:CGRectMake(frame.size.width/4, frame.size.height/4, frame.size.width/2, frame.size.height/2)];
    [self addSubview:self.stickView];
    
    self.stickView.backgroundColor = [UIColor redColor];
    self.stickBgView.backgroundColor = [UIColor greenColor];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.stickBgView.frame = self.bounds;
}

- (void)setCallBack:(void(^)(CGFloat,CGFloat))callback {
    self.callback = callback;
}


- (CGPoint)callinelength:(CGPoint)point {
    CGFloat centrex = self.frame.size.width/2;          //圆心X
    CGFloat centrey = self.frame.size.height/2;         //圆心Y
    CGFloat radius = self.frame.size.width/2;           //半径
    CGFloat x;              //坐标系X
    CGFloat y;              //坐标系Y
    
    x = point.x - centrex;
    y = centrey - point.y;
    
    float current_radius =  sqrtf(x*x + y*y);           //计算改点到圆心的距离
    if(current_radius > radius)
    {
        float circlex = fabs(x) / current_radius * radius;
        float circley = fabs(y) / current_radius * radius;
        if(x < 0 && y > 0)
        {
            x = centrex - circlex;
            y = centrey - circley;
        }
        else if(x > 0 && y > 0)
        {
            x = centrex + circlex;
            y = centrey - circley;
        }
        else if(x < 0 && y < 0)
        {
            x = centrex - circlex;
            y = centrey + circley;
        }
        else if (x > 0 && y < 0)
        {
            x = centrex + circlex;
            y = centrey + circley;
        }
        return CGPointMake(x, y);
    }
    else
    {
        return CGPointMake(point.x, point.y);
    }
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint pointBegan = [touch locationInView:self];
    [self updatePosition:[self callinelength:pointBegan]];
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint pointBegan = [touch locationInView:self];
    [self updatePosition:[self callinelength:pointBegan]];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self updatePosition:CGPointMake(self.frame.size.width/2, self.frame.size.height/2)];
}

- (void)updatePosition:(CGPoint)position {
    self.stickView.center = position;
    if (self.callback) {
        CGFloat radius = self.frame.size.width/2;
        CGFloat xRate = (position.x - radius)/radius;
        CGFloat yRate = (position.y - radius)/radius;
        self.callback(xRate, yRate);
    }
}

@end
