#if __has_include(<GPUImage/GPUImageFramework.h>)
#import <GPUImage/GPUImageTwoInputFilter.h>

#else
#import "GPUImageTwoInputFilter.h"

#endif

/// Blends two images by taking the maximum value of each color component between the images
@interface GPUImageLightenBlendFilter : GPUImageTwoInputFilter
{
}

@end
