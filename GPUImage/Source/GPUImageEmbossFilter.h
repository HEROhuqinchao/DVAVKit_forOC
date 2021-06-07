#if __has_include(<GPUImage/GPUImageFramework.h>)
#import <GPUImage/GPUImage3x3ConvolutionFilter.h>
#else
#import "GPUImage3x3ConvolutionFilter.h"
#endif

@interface GPUImageEmbossFilter : GPUImage3x3ConvolutionFilter

// The strength of the embossing, from  0.0 to 4.0, with 1.0 as the normal level
@property(readwrite, nonatomic) CGFloat intensity; 

@end
