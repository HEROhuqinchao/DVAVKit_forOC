#if __has_include(<GPUImage/GPUImageFramework.h>)
#import <GPUImage/GPUImageTwoInputFilter.h>

#else
#import "GPUImageTwoInputFilter.h"

#endif

@interface GPUImageVoronoiConsumerFilter : GPUImageTwoInputFilter 
{
    GLint sizeUniform;
}

@property (nonatomic, readwrite) CGSize sizeInPixels;

@end
