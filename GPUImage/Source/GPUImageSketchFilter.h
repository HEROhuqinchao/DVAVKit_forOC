#if __has_include(<GPUImage/GPUImageFramework.h>)
#import <GPUImage/GPUImageSobelEdgeDetectionFilter.h>

#else
#import "GPUImageSobelEdgeDetectionFilter.h"

#endif

/** Converts video to look like a sketch.
 
 This is just the Sobel edge detection filter with the colors inverted.
 */
@interface GPUImageSketchFilter : GPUImageSobelEdgeDetectionFilter
{
}

@end
