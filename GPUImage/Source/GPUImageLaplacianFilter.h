#if __has_include(<GPUImage/GPUImageFramework.h>)
#import <GPUImage/GPUImage3x3ConvolutionFilter.h>
#else
#import "GPUImage3x3ConvolutionFilter.h"
#endif

@interface GPUImageLaplacianFilter : GPUImage3x3ConvolutionFilter

@end
