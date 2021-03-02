#import "MediaDecoder.h"
#import <VideoToolbox/VideoToolbox.h>
#import <objc/runtime.h>
#import "Util/TimeTicker.h"
#if TARGET_OS_IPHONE
#define WEBRTC_IOS
#elif TARGET_OS_MAC
#define WEBRTC_MAC
#endif

using namespace toolkit;

@interface MediaDecoder ()
{
    VTDecompressionSessionRef _deocderSession;
    CMVideoFormatDescriptionRef _decoderFormatDescription;
}
@end


static void didDecompress( void *decompressionOutputRefCon, void *sourceFrameRefCon, OSStatus status, VTDecodeInfoFlags infoFlags, CVImageBufferRef pixelBuffer, CMTime presentationTimeStamp, CMTime presentationDuration ){
    if(pixelBuffer && !(infoFlags & kVTDecodeInfo_FrameDropped)){
        MediaDecoder *h264Decoder = (__bridge MediaDecoder *)decompressionOutputRefCon;
        if(!h264Decoder.delegate){
            return;
        }
        __strong id<MediaDecoderDelegate> strongDelegate = h264Decoder.delegate;
        [strongDelegate onDecoded:pixelBuffer userData:sourceFrameRefCon];
    }
}


@implementation MediaDecoder

-(bool)decodeOneVideoFrame:(const uint8_t *) data len:(int )dataLen userData:(void *) userData{
    uint32_t nalSize = ntohl((uint32_t)(dataLen - 4));
    memcpy((uint8_t *)data, &nalSize, 4);
    int nalType = data[4] & 0x1F;
    switch (nalType) {
        case 0x07:
        case 0x08:
            return false;
        default:
            return [self decode:data withLen:dataLen userData:userData];
            break;
    }
}
inline CFDictionaryRef CreateCFDictionary(CFTypeRef* keys,
                                          CFTypeRef* values,
                                          size_t size)
{
    return CFDictionaryCreate(nullptr, keys, values, size,
                              &kCFTypeDictionaryKeyCallBacks,
                              &kCFTypeDictionaryValueCallBacks);
}
-(BOOL)ResetDecompressionSession{
    TimeTicker1(0);
    static size_t const attributes_size = 3;
    CFTypeRef keys[attributes_size] =
    {
#if   defined(WEBRTC_IOS)
        kCVPixelBufferOpenGLESCompatibilityKey,
#elif defined(WEBRTC_MAC)
        kCVPixelBufferOpenGLCompatibilityKey,
#endif
        kCVPixelBufferIOSurfacePropertiesKey,
        kCVPixelBufferPixelFormatTypeKey
    };
    
    CFDictionaryRef io_surface_value = CreateCFDictionary(nullptr, nullptr, 0);
    int64_t nv12type = kCVPixelFormatType_420YpCbCr8BiPlanarFullRange;
    CFNumberRef pixel_format = CFNumberCreate(nullptr, kCFNumberLongType, &nv12type);
    CFTypeRef values[attributes_size] = {kCFBooleanTrue, io_surface_value, pixel_format};
    CFDictionaryRef attributes = CreateCFDictionary(keys, values, attributes_size);
    
    if (io_surface_value)
    {
        CFRelease(io_surface_value);
        io_surface_value = nullptr;
    }
    
    if (pixel_format)
    {
        CFRelease(pixel_format);
        pixel_format = nullptr;
    }
    
    VTDecompressionOutputCallbackRecord record = { didDecompress, (__bridge void *)self};
    OSStatus status = VTDecompressionSessionCreate(nullptr,
                                                   _decoderFormatDescription,
                                                   nullptr,
                                                   attributes,
                                                   &record,
                                                   &_deocderSession);
    CFRelease(attributes);
    if (status != noErr)
    {
        [self DestroyDecompressionSession];
        return false;
    }
#if defined(WEBRTC_IOS)
    VTSessionSetProperty(_deocderSession,
                         kVTDecompressionPropertyKey_RealTime,
                         kCFBooleanTrue);
#endif
    return true;
}
-(id)initH264DecoderWithSPS:(NSData *)sps PPS:(NSData*)pps {
    self=[super init];
    if (self) {
        const uint8_t* const parameterSetPointers[2] = { (uint8_t*)sps.bytes, (uint8_t *)pps.bytes };
        const size_t parameterSetSizes[2] = { [sps length], [pps length] };
        OSStatus status = CMVideoFormatDescriptionCreateFromH264ParameterSets(kCFAllocatorDefault,
                                                                              2, //param count
                                                                              parameterSetPointers,
                                                                              parameterSetSizes,
                                                                              4, //nal start code size
                                                                              &_decoderFormatDescription);
        if(status != noErr) {
            NSLog(@"CMVideoFormatDescriptionCreateFromH264ParameterSets failed status=%d", (int)status);
            return nil;
        }
        if(![self ResetDecompressionSession]){
            return nil;
        }
    }
    return self;
}

static CMSampleBufferRef CreateSampleBufferFrom(CMFormatDescriptionRef fmt_desc, void *demux_buff, size_t demux_size)
{
    OSStatus status;
    CMBlockBufferRef newBBufOut = NULL;
    CMSampleBufferRef sBufOut = NULL;
    
    status = CMBlockBufferCreateWithMemoryBlock(
                                                NULL,
                                                demux_buff,
                                                demux_size,
                                                kCFAllocatorNull,
                                                NULL,
                                                0,
                                                demux_size,
                                                FALSE,
                                                &newBBufOut);
    
    if (!status) {
        status = CMSampleBufferCreate(
                                      NULL,
                                      newBBufOut,
                                      TRUE,
                                      0,
                                      0,
                                      fmt_desc,
                                      1,
                                      0,
                                      NULL,
                                      0,
                                      NULL,
                                      &sBufOut);
    }
    
    CFRelease(newBBufOut);
    if (status == 0) {
        return sBufOut;
    } else {
        return NULL;
    }
}



-(bool)decode:(const uint8_t *)nal withLen:(size_t)len userData:(void *) userData{
    CMSampleBufferRef sample_buffer = CreateSampleBufferFrom(_decoderFormatDescription,(void *)nal,len);
    VTDecodeInfoFlags flags_out;
    VTDecodeFrameFlags decode_flags = kVTDecodeFrame_EnableAsynchronousDecompression | kVTDecodeFrame_1xRealTimePlayback ;
    OSStatus status = VTDecompressionSessionDecodeFrame( _deocderSession,
                                                        sample_buffer,
                                                        decode_flags,
                                                        userData,
                                                        &flags_out);
    if(status == kVTInvalidSessionErr) {
        if([self ResetDecompressionSession] == 0) {
            status = VTDecompressionSessionDecodeFrame( _deocderSession,
                                                       sample_buffer,
                                                       decode_flags,
                                                       userData,
                                                       &flags_out);
        }
    }
    CFRelease(sample_buffer);
    if (status != noErr) {
        NSLog(@"VTDecompressionSessionDecodeFrame err:%d",status);
        return false;
    }
    return true;
}

-(void)DestroyDecompressionSession{
    if(_deocderSession) {
        VTDecompressionSessionInvalidate(_deocderSession);
        CFRelease(_deocderSession);
        _deocderSession = NULL;
    }
}
- (void) dealloc
{
    if(_decoderFormatDescription) {
        CFRelease(_decoderFormatDescription);
        _decoderFormatDescription = NULL;
    }
    [self DestroyDecompressionSession];
}

@end

