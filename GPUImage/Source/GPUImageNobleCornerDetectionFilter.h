#if __has_include(<GPUImage/GPUImageFramework.h>)
#import <GPUImage/GPUImageHarrisCornerDetectionFilter.h>

#else
#import "GPUImageHarrisCornerDetectionFilter.h"

#endif

/** Noble corner detector
 
 This is the Noble variant on the Harris detector, from 
 Alison Noble, "Descriptions of Image Surfaces", PhD thesis, Department of Engineering Science, Oxford University 1989, p45.  
*/


@interface GPUImageNobleCornerDetectionFilter : GPUImageHarrisCornerDetectionFilter

@end
