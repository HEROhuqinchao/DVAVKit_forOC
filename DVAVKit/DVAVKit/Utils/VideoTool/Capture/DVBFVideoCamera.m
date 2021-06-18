//
//  DVBFVideoCamera.m
//  DVAVKit
//
//  Created by 胡勤超 on 2021/6/7.
//  Copyright © 2021 MyKit. All rights reserved.
//

#import "DVBFVideoCamera.h"
#import <Accelerate/Accelerate.h>
#import "ADYGPUImageBeautyFilter.h"
#import "ADYGPUImageEmptyFilter.h"
#import "ADYAdjustFocusView.h"
#import "GPUImagePixelBufferOutput.h"
#if __has_include(<GPUImage/GPUImageFramework.h>)
#import <GPUImage/GPUImageFramework.h>
#else
#import "GPUImage.h"

#endif

@interface DVBFVideoCamera () <GPUImageVideoCameraDelegate,UIGestureRecognizerDelegate>

@property (nonatomic, strong) GPUImageVideoCamera *videoCamera;
@property (nonatomic, strong) ADYGPUImageBeautyFilter *beautyFilter;
@property (nonatomic, strong) GPUImageOutput<GPUImageInput> *filter;
@property (nonatomic, strong) GPUImageCropFilter *cropfilter;//画布裁剪
@property (nonatomic, strong) GPUImageOutput<GPUImageInput> *output;
@property (nonatomic, strong) GPUImageView *gpuImageView;
@property (nonatomic, strong) ADYAdjustFocusView *focusView;
@property (nonatomic, strong) GPUImageAlphaBlendFilter *blendFilter;
@property (nonatomic, strong) GPUImageUIElement *uiElementInput;
@property (nonatomic, strong) UIView *waterMarkContentView;
@property (nonatomic, assign) CGFloat  currentPinchZoomFactor;
@property (nonatomic, strong) GPUImageMovieWriter *movieWriter;
@property (nonatomic, strong) DVVideoConfig *configuration;
@property (nonatomic, strong) GPUImagePixelBufferOutput *gpuOutput;
@end
@implementation DVBFVideoCamera
@synthesize torch = _torch;
@synthesize beautyLevel = _beautyLevel;
@synthesize brightLevel = _brightLevel;
@synthesize zoomScale = _zoomScale;

#pragma mark -- LifeCycle
- (instancetype)initWithVideoConfiguration:(DVVideoConfig *)configuration {
    if (self = [super init]) {
        _configuration = configuration;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterBackground:) name:UIApplicationWillResignActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterForeground:) name:UIApplicationDidBecomeActiveNotification object:nil];
        //将要改变状态栏的方向-- 通知
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(statusBarChanged:) name:UIApplicationWillChangeStatusBarOrientationNotification object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setFocusPointAuto) name:AVCaptureDeviceSubjectAreaDidChangeNotification object:nil];
        
        self.beautyFace = YES;
        self.beautyLevel = 0.5;
        self.brightLevel = 0.5;
        self.zoomScale = 1.0;
        self.mirror = YES;
    }
    return self;
}

- (void)dealloc {
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_videoCamera stopCameraCapture];
    if(_gpuImageView){
        [_gpuImageView removeFromSuperview];
        _gpuImageView = nil;
    }
}

#pragma mark -- Setter Getter

-(ADYAdjustFocusView *)focusView{
    if (!_focusView) {
        _focusView = [[ADYAdjustFocusView alloc]initWithFrame:CGRectMake(0, 0, 80, 80)];
        _focusView.hidden = YES;
        [self.preView addSubview:self.focusView];
    }
    return _focusView;
}

- (GPUImageVideoCamera *)videoCamera{
    if(!_videoCamera){
        _videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:_configuration.sessionPreset cameraPosition:_configuration.position];
        _videoCamera.outputImageOrientation = _configuration.outputImageOrientation;
        _videoCamera.horizontallyMirrorFrontFacingCamera = NO;
        _videoCamera.horizontallyMirrorRearFacingCamera = NO;
        _videoCamera.delegate = self;
        _videoCamera.frameRate = (int32_t)_configuration.fps;
    }
    return _videoCamera;
}

- (void)setRunning:(BOOL)running {
    if (_running == running) return;
    _running = running;
    if (!_running) {
        [UIApplication sharedApplication].idleTimerDisabled = NO;
        [self.videoCamera stopCameraCapture];
        if(self.saveLocalVideo) [self.movieWriter finishRecording];
    } else {
        [UIApplication sharedApplication].idleTimerDisabled = YES;
        [self reloadFilter];
        [self.videoCamera startCameraCapture];
        if(self.saveLocalVideo) [self.movieWriter startRecording];
    }
}
/**
 录制
 */
