//
//  DVVideoFlvTagData.m
//  iOS_Test
//
//  Created by DV on 2019/10/18.
//  Copyright © 2019 iOS. All rights reserved.
//

#import "DVVideoFlvTagData.h"

@interface DVVideoFlvTagData ()

@property(nonatomic, assign, readwrite) DVVideoFlvTagFrameType frameType;
@property(nonatomic, assign, readwrite) DVVideoFlvTagCodecIDType codecIDType;
@property(nonatomic, strong, readwrite) NSData *packetData;

@property(nonatomic, assign, readwrite) BOOL sei;
@end


@implementation DVVideoFlvTagData

#pragma mark - <-- Initializer -->
+ (instancetype)tagDataWithFrameType:(DVVideoFlvTagFrameType)frameType
                           avcPacket:(DVAVCVideoPacket *)packet  SEI:(BOOL)sei{
    
    DVVideoFlvTagData *tagData = [[DVVideoFlvTagData alloc] init];
    tagData.sei = sei;
    tagData.frameType = frameType;
    tagData.codecIDType = DVVideoFlvTagCodecIDType_AVC;
    tagData.packetData = packet.fullData;
    return tagData;
}

+ (instancetype)tagDataWithFrameType:(DVVideoFlvTagFrameType)frameType
                          hevcPacket:(DVHEVCVideoPacket *)packet  SEI:(BOOL)sei{
    DVVideoFlvTagData *tagData = [[DVVideoFlvTagData alloc] init];
    tagData.sei = sei;
    tagData.frameType = frameType;
    tagData.codecIDType = DVVideoFlvTagCodecIDType_HEVC;
    tagData.packetData = packet.fullData;
    
    return tagData;
}


#pragma mark - <-- Property -->
- (NSData *)fullData {
    NSMutableData *mData = [NSMutableData data];
    /**
     // 1:Iframe  7:AVC
     // 2:Pframe  7:AVC
     */
    UInt8 header = (_frameType << 4) | _codecIDType;
    [mData appendBytes:&header length:1];
    [mData appendData:self.packetData];
    return [mData copy];
}



@end
