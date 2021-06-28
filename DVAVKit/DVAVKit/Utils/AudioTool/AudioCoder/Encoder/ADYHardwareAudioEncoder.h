//
//  Module:   ADYHardwareAudioEncoder   @ ADYLiveSDK
//
//  Function: 奥点云直播推流用 RTMP SDK
//
//  Copyright © 2021 杭州奥点科技股份有限公司. All rights reserved.
//
//  Version: 1.1.0  Creation(版本信息)

/**
 * @author   Created by 胡勤超 on 2021/5/26.
 * @instructions 说明
 该类是
 
 * @abstract  奥点官方网站  https://www.aodianyun.com
 
 */




#import "DVAudioEncoder.h"


NS_ASSUME_NONNULL_BEGIN

@interface ADYHardwareAudioEncoder : NSObject<DVAudioEncoder>

#pragma mark - Initializer
///=============================================================================
/// @name Initializer
///=============================================================================
- (nullable instancetype)init UNAVAILABLE_ATTRIBUTE;
+ (nullable instancetype)new UNAVAILABLE_ATTRIBUTE;
@end

NS_ASSUME_NONNULL_END
