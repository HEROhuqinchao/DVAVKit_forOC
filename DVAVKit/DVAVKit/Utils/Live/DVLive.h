//
//  DVLive.h
//  DVAVKit
//
//  Created by 施达威 on 2019/3/23.
//  Copyright © 2019 DVKit. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DVVideoConfig.h"
#import "DVAudioConfig.h"
#import "DVVideoCapture.h"
#import "DVBFVideoCamera.h"
NS_ASSUME_NONNULL_BEGIN

#pragma mark - <-------------------- Define -------------------->
typedef NS_ENUM(UInt8, DVLiveStatus) {
    DVLiveStatus_Disconnected = 0,
    DVLiveStatus_Connecting,
    DVLiveStatus_Connected,
    DVLiveStatus_Reconnecting,
};


#pragma mark - <-------------------- Protocol -------------------->
@class DVLive;
@protocol DVLiveDelegate <NSObject>

- (void)DVLive:(DVLive *)live status:(DVLiveStatus)status;

@end


#pragma mark - <-------------------- Class -------------------->
@interface DVLive : NSObject

#pragma mark - <-- Property -->
@property(nonatomic, strong, readonly) DVVideoConfig *videoConfig;
@property(nonatomic, strong, readonly) DVAudioConfig *audioConfig;

@property(nonatomic, weak, readonly, nullable) DVVideoCapture *camera;
@property(nonatomic, weak, readonly, nullable) DVBFVideoCamera *cameraBF;//美颜相机采集
@property(nonatomic, weak, readonly, nullable) UIView *preView;

@property(nonatomic, assign, readonly) DVLiveStatus liveStatus;
@property(nonatomic, assign, readonly) BOOL isLiving;
@property(nonatomic, assign, readonly) BOOL isBeauty;
@property(nonatomic, assign, readonly) BOOL isRecording;

@property(nonatomic, weak) id<DVLiveDelegate> delegate;

@property(nonatomic, assign) BOOL isEnableLog;


#pragma mark - <-- Method -->
- (void)setVideoConfig:(DVVideoConfig *)videoConfig;
- (void)setAudioConfig:(DVAudioConfig *)audioConfig;

- (void)connectToURL:(NSString *)url;
- (void)disconnect;

- (void)startLive;
- (void)stopLive;

- (void)changeToFrontCamera;
- (void)changeToBackCamera;



- (UIImage *)screenshot;
- (void)saveScreenshotToPhotoAlbum;

- (void)startRecordToURL:(NSString *)url;
- (void)startRecordToPhotoAlbum;
- (void)stopRecord;
/**
 * 初始化
 @param beauty 是否使用美颜相机
 */
- (instancetype)initWithBeauty:(BOOL)beauty;
@end

NS_ASSUME_NONNULL_END
