//
//  GPUImageHistogramEqualizationFilter.h
//  FilterShowcase
//
//  Created by Adam Marcus on 19/08/2014.
//  Copyright (c) 2014 Sunset Lake Software LLC. All rights reserved.
//

#if __has_include(<GPUImage/GPUImageFramework.h>)
#import <GPUImage/GPUImageFilterGroup.h>

#else
#import "GPUImageFilterGroup.h"

#endif
#import "GPUImageHistogramFilter.h"
#import "GPUImageRawDataOutput.h"
#import "GPUImageRawDataInput.h"
#if __has_include(<GPUImage/GPUImageFramework.h>)
#import <GPUImage/GPUImageTwoInputFilter.h>

#else
#import "GPUImageTwoInputFilter.h"

#endif

@interface GPUImageHistogramEqualizationFilter : GPUImageFilterGroup
{
    GPUImageHistogramFilter *histogramFilter;
    GPUImageRawDataOutput *rawDataOutputFilter;
    GPUImageRawDataInput *rawDataInputFilter;
}

@property(readwrite, nonatomic) NSUInteger downsamplingFactor;

- (id)initWithHistogramType:(GPUImageHistogramType)newHistogramType;

@end
