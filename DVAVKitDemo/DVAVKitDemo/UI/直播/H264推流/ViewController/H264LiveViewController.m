//
//  H264LiveViewController.m
//  DVAVKitDemo
//
//  Created by mlgPro on 2020/4/10.
//  Copyright © 2020 DVUntilKit. All rights reserved.
//

#import "H264LiveViewController.h"

@interface H264LiveViewController () <DVLiveDelegate>

@property(nonatomic, strong) DVLive *live;

@end

@implementation H264LiveViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initLive];
    [self.live startLive];
    UIButton *b = [[UIButton alloc] initWithFrame:CGRectMake(self.view.width - 20 - 100,
                                                             self.view.height - 80,
                                                             100,
                                                             40)];
    b.title = @"翻转镜头";
    b.titleColor = [UIColor whiteColor];
    b.titleColorForHighlighted = [UIColor grayColor];
    [b addTarget:self action:@selector(onClickForChangeCamera:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:b];
    
}
-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
//    [self.live startLive];
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
  
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.live stopLive];
}


#pragma mark - <-- Init -->
- (void)initLive {
    
    DVVideoConfig *videoConfig = [DVVideoConfig kConfig_720P_24fps];
    videoConfig.position = AVCaptureDevicePositionFront;
    videoConfig.gop = videoConfig.fps;
    videoConfig.orientation = AVCaptureVideoOrientationLandscapeRight;
    DVAudioConfig *audioConfig = [DVAudioConfig kConfig_44k_16bit_2ch];
    
    self.live = [[DVLive alloc] initWithBeauty:YES];
    self.live.delegate = self;
    self.live.isEnableLog = YES;
    [self.live setVideoConfig:videoConfig];
    [self.live setAudioConfig:audioConfig];
    [self.live connectToURL:self.url];
    
    
    if (self.live.preView) {
        self.live.preView.frame = [DVFrame frame_full];
        [self.view insertSubview:self.live.preView atIndex:0];
    }
    
//    [self initBtnChangeCamera];
    
    
}


#pragma mark - <-- ACTION -->
- (void)onClickForChangeCamera:(UIButton *)sender {
    [super onClickForChangeCamera:sender];
    sender.selected = !sender.selected;
    if (sender.selected) {
        [self.live changeToBackCamera];
    } else {
        [self.live changeToFrontCamera];
    }
}

#pragma mark - <-- Delegate -->
- (void)DVLive:(DVLive *)live status:(DVLiveStatus)status {
    switch (status) {
        case DVLiveStatus_Disconnected:
            self.barBtn.title = @"未连接";
            break;
        case DVLiveStatus_Connecting:
            self.barBtn.title = @"连接中";
            break;
        case DVLiveStatus_Connected:
            self.barBtn.title = @"已连接";
            break;
        case DVLiveStatus_Reconnecting:
            self.barBtn.title = @"重新连接中";
            break;
        default:
            break;
    }
}

@end
