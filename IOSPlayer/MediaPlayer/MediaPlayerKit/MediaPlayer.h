#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface YuvFrame : NSObject
-(id) initWithRef:(CVImageBufferRef)ref pts:(uint32_t)pts dts:(uint32_t)dts;
@property (nonatomic) CVImageBufferRef frame;
@property (nonatomic) uint32_t         pts;
@property (nonatomic) uint32_t         dts;
@end

@class MediaPlayerOC;
@protocol MediaPlayerDelegate <NSObject>
-(void) mediaPlayer:(MediaPlayerOC *)player onDrawFrame:(YuvFrame *)frame;
-(void) mediaPlayer:(MediaPlayerOC *)player onShutdown:(NSError *)err;
-(void) mediaPlayer:(MediaPlayerOC *)player onProgress:(float)progress;
-(void) mediaPlayer:(MediaPlayerOC *)player onPlayResult:(NSError *)err;
-(void) mediaPlayerOnAutoPaused:(MediaPlayerOC *)player;
@end

@interface MediaPlayerOC : NSObject
@property(nonatomic,weak) id<MediaPlayerDelegate> delegate;
@property(nonatomic,readonly) int videoHeight;
@property(nonatomic,readonly) int videoWidth;
@property(nonatomic,readonly) float videoFps;
@property(nonatomic,readonly) int audioSampleRate;
@property(nonatomic,readonly) int audioSampleBit;
@property(nonatomic,readonly) int audioChannel;
@property(nonatomic,readonly) bool containAudio;
@property(nonatomic,readonly) bool containVideo;
@property(nonatomic,readonly) bool isInited;
@property(nonatomic,readonly) float duration;
@property(nonatomic) float progress;
@property(nonatomic) bool enableAudio;
@property(nonatomic) bool pause;
@property(nonatomic,readonly) bool playing;
@property(nonatomic,retain) YuvFrame *frame;
@property(nonatomic) bool pauseAuto;
@property(nonatomic,readonly,retain) NSString *url;

-(void) play:(NSString *)url;

-(void) teardown;

-(void) rePlay;

-(void) setOption:(NSString *) key intValue:(int)val;
-(void) setOption:(NSString *) key stringValue:(NSString *)val;

@end



@interface MediaPlayerHelper : NSObject<MediaPlayerDelegate>

+(instancetype) Instance;
-( MediaPlayerOC * _Nullable )getPlayer:(NSString *_Nonnull) url;
-(void) addDelegate:(id<MediaPlayerDelegate> _Nonnull) delegate withUrl:(NSString *_Nonnull)url;
-(void) removeDelegate:(id<MediaPlayerDelegate> _Nonnull) delegate withUrl:(NSString *_Nonnull)url;

@end








