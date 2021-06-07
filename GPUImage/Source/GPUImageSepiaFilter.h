#if __has_include(<GPUImage/GPUImageFramework.h>)
#import <GPUImage/GPUImageColorMatrixFilter.h>

#else
#import "GPUImageColorMatrixFilter.h"

#endif

/// Simple sepia tone filter
@interface GPUImageSepiaFilter : GPUImageColorMatrixFilter

@end
