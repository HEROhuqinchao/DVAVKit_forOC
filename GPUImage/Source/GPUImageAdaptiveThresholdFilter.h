#if __has_include(<GPUImage/GPUImageFramework.h>)
#import <GPUImage/GPUImageFilterGroup.h>

#else
#import "GPUImageFilterGroup.h"

#endif

@interface GPUImageAdaptiveThresholdFilter : GPUImageFilterGroup

/** A multiplier for the background averaging blur radius in pixels, with a default of 4
 */
@property(readwrite, nonatomic) CGFloat blurRadiusInPixels;

@end
