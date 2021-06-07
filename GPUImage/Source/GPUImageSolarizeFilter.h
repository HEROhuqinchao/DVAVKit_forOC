
#if __has_include(<GPUImage/GPUImageFramework.h>)
#import <GPUImage/GPUImageFilter.h>
#else
#import "GPUImageFilter.h"
#endif

/** Pixels with a luminance above the threshold will invert their color
 */
@interface GPUImageSolarizeFilter : GPUImageFilter
{
    GLint thresholdUniform;
}

/** Anything above this luminance will be inverted, and anything below normal. Ranges from 0.0 to 1.0, with 0.5 as the default
 */
@property(readwrite, nonatomic) CGFloat threshold;

@end
