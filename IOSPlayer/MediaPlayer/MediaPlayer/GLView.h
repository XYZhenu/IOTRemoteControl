#import <UIKit/UIKit.h>
#import "MediaPlayer.h"

@interface GLView : UIView

- (void)drawFrame:(YuvFrame *)frame;
- (void)setSrcTitle:(NSString *)name;
- (void)setAspectFit:(BOOL)af;
-(YuvFrame *) pixelBuffer;
@end
