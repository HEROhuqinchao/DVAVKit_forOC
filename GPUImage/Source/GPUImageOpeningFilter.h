#if __has_include(<GPUImage/GPUImageFramework.h>)
#import <GPUImage/GPUImageFilterGroup.h>

#else
#import "GPUImageFilterGroup.h"

#endif

@class GPUImageErosionFilter;
@class GPUImageDilationFilter;

// A filter that first performs an erosion on the red channel of an image, followed by a dilation of the same radius. 
// This helps to filter out smaller bright elements.

@interface GPUImageOpeningFilter : GPUImageFilterGroup
{
    GPUImageErosionFilter *erosionFilter;
    GPUImageDilationFilter *dilationFilter;
}

@property(readwrite, nonatomic) CGFloat verticalTexelSpacing, horizontalTexelSpacing;

- (id)initWithRadius:(NSUInteger)radius;

@end
