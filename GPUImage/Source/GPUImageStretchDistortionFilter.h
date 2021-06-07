
#if __has_include(<GPUImage/GPUImageFramework.h>)
#import <GPUImage/GPUImageFilter.h>
#else
#import "GPUImageFilter.h"
#endif

/** Creates a stretch distortion of the image
 */
@interface GPUImageStretchDistortionFilter : GPUImageFilter {
    GLint centerUniform;
}

/** The center about which to apply the distortion, with a default of (0.5, 0.5)
 */
@property(readwrite, nonatomic) CGPoint center;

@end
