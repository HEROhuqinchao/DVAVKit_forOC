//
//  GPUImagePixelBufferOutput.m
//
//  Function: 奥点云直播推流用 RTMP SDK
//
//  Copyright © 2021 杭州奥点科技股份有限公司. All rights reserved.
//
//  Version: 1.1.0  Creation(版本信息)

#import "GPUImagePixelBufferOutput.h"

@implementation GPUImagePixelBufferOutput


- (instancetype)initwithImageSize:(CGSize)newImageSize{
 
  if (self == [super initWithImageSize:newImageSize resultsInBGRAFormat:YES]) {
    
  }
  return self;
}

#pragma mark - GPUImageInput protocol
- (void)newFrameReadyAtTime:(CMTime)frameTime atIndex:(NSInteger)textureIndex;
{
   [super newFrameReadyAtTime:frameTime atIndex:textureIndex];

    [self lockFramebufferForReading];

    CVPixelBufferRef pixelBuffer = NULL;
    CVPixelBufferCreateWithBytes(NULL,
                                 imageSize.width,
                                 imageSize.height,
                                 kCVPixelFormatType_32BGRA,
                                 self.rawBytesForImage,
                                 self.bytesPerRowInOutput,
                                 NULL,
                                 NULL,
                                 NULL,
                                 &pixelBuffer);
    
    if(self.pixelBufferCallback){
        self.pixelBufferCallback(pixelBuffer);
    }
    CVPixelBufferRelease(pixelBuffer);
    [self unlockFramebufferAfterReading];
}

- (void)willOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer {}

- (void)processAudioBuffer:(CMSampleBufferRef)audioBuffer {}

- (BOOL)hasAudioTrack {return YES;}

@end
