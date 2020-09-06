#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <UIKit/UIKit.h>

@protocol MediaDecoderDelegate <NSObject>
- (void)onDecoded:(CVImageBufferRef )imageBuffer userData:(void *)userData;
@end

@interface MediaDecoder : NSObject
@property (nonatomic,assign) id<MediaDecoderDelegate> delegate;
-(id)initH264DecoderWithSPS:(NSData *)sps PPS:(NSData*)pps;
-(bool)decodeOneVideoFrame:(const uint8_t *) data len:(int )dataLen userData:(void *) userData;

@end
