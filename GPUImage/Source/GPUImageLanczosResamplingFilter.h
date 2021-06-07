#if __has_include(<GPUImage/GPUImageFramework.h>)
#import <GPUImage/GPUImageTwoPassTextureSamplingFilter.h>

#else
#import "GPUImageTwoPassTextureSamplingFilter.h"

#endif

@interface GPUImageLanczosResamplingFilter : GPUImageTwoPassTextureSamplingFilter

@property(readwrite, nonatomic) CGSize originalImageSize;

@end
