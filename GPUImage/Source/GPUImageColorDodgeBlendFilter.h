#if __has_include(<GPUImage/GPUImageFramework.h>)
#import <GPUImage/GPUImageTwoInputFilter.h>

#else
#import "GPUImageTwoInputFilter.h"

#endif

/** Applies a color dodge blend of two images
 */
@interface GPUImageColorDodgeBlendFilter : GPUImageTwoInputFilter
{
}

@end
