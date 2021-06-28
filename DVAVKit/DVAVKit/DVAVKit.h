//
//  DVAVKit.h
//  DVAVKit
//
//  Created by DV on 2019/1/6.
//  Copyright © 2019 DVKit. All rights reserved.
//

#import <Foundation/Foundation.h>


#if __has_include(<DVAVKit/DVAVKit.h>)
FOUNDATION_EXPORT double DVAVKitVersionNumber;
FOUNDATION_EXPORT const unsigned char DVAVKitVersionString[];

#import <DVAVKit/DVFFmpegKit.h>
#import <DVAVKit/DVVideoToolKit.h>
#import <DVAVKit/DVAudioToolKit.h>
#import <DVAVKit/DVFlvKit.h>
#import <DVAVKit/DVRtmpKit.h>
#import <DVAVKit/DVLiveKit.h>
#import <DVAVKit/DVOpenGLKit.h>
#import <DVAVKit/DVGLKits.h>

//#import <DVAVKit/DVAudioPlayer.h>
//#import <DVAVKit/DVFFRtmpSocket.h>
//#import <DVAVKit/FFBuffer.h>
//#import <DVAVKit/FFFrame.h>
//#import <DVAVKit/FFH264Encodec.h>
//#import <DVAVKit/FFUtils.h>

#else

#import "DVFFmpegKit.h"
#import "DVVideoToolKit.h"
#import "DVAudioToolKit.h"
#import "DVFlvKit.h"
#import "DVRtmpKit.h"
#import "DVLiveKit.h"
#import "DVOpenGLKit.h"
#import "DVGLKits.h"

//#import "DVAudioPlayer.h"
//#import "DVFFRtmpSocket.h"
//#import "FFBuffer.h"
//#import "FFFrame.h"
//#import "FFH264Encodec.h"
//#import "FFUtils.h"

#endif
