#if __has_include(<GPUImage/GPUImageFramework.h>)
#import <GPUImage/GPUImageGaussianBlurFilter.h>

#else
#import "GPUImageGaussianBlurFilter.h"

#endif

@interface GPUImageBilateralFilter : GPUImageGaussianBlurFilter
{
    CGFloat firstDistanceNormalizationFactorUniform;
    CGFloat secondDistanceNormalizationFactorUniform;
}
// A normalization factor for the distance between central color and sample color.
@property(nonatomic, readwrite) CGFloat distanceNormalizationFactor;
@end
