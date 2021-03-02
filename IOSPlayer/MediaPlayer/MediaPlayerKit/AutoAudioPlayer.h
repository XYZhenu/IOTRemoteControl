#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@protocol AutoAudioPlayerDelegate <NSObject>
-(int)getPCMBufferSize;
-(int)getPCMSampleBit;
-(int)getPCMSampleRate;
-(int)getPCMChannel;
-(int)ReadPCM:(char *)buf Size:(int)bufsize;
@end


@interface AutoAudioPlayer : NSObject
@property(nonatomic,assign) id<AutoAudioPlayerDelegate> delegate;
-(void)StopPlay;
-(BOOL)StartPlay;
-(void)Pause:(bool)pause;
@property(readonly, getter=isPlaying) BOOL playing; /* is it playing or not? */
@end
