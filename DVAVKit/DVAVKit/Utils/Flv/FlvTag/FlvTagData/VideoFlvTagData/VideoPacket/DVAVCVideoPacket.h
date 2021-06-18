//
//  DVAVCVideoPacket.h
//  iOS_Test
//
//  Created by DV on 2019/10/18.
//  Copyright © 2019 iOS. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - <-------------------- Define -------------------->
/**
 * 特殊情况
 * 视频的格式(CodecID)是AVC（H.264）的话，VideoTagHeader会多出4个字节的信息，AVCPacketType
 * 和CompositionTime。
 * AVCDecoderConfigurationRecord.包含着是H.264解码相关比较重要的sps和pps信息，再给AVC解码器送数据流之前一定要把sps和pps信息送出，否则的话解码器不能正常解码。而且在解码器stop之后再次start之前，如seek、快进快退状态切换等，都需要重新送一遍sps和pps的信息.AVCDecoderConfigurationRecord在FLV文件中一般情况也是出现1次，也就是第一个video tag.
 * @param DVAVCVideoPacketType_Header--->  AVCDecoderConfigurationRecord(AVC sequence header)；AVC序列头
 * @param DVAVCVideoPacketType_AVC--->  AVC NALU
 * @param DVAVCVideoPacketType_End--->  AVC end of sequence (lower level NALU sequence ender is not required or supported)；AVC序列结束（不需要或不支持较低级别的NALU序列结束符）
 */
typedef NS_ENUM(UInt8, DVAVCVideoPacketType) {
    DVAVCVideoPacketType_Header = 0x00,
    DVAVCVideoPacketType_AVC = 0x01,
    DVAVCVideoPacketType_End = 0x02,
};



#pragma mark - <-------------------- Class -------------------->
@interface DVAVCVideoPacket : NSObject

#pragma mark - <-- Property -->
@property(nonatomic, assign, readonly) DVAVCVideoPacketType packetType;
@property(nonatomic, assign, readonly) UInt32 timeStamp;
@property(nonatomic, strong, readonly) NSData *videoData;

@property(nonatomic, strong, readonly) NSData *fullData;
@property(nonatomic, assign, readonly) BOOL sei;

#pragma mark - <-- Initializer -->
+ (instancetype)headerPacketWithSps:(NSData *)sps pps:(NSData *)pps;
+ (instancetype)packetWithAVC:(NSData *)avcData timeStamp:(UInt32)timeStamp SEI:(BOOL)sei;
+ (instancetype)endPacket;

@end

NS_ASSUME_NONNULL_END