- (void)startRecordingToLocalFileURL:(NSURL *)localFileURL
{
    if (self.saveLocalVideo == YES) {
        return;
    }
    self.saveLocalVideo = YES;
    self.saveLocalVideoPath = localFileURL;
    GPUImageMovieWriter *movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:localFileURL size:self.configuration.size];
    movieWriter.encodingLiveVideo = YES;
    movieWriter.shouldPassthroughAudio = YES;
    self.movieWriter = movieWriter;
    self.videoCamera.audioEncodingTarget = movieWriter;
    
    // 添加水印
    if(self.warterMarkView){
        [self.blendFilter addTarget:self.movieWriter];
    }
    else {
        [self.output addTarget:self.movieWriter];
    }
    [self.movieWriter startRecording];
}
// 停止录制
- (void)stopRecording
{
    if (self.saveLocalVideo == NO) {
        return;
    }
    self.saveLocalVideo = NO;
    [self.movieWriter finishRecording];
    // 添加水印
    if(self.warterMarkView){
        [self.blendFilter removeTarget:self.movieWriter];
    }
    else {
        [self.output removeTarget:self.movieWriter];
    }
}
//停止录制-附有回调
- (void)stopRecordingWithCompletionHandler:(void (^)(void))completionHandler
{
    if (self.saveLocalVideo == NO) {
        return;
    }
    self.saveLocalVideo = NO;
    __weak typeof(self) _self = self;
    [self.movieWriter finishRecordingWithCompletionHandler:^ {
        // 添加水印
        if(_self.warterMarkView){
            [_self.blendFilter removeTarget:_self.movieWriter];
        }
        else {
            [_self.output removeTarget:_self.movieWriter];
        }
        if (completionHandler) {
            completionHandler();
        }
    }];
}

- (void)setPreView:(UIView *)preView {
    if (self.gpuImageView.superview) [self.gpuImageView removeFromSuperview];
    [preView insertSubview:self.gpuImageView atIndex:0];
    self.gpuImageView.frame = CGRectMake(0, 0, preView.frame.size.width, preView.frame.size.height);
}

- (UIView *)preView {
    return self.gpuImageView.superview;
}

- (void)setCaptureDevicePosition:(AVCaptureDevicePosition)captureDevicePosition {
    // 切换摄像头，重置缩放比例
    self.zoomScale = 1.0;
    if(captureDevicePosition == self.videoCamera.cameraPosition) return;
    [self.videoCamera rotateCamera];
    self.videoCamera.frameRate = (int32_t)_configuration.fps;
    [self reloadMirror];
}

- (AVCaptureDevicePosition)captureDevicePosition {
    return [self.videoCamera cameraPosition];
}

- (void)setVideoFrameRate:(NSInteger)videoFrameRate {
    if (videoFrameRate <= 0) return;
    if (videoFrameRate == self.videoCamera.frameRate) return;
    self.videoCamera.frameRate = (uint32_t)videoFrameRate;
}

- (NSInteger)videoFrameRate {
    return self.videoCamera.frameRate;
}

- (void)setTorch:(BOOL)torch {
    BOOL ret = false;
    if (!self.videoCamera.captureSession) return;
    AVCaptureSession *session = (AVCaptureSession *)self.videoCamera.captureSession;
    [session beginConfiguration];
    if (self.videoCamera.inputCamera) {
        if (self.videoCamera.inputCamera.torchAvailable) {
            NSError *err = nil;
            if ([self.videoCamera.inputCamera lockForConfiguration:&err]) {
                [self.videoCamera.inputCamera setTorchMode:(torch ? AVCaptureTorchModeOn : AVCaptureTorchModeOff) ];
                [self.videoCamera.inputCamera unlockForConfiguration];
                ret = (self.videoCamera.inputCamera.torchMode == AVCaptureTorchModeOn);
            } else {
                NSLog(@"Error while locking device for torch: %@", err);
                ret = false;
            }
        } else {
            NSLog(@"Torch not available in current camera input");
        }
    }
    [session commitConfiguration];
    _torch = ret;
}

- (BOOL)torch {
    return self.videoCamera.inputCamera.torchMode;
}

- (void)setMirror:(BOOL)mirror {
    _mirror = mirror;
}

- (void)setBeautyFace:(BOOL)beautyFace{
    _beautyFace = beautyFace;
    [self reloadFilter];
}

