//
//  DVBFVideoCamera.h
//  DVAVKit
//
//  Created by 胡勤超 on 2021/6/7.
//  Copyright © 2021 MyKit. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>
#import "DVVideoConfig.h"
NS_ASSUME_NONNULL_BEGIN
@class DVBFVideoCamera;
/** ADYGPUImageVideoCapture callback videoData - 视频数据处理回调*/
@protocol DVBFVideoCameraDelegate <NSObject>
- (void)DVVideoCapture:(DVBFVideoCamera *)capture
    outputSampleBuffer:(CMSampleBufferRef)sampleBuffer
                isBeauty:(BOOL)isBeauty;

@end

@interface DVBFVideoCamera : NSObject
#pragma mark - Attribute -- 相机属性
///=============================================================================
/// @name Attribute
///=============================================================================

/**
 * The delegate of the capture. captureData callback
 * 回调数据代理
 */
@property (nullable, nonatomic, weak) id<DVBFVideoCameraDelegate> delegate;

/**
 * The running control start capture or stop capture
 * 正在运行的控件启动捕获或停止捕获
 */
@property (nonatomic, assign) BOOL running;

/**
 * The preView will show OpenGL ES view
 * 预览将显示OpenGL ES视图
 */
@property (null_resettable, nonatomic, strong) UIView *preView;


/**
 * The captureDevicePosition control camraPosition ,default front
 * 摄像头翻转 - 默认为前置
 */
//@property (nonatomic, assign) AVCaptureDevicePosition captureDevicePosition;

/**
 * The beautyFace control capture shader filter empty or beautiy
 * 是否开启 美颜滤镜
 */
@property (nonatomic, assign) BOOL beautyFace;

/**
 * The torch control capture flash is on or off
 * 闪光灯打开或关闭
 */
@property (nonatomic, assign) BOOL torch;

/**
 * The mirror control mirror of front camera is on or off
 * 前摄像头的镜像打开或关闭
 */
@property (nonatomic, assign) BOOL mirror;

/**
 * The beautyLevel control beautyFace Level, default 0.5, between 0.0 ~ 1.0
 * 控制美颜滤镜程度，默认为0.5，介于0.0~1.0之间
 */
@property (nonatomic, assign) CGFloat beautyLevel;

/**
 * The brightLevel control brightness Level, default 0.5, between 0.0 ~ 1.0
 * 控制亮度级别，默认为0.5，介于0.0~1.0之间
 */
@property (nonatomic, assign) CGFloat brightLevel;

/**
 * The torch control camera zoom scale default 1.0, between 1.0 ~ 3.0
 * 控制摄像头缩放比例默认为1.0，介于1.0~3.0之间
 */
@property (nonatomic, assign) CGFloat zoomScale;

/**
 * The videoFrameRate control videoCapture output data count
 * videoFrameRate控制videoCapture 视频帧率
 */
@property (nonatomic, assign) NSInteger videoFrameRate;

/***
 * The warterMarkView control whether the watermark is displayed or not ,if set ni,will remove watermark,otherwise add
 * warterMarkView 控制是否显示水印，如果设置为ni，则删除水印，否则添加水印
 *.*/
@property (nonatomic, strong, nullable) UIView *warterMarkView;

/**
 * The currentImage is videoCapture shot
 * 当前图像为视频捕获快照
 */
@property (nonatomic, strong, nullable) UIImage *currentImage;

/**
 * The saveLocalVideo is save the local video
 * 是否保存本地视频
 */
@property (nonatomic, assign) BOOL saveLocalVideo;

/**
 * The saveLocalVideoPath is save the local video  path
 * saveLocalVideoPath 是保存本地视频路径
 */
@property (nonatomic, strong, nullable) NSURL *saveLocalVideoPath;

/**
 * 录制
 * 开始录制：
 * @param localFileURL 录制路径
 */
- (void)startRecordingToLocalFileURL:(NSURL *_Nullable)localFileURL;

/**
 * 停止录制
 */
- (void)stopRecording;

/**
 * 停止录制回调
 */
- (void)stopRecordingWithCompletionHandler:(void(^_Nullable)(void))completionHandler;


#pragma mark - Initializer -- 初始化
///=============================================================================
/// @name Initializer -
///=============================================================================
- (nullable instancetype)init UNAVAILABLE_ATTRIBUTE;
+ (nullable instancetype)new UNAVAILABLE_ATTRIBUTE;

/**
 *   The designated initializer. Multiple instances with the same configuration will make the
   capture unstable.
 *   指定的初始值设定项。具有相同配置的多个实例将使
 捕获不稳定。
 
 */
- (nullable instancetype)initWithVideoConfiguration:(nullable DVVideoConfig *)configuration NS_DESIGNATED_INITIALIZER;

@end


NS_ASSUME_NONNULL_END
