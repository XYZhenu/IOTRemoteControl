//
//  H264HwDecoder.h
//  MediaPlayer
//
//  Created by XYZHENU on 2020/7/25.
//  Copyright © 2020 jizan. All rights reserved.
//
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <Foundation/Foundation.h>
#import <VideoToolbox/VideoToolbox.h>
#import <AVFoundation/AVSampleBufferDisplayLayer.h>

NS_ASSUME_NONNULL_BEGIN

typedef enum : NSUInteger {
    H264HWDataType_Image = 0,
    H264HWDataType_Pixel,
    H264HWDataType_Layer,
} H264HWDataType;

@interface H264HwDecoder : NSObject
 
@property (nonatomic,assign) H264HWDataType showType;    //显示类型
@property (nonatomic,strong) UIImage *image;            //解码成RGB数据时的IMG
@property (nonatomic,assign) CVPixelBufferRef pixelBuffer;    //解码成YUV数据时的解码BUF
@property (nonatomic,strong) AVSampleBufferDisplayLayer *displayLayer;  //显示图层
 
@property (nonatomic,assign) BOOL isNeedPerfectImg;    //是否读取完整UIImage图形(showType为0时才有效)
 
- (instancetype)init;
 
/**
 H264视频流解码
 @param videoData 视频帧数据
 @param videoSize 视频帧大小
 @return 视图的宽高(width, height)，当为接收为AVSampleBufferDisplayLayer时返回接口是无效的
 */
- (CGSize)decodeH264VideoData:(uint8_t *)videoData videoSize:(NSInteger)videoSize dts:(uint32_t)dts pts:(uint32_t)pts;
 
/**
 释放解码器
 */
- (void)releaseH264HwDecoder;
 
/**
 视频截图
 @return IMG
 */
- (UIImage *)snapshot;
 
@end

NS_ASSUME_NONNULL_END
