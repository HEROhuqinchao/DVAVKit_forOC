//
//  GPUImagePixelBufferOutput.h
//
//  Function: 奥点云直播推流用 RTMP SDK
//
//  Copyright © 2021 杭州奥点科技股份有限公司. All rights reserved.
//
//  Version: 1.1.0  Creation(版本信息)

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#if __has_include(<GPUImage/GPUImageFramework.h>)
#import <GPUImage/GPUImageRawDataOutput.h>
#else
#import "GPUImageRawDataOutput.h"

#endif

typedef void (^GPUImageBufferOutputBlock) (CVPixelBufferRef _Nullable pixelBufferRef);

NS_ASSUME_NONNULL_BEGIN

@interface GPUImagePixelBufferOutput : GPUImageRawDataOutput <GPUImageInput>

@property(nonatomic, copy)GPUImageBufferOutputBlock pixelBufferCallback;

- (instancetype)initwithImageSize:(CGSize)newImageSize;
@end

NS_ASSUME_NONNULL_END