- (void)setBeautyLevel:(CGFloat)beautyLevel {
    _beautyLevel = beautyLevel;
    if (self.beautyFilter) {
        [self.beautyFilter setBeautyLevel:_beautyLevel];
    }
}

- (CGFloat)beautyLevel {
    return _beautyLevel;
}

- (void)setBrightLevel:(CGFloat)brightLevel {
    _brightLevel = brightLevel;
    if (self.beautyFilter) {
        [self.beautyFilter setBrightLevel:brightLevel];
    }
}

- (CGFloat)brightLevel {
    return _brightLevel;
}

- (void)setZoomScale:(CGFloat)zoomScale {
    if (self.videoCamera && self.videoCamera.inputCamera) {
        AVCaptureDevice *device = (AVCaptureDevice *)self.videoCamera.inputCamera;
        if ([device lockForConfiguration:nil]) {
            device.videoZoomFactor = zoomScale;
            [device unlockForConfiguration];
            _zoomScale = zoomScale;
        }
    }
}

- (CGFloat)zoomScale {
    return _zoomScale;
}

- (void)setWarterMarkView:(UIView *)warterMarkView{
    if(_warterMarkView && _warterMarkView.superview){
        [_warterMarkView removeFromSuperview];
        _warterMarkView = nil;
    }
    _warterMarkView = warterMarkView;
    self.blendFilter.mix = warterMarkView.alpha;
    [self.waterMarkContentView addSubview:_warterMarkView];
    [self reloadFilter];
}

- (GPUImageUIElement *)uiElementInput{
    if(!_uiElementInput){
        _uiElementInput = [[GPUImageUIElement alloc] initWithView:self.waterMarkContentView];
    }
    return _uiElementInput;
}
/**注释：
 GPUImageNormalBlendFilter 就是把水印层图像添加到视频帧上，不做其他处理；
 GPUImageAlphaBlendFilter 水印层上的内容处于半透明的状态；
 GPUImageAddBlendFilter 水印层图像会受到视频帧本身滤镜的影响；
 GPUImageDissolveBlendFilter会造成视频帧变暗。
 */
/**水印层上的内容处于半透明的状态*/
- (GPUImageAlphaBlendFilter *)blendFilter{
    if(!_blendFilter){
        _blendFilter = [[GPUImageAlphaBlendFilter alloc] init];
        _blendFilter.mix = 1.0;
        [_blendFilter disableSecondFrameCheck];
    }
    return _blendFilter;
}

- (UIView *)waterMarkContentView{
    if(!_waterMarkContentView){
        _waterMarkContentView = [UIView new];
        _waterMarkContentView.frame = CGRectMake(0, 0, self.configuration.size.width, self.configuration.size.height);
        _waterMarkContentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
    return _waterMarkContentView;
}

- (GPUImageView *)gpuImageView{
    if(!_gpuImageView){
        _gpuImageView = [[GPUImageView alloc] initWithFrame:[UIScreen mainScreen].bounds];
        [_gpuImageView setFillMode:kGPUImageFillModePreserveAspectRatioAndFill];
        [_gpuImageView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
        UIPinchGestureRecognizer *pinchGestureRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchGestureDetected:)];
        [pinchGestureRecognizer setDelegate:self];
       /*加载到要缩放的图片*/
        [_gpuImageView addGestureRecognizer:pinchGestureRecognizer];
        
        UITapGestureRecognizer *singleFingerOne = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                          action:@selector(handleDoubleClickAction:)];
        singleFingerOne.numberOfTouchesRequired = 1; //手指数
        singleFingerOne.numberOfTapsRequired = 1; //tap次数
        singleFingerOne.delegate = self;
        [_gpuImageView addGestureRecognizer:singleFingerOne];
    }
    return _gpuImageView;
}

-(UIImage *)currentImage{
    if(_filter){
        [_filter useNextFrameForImageCapture];
        return _filter.imageFromCurrentFramebuffer;
    }
    return nil;
}

- (GPUImageMovieWriter*)movieWriter{
    if(!_movieWriter){
        _movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:self.saveLocalVideoPath size:self.configuration.size];
        _movieWriter.encodingLiveVideo = YES;
        _movieWriter.shouldPassthroughAudio = YES;
        self.videoCamera.audioEncodingTarget = self.movieWriter;
    }
    return _movieWriter;
}

