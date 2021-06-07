
#if __has_include(<GPUImage/GPUImageFramework.h>)
#import <GPUImage/GPUImageFilter.h>
#else
#import "GPUImageFilter.h"
#endif

@interface GPUImagePixellateFilter : GPUImageFilter
{
    GLint fractionalWidthOfAPixelUniform, aspectRatioUniform;
}

// The fractional width of the image to use as a size for the pixels in the resulting image. Values below one pixel width in the source image are ignored.
@property(readwrite, nonatomic) CGFloat fractionalWidthOfAPixel;


@end
