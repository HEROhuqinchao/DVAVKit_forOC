#if __has_include(<GPUImage/GPUImageFramework.h>)
#import <GPUImage/GPUImageFilterGroup.h>

#else
#import "GPUImageFilterGroup.h"

#endif

@interface GPUImageAverageLuminanceThresholdFilter : GPUImageFilterGroup

// This is multiplied by the continually calculated average image luminosity to arrive at the final threshold. Default is 1.0.
@property(readwrite, nonatomic) CGFloat thresholdMultiplier;

@end