#pragma mark -- Custom Method
///  setTouchZoomScale 更改焦距
-(void)handleDoubleClickAction:(UIPinchGestureRecognizer *)recognizer{
    CGPoint  point = [recognizer locationInView:recognizer.view];
    [self.focusView frameByAnimationCenter:point];
    [self setFocusPoint:point];
    
}
- (void)pinchGestureDetected:(UIPinchGestureRecognizer *)recognizer{
    /*获取状态*/
    UIGestureRecognizerState state = [recognizer state];
    if (state == UIGestureRecognizerStateBegan){
        _currentPinchZoomFactor = _zoomScale;
    }
    /*获取捏合大小比例*/
    CGFloat scale = [recognizer scale];
    /*获取捏合的速度*/
    //       CGFloat velocity = [recognizer velocity];
    CGFloat   zoomFactor = _currentPinchZoomFactor * scale;
    [self setZoomScale: (zoomFactor < 1) ? 1 : ((zoomFactor > 3) ? 3 : zoomFactor)];
}
/**点击聚焦*/
-(void) setFocusPoint:(CGPoint)point{
    AVCaptureDevice *device = (AVCaptureDevice *)self.videoCamera.inputCamera;
    if ([device isFocusPointOfInterestSupported] || [device isExposurePointOfInterestSupported]) {
        CGPoint  convertedFocusPoint = [self convertToPointOfInterestFromViewCoordinates:point captureVideoPreviewLayer:nil];
        [self autoFocusAtPoint:convertedFocusPoint];
    }
}
-(void)autoFocusAtPoint:(CGPoint )focusPoint{
    NSError *err = nil;
    AVCaptureDevice *device = (AVCaptureDevice *)self.videoCamera.inputCamera;

    if ([device isFocusPointOfInterestSupported] && [device isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
        if ([device lockForConfiguration:&err]) {
//            device.exposurePointOfInterest = focusPoint;
//            device.exposureMode = AVCaptureExposureModeAutoExpose;
            device.focusPointOfInterest = focusPoint;
            device.focusMode = AVCaptureFocusModeAutoFocus;
            [device unlockForConfiguration];
        }
    }
    if ([device isExposurePointOfInterestSupported] && [device isExposureModeSupported:AVCaptureExposureModeAutoExpose]) {
        if ([device lockForConfiguration:&err]) {
            device.exposurePointOfInterest = focusPoint;
            device.exposureMode = AVCaptureExposureModeAutoExpose;
//            device.focusPointOfInterest = focusPoint;
//            device.focusMode = AVCaptureFocusModeAutoFocus;
            [device unlockForConfiguration];
        }
    }
}
/**自动聚焦*/
-(void) setFocusPointAuto{
    [self setFocusPoint:self.preView.center];
}
- (BOOL)isPositionFront {
    return self.videoCamera.cameraPosition == AVCaptureDevicePositionFront;
}
-(CGPoint )convertToPointOfInterestFromViewCoordinates:(CGPoint )viewCoordinates  captureVideoPreviewLayer:(AVCaptureVideoPreviewLayer *)captureVideoPreviewLayer{
    CGPoint pointOfInterest = CGPointMake(.5f, .5f);
    if (captureVideoPreviewLayer) {
        CGSize frameSize = [captureVideoPreviewLayer frame].size;
        
        if ([captureVideoPreviewLayer.connection isVideoMirrored]) {
            viewCoordinates.x = frameSize.width - viewCoordinates.x;
        }
        
        // Convert UIKit coordinate to Focus Point(0.0~1.1)
        pointOfInterest = [captureVideoPreviewLayer captureDevicePointOfInterestForPoint:viewCoordinates];
        
        // NSLog(@"Focus - Auto test: %@",NSStringFromCGPoint(pointOfInterest));
    }else{
        // 坐标转换
        pointOfInterest = CGPointMake(viewCoordinates.y / self.gpuImageView.bounds.size.height, 1 - viewCoordinates.x / self.gpuImageView.bounds.size.width);
        if ([self isPositionFront]) {
            pointOfInterest = CGPointMake(pointOfInterest.x, 1 - pointOfInterest.y);
        }
    }
    return pointOfInterest;
}
- (void)reloadFilter{
    [self.filter removeAllTargets];
    [self.blendFilter removeAllTargets];
    [self.uiElementInput removeAllTargets];
    [self.videoCamera removeAllTargets];
    [self.output removeAllTargets];
    [self.cropfilter removeAllTargets];
    
    if (self.beautyFace) {
        self.output = [[ADYGPUImageEmptyFilter alloc] init];
        self.filter = [[ADYGPUImageBeautyFilter alloc] init];
        self.beautyFilter = (ADYGPUImageBeautyFilter*)self.filter;
    } else {
        self.output = [[ADYGPUImageEmptyFilter alloc] init];
        self.filter = [[ADYGPUImageEmptyFilter alloc] init];
        self.beautyFilter = nil;
    }
    
    ///< 调节镜像
    [self reloadMirror];
    ///< 480*640 比例为4:3  强制转换为16:9
    if([self.configuration.sessionPreset isEqualToString:AVCaptureSessionPreset640x480]){//裁剪
        CGRect cropRect = self.configuration.isLandscape ? CGRectMake(0, 0.125, 1, 0.75) : CGRectMake(0.125, 0, 0.75, 1);
        self.cropfilter = [[GPUImageCropFilter alloc] initWithCropRegion:cropRect];
        [self.videoCamera addTarget:self.cropfilter];
        [self.cropfilter addTarget:self.filter];
    }else{
        [self.videoCamera addTarget:self.filter];
    }
    
    ///< 添加水印
    /**
     * filter
     * blendFilter  半透明滤镜
     * uiElementInput 水印图形
     */
    if(self.warterMarkView){
        [self.filter addTarget:self.blendFilter];
        [self.uiElementInput addTarget:self.blendFilter];
        [self.blendFilter addTarget:self.gpuImageView];
        if(self.saveLocalVideo) [self.blendFilter addTarget:self.movieWriter];
        [self.filter addTarget:self.output];
        [self.uiElementInput update];
    }else{
        [self.filter addTarget:self.output];
        [self.output addTarget:self.gpuImageView];
        if(self.saveLocalVideo) [self.output addTarget:self.movieWriter];
    }
    
    [self.filter forceProcessingAtSize:self.configuration.size];
    [self.output forceProcessingAtSize:self.configuration.size];
    [self.blendFilter forceProcessingAtSize:self.configuration.size];
    [self.uiElementInput forceProcessingAtSize:self.configuration.size];
    
    
    /// 关系链
    _gpuOutput = [[GPUImagePixelBufferOutput alloc] initwithImageSize:_configuration.size];
    [self.output addTarget:_gpuOutput];
    
    /// 发送采集数据
    __weak typeof(self) weakSelf = self;
    _gpuOutput.pixelBufferCallback = ^(CVPixelBufferRef  _Nullable pixelBufferRef) {
        
//        if (pixelBufferRef && weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(captureOutput:pixelBuffer:isBeauty:)]) {
//            [weakSelf.delegate captureOutput:weakSelf pixelBuffer:pixelBufferRef isBeauty:NO];
//        }
    };
}

- (void)reloadMirror{
    if(self.mirror && self.captureDevicePosition == AVCaptureDevicePositionFront){
        self.videoCamera.horizontallyMirrorFrontFacingCamera = YES;
    }else{
        self.videoCamera.horizontallyMirrorFrontFacingCamera = NO;
    }
}

#pragma mark Notification

- (void)willEnterBackground:(NSNotification *)notification {
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    [self.videoCamera pauseCameraCapture];
    runSynchronouslyOnVideoProcessingQueue(^{
        glFinish();
    });
}

- (void)willEnterForeground:(NSNotification *)notification {
    [self.videoCamera resumeCameraCapture];
    [UIApplication sharedApplication].idleTimerDisabled = YES;
}

- (void)statusBarChanged:(NSNotification *)notification {
    NSLog(@"UIApplicationWillChangeStatusBarOrientationNotification. UserInfo: %@", notification.userInfo);
    UIInterfaceOrientation statusBar = [[UIApplication sharedApplication] statusBarOrientation];

    if(self.configuration.autorotate){
        if (self.configuration.isLandscape) {
            if (statusBar == UIInterfaceOrientationLandscapeLeft) {
                self.videoCamera.outputImageOrientation = UIInterfaceOrientationLandscapeRight;
            } else if (statusBar == UIInterfaceOrientationLandscapeRight) {
                self.videoCamera.outputImageOrientation = UIInterfaceOrientationLandscapeLeft;
            }
        } else {
            if (statusBar == UIInterfaceOrientationPortrait) {
                self.videoCamera.outputImageOrientation = UIInterfaceOrientationPortraitUpsideDown;
            } else if (statusBar == UIInterfaceOrientationPortraitUpsideDown) {
                self.videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
            }
        }
    }
}

- (void)willOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer{
    CVPixelBufferRef pixelBuffer = (CVPixelBufferRef)CMSampleBufferGetImageBuffer(sampleBuffer);
//    if (pixelBuffer && self.delegate && [self.delegate respondsToSelector:@selector(captureOutput:pixelBuffer:isBeauty:)]) {
//        [self.delegate captureOutput:self pixelBuffer:pixelBuffer isBeauty:YES];
//    }
}

@end
