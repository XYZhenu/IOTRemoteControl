#import <Foundation/Foundation.h>


@interface WeakArray : NSObject
-(void)addObject:(NSObject *)obj;
-(void)removeObject:(NSObject *)obj;

@property(nonatomic,readonly,retain) NSMutableArray *strongRef;
@end
