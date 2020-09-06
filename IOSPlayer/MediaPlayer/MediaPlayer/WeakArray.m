#import "WeakArray.h"

@implementation WeakArray
{
    NSMutableArray *_delegate_array;
}
-(id)init
{
    self=[super init];
    if (self) {
        _delegate_array=[NSMutableArray array];
    }
    return self;
}
-(void)addObject:(NSObject *)obj{
    for (NSValue *val in _delegate_array) {
        if (val.nonretainedObjectValue == obj) {
            return;
        }
    }
    [_delegate_array addObject:[NSValue valueWithNonretainedObject:obj]];
}
-(void)removeObject:(NSObject *)obj{
    for (NSValue *val in _delegate_array) {
        if (val.nonretainedObjectValue == obj) {
            [_delegate_array removeObject:val];
            return;
        }
    }
}
-(NSMutableArray *)strongRef{
    NSMutableArray *strongDelegate=[NSMutableArray array];
    for (NSValue *val in _delegate_array) {
        if(val.nonretainedObjectValue){
            __strong NSObject *obj = val.nonretainedObjectValue;
            [strongDelegate addObject:obj];
        }
    }
    return strongDelegate;
}

@end
