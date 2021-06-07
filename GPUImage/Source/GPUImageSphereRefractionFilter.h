
#if __has_include(<GPUImage/GPUImageFramework.h>)
#import <GPUImage/GPUImageFilter.h>
#else
#import "GPUImageFilter.h"
#endif

@interface GPUImageSphereRefractionFilter : GPUImageFilter
{
    GLint radiusUniform, centerUniform, aspectRatioUniform, refractiveIndexUniform;
}

/// The center about which to apply the distortion, with a default of (0.5, 0.5)
@property(readwrite, nonatomic) CGPoint center;
/// The radius of the distortion, ranging from 0.0 to 1.0, with a default of 0.25
@property(readwrite, nonatomic) CGFloat radius;
/// The index of refraction for the sphere, with a default of 0.71
@property(readwrite, nonatomic) CGFloat refractiveIndex;

@end
