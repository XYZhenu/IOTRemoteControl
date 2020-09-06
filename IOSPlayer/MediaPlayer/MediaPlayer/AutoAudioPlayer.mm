#import "AutoAudioPlayer.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreAudio/CoreAudioTypes.h>
#import <AudioToolbox/AudioToolbox.h>
#import <objc/runtime.h>
#define QUEUE_BUFFER_SIZE 5

#pragma mark -
#pragma mark recorder call back
static void MyInputBufferHandler(void *                  inUserData,
                                 AudioQueueRef           inAQ,
                                 AudioQueueBufferRef     inBuffer)
{
    //拿到一帧的数据
    unsigned int buf_length = inBuffer->mAudioDataBytesCapacity;
    void * buf = inBuffer->mAudioData;
    AutoAudioPlayer * autoAudioPlayer = (__bridge AutoAudioPlayer *) inUserData;
    if (![autoAudioPlayer.delegate ReadPCM:(char *)buf Size:buf_length]) {
        memset(buf, 0, buf_length);
    }
   //NSLog(@"AutoAudioPlayer.delegate:%d",(NSUInteger)[autoAudioPlayer.delegate performSelector:NSSelectorFromString(@"retainCount")]);
    AudioQueueEnqueueBuffer(inAQ, inBuffer, 0, nil);
}

@implementation AutoAudioPlayer
{
    AudioQueueRef audioQueue;
    AudioQueueBufferRef  audioQueueBuffers[QUEUE_BUFFER_SIZE];
    AudioStreamBasicDescription format;
    BOOL paused;
}

-(id)init
{
    self=[super init];
    if (self) {
        paused=false;
        audioQueue=NULL;
    }
    return self;
}
- (int)create:(long)sample bitsPerSample:(long)bitsPerSample channels:(long)channels
{
    format.mSampleRate = (Float64)sample;
    format.mFormatID   = kAudioFormatLinearPCM;
    if (bitsPerSample == 8)
        format.mFormatFlags  = kAudioFormatFlagIsPacked;
    else
        format.mFormatFlags  = kLinearPCMFormatFlagIsSignedInteger|kAudioFormatFlagIsPacked;
    format.mFramesPerPacket  = 1;
    format.mChannelsPerFrame = channels;
    format.mBytesPerFrame    = format.mChannelsPerFrame * (bitsPerSample/8);
    format.mBytesPerPacket   = format.mBytesPerFrame;
    format.mBitsPerChannel   = bitsPerSample;
    format.mReserved = 0;
    
    int error = 0;
    error = AudioQueueNewOutput(&format, MyInputBufferHandler, (__bridge void *)(self), NULL,kCFRunLoopCommonModes, 0, &audioQueue);
    if (error)
    {
        return error;
    }
    
    int bufferSize_ = [_delegate getPCMBufferSize];
    for (int i = 0; i < QUEUE_BUFFER_SIZE; i++)
    {
        
        error = AudioQueueAllocateBuffer(audioQueue, bufferSize_, &audioQueueBuffers[i]);
        if (error)
        {
            return error;
        }
        else
        {
            audioQueueBuffers[i]->mAudioDataByteSize = audioQueueBuffers[i]->mAudioDataBytesCapacity;
            memset(audioQueueBuffers[i]->mAudioData, 0, audioQueueBuffers[i]->mAudioDataByteSize );
            AudioQueueEnqueueBuffer(audioQueue, audioQueueBuffers[i], 0, nil);
        }
    }
    OSStatus ret=AudioQueueSetParameter(audioQueue, kAudioQueueParam_Volume, 1.0);
    ret= AudioQueueStart(audioQueue, nil);
    return ret;
}
-(BOOL)isPlaying
{
    return !paused;
}
-(void)StopPlay
{
    if (audioQueue!=NULL) {
        AudioQueueStop(audioQueue, YES);
        AudioQueueDispose(audioQueue, YES);
        audioQueue=NULL;
        paused=true;
    }
}
-(BOOL)StartPlay
{
    if (audioQueue!=NULL) {
        [self StopPlay];
    }
    if ([self create:[_delegate getPCMSampleRate]
       bitsPerSample:[_delegate getPCMSampleBit]
            channels:[_delegate getPCMChannel]]!=0) {
        return false;
    }
    paused=false;
    return true;
}

-(void)Pause:(bool)_pause{
    if (paused==_pause) {
        return;
    }
    paused=_pause;
    if (paused) {
        AudioQueuePause(audioQueue);
    }else{
        AudioQueueStart(audioQueue, nil);
    }
}
-(void)dealloc
{
    [self StopPlay];
}

@end
