#if __has_include(<GPUImage/GPUImageFramework.h>)
#import <GPUImage/GPUImageTwoInputFilter.h>

#else
#import "GPUImageTwoInputFilter.h"

#endif

/** Applies a color burn blend of two images
 */
@interface GPUImageColorBurnBlendFilter : GPUImageTwoInputFilter
{
}

@end
