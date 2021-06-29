//
//  DVLive.m
//  DVAVKit
//
//  Created by 施达威 on 2019/3/23.
//  Copyright © 2019 DVKit. All rights reserved.
//

#import "DVLive.h"
#import "DVVideoToolKit.h"
#import "DVAudioToolKit.h"
#import "DVFlvKit.h"
#import "DVRtmpKit.h"
#import "ADYHardwareAudioEncoder.h"
#import "NTPManger.h"
@interface DVLive () < DVVideoCaptureDelegate,
                       DVAudioUnitDelegate,
                       DVVideoEncoderDelegate,
                       DVAudioEncoderDelegate,
                       DVRtmpDelegate,
                       DVRtmpBufferDelegate,
                       DVBFVideoCameraDelegate>
{
    
    NSTimeInterval timeInterval;   ///记录当前开始直播时时间戳
    uint64_t timeStamploc;          ///本地时钟计时器保存
    BOOL  isUpDataNTP;             /// 更新本地时间
    BOOL  isBeauty;                    /// 是否使用美颜相机
}

@property (nonatomic, strong) dispatch_source_t timer;

@property(nonatomic, strong, readwrite) DVVideoConfig *videoConfig;
@property(nonatomic, strong, readwrite) DVAudioConfig *audioConfig;
@property(nonatomic, strong, nullable) DVBFVideoCamera *videoBFCapture;//美颜相机采集
@property(nonatomic, strong, nullable) DVVideoCapture *videoCapture;//原相机采集
@property(nonatomic, strong, nullable) DVAudioUnit *audioUnit;
@property(nonatomic, strong, nullable) id<DVVideoEncoder> videoEncoder;
@property(nonatomic, strong, nullable) id<DVAudioEncoder> audioEncoder;
@property(nonatomic, strong, nullable) id<DVRtmp> rtmpSocket;

@property(nonatomic, strong) dispatch_semaphore_t videoEncoderLock;
@property(nonatomic, strong) dispatch_semaphore_t audioEncoderLock;

@property(nonatomic, assign, readwrite) DVLiveStatus liveStatus;
@property(nonatomic, assign, readwrite) BOOL isLiving;
@property(nonatomic, assign, readwrite) BOOL isRecording;

@property(nonatomic, strong) NSFileHandle *fileHandle;
@property(nonatomic, strong) dispatch_queue_t fileQueue;
@property(nonatomic, copy) NSString *recordPath;

@end


@implementation DVLive

#pragma mark - <-- Initializer -->
- (instancetype)initWithBeauty:(BOOL)beauty {
    self = [super init];
    if (self) {
        [self initLock];
        [self initSession];
        [self initRtmpSocket];
        timeInterval = 0.0;
        timeStamploc = 0.0;
        isUpDataNTP = NO;
        isBeauty = beauty;
    }
    return self;
}

- (void)dealloc {
    if (self.timer) {
        //停止定时器
        dispatch_source_cancel(self.timer);
        self.timer = nil;
    }
    if (_videoBFCapture) {
        [_videoBFCapture stop];
        _videoBFCapture.delegate = nil;
        _videoBFCapture = nil;
    }
     if (_videoCapture) {
        [_videoCapture stop];
        _videoCapture.delegate = nil;
        _videoCapture = nil;
    }
    
    if (_audioUnit) {
        [_audioUnit stop];
        _audioUnit.delegate = nil;
        _audioUnit = nil;
    }
    
    if (_videoEncoder) {
        [_videoEncoder closeEncoder];
        _videoEncoder.delegate = nil;
        _videoEncoder = nil;
    }
    
    if (_audioEncoder) {
        [_audioEncoder closeEncoder];
        _audioEncoder.delegate = nil;
        _audioEncoder = nil;
    }
    
    if (_rtmpSocket) {
        [_rtmpSocket disconnect];
        _rtmpSocket.delegate = nil;
        _rtmpSocket.bufferDelegate = nil;
        _rtmpSocket = nil;
    }
    
    if (_fileHandle) {
        dispatch_sync(self.fileQueue, ^{
            [_fileHandle closeFile];
            _fileHandle = nil;
        });
    }
}


#pragma mark - <-- Property -->
- (UIView *)preView {
    if (isBeauty) {
        return self.videoBFCapture ? self.videoBFCapture.preView : nil;
    }
    return self.videoCapture ? self.videoCapture.preView : nil;
}

- (DVVideoCapture *)camera {
    return self.videoCapture;
}
-(DVBFVideoCamera *)cameraBF{
    return self.videoBFCapture;
}
-(BOOL)isBeauty{
    return isBeauty;
}
- (BOOL)isLiving {
    BOOL status = NO;
    if (self.videoCapture && self.audioUnit && self.rtmpSocket) {
        status = self.videoCapture.isRunning
                || self.audioUnit.isRunning
                || self.rtmpSocket.rtmpStatus == DVRtmpStatus_Connected;
    }
    if (isBeauty) {
        if (self.videoBFCapture && self.audioUnit && self.rtmpSocket) {
            status = self.videoBFCapture.isRunning
                    || self.audioUnit.isRunning
                    || self.rtmpSocket.rtmpStatus == DVRtmpStatus_Connected;
        }
    }
    return status;
}

/**
 * 切换手机摄像头 默认前置后置切换
 * 切换前置
 */
- (void)changeToFrontCamera{
    if (self.isBeauty) {
        [self.cameraBF changeToFrontCamera];
    }else{
        [self.camera changeToFrontCamera];
    }
}
///  切换后置
- (void)changeToBackCamera{
    if (self.isBeauty) {
        [self.cameraBF changeToBackCamera];
    }else{
        [self.camera changeToBackCamera];
    }
}

- (dispatch_queue_t)fileQueue {
    if (!_fileQueue) {
        _fileQueue = dispatch_queue_create("com.dv.avkit.live.record", nil);
    }
    return _fileQueue;
}

- (NSFileHandle *)fileHandle {
    if (!_fileHandle && _recordPath) {
        self.fileHandle = [NSFileHandle fileHandleForWritingAtPath:_recordPath];
        [self.fileHandle seekToEndOfFile];
    }
    return _fileHandle;
}


#pragma mark - <-- Init -->
- (void)initLock {
    self.videoEncoderLock = dispatch_semaphore_create(1);
    self.audioEncoderLock = dispatch_semaphore_create(1);
}

- (void)initSession {
    NSError *error;
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    
    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:&error];
    [self printfError:error];
    
    [audioSession setActive:YES error:&error];
    [self printfError:error];
}

- (void)initRtmpSocket {
    self.rtmpSocket = [[DVRtmpSocket alloc] initWithDelegate:self];
    self.rtmpSocket.bufferDelegate = self;
}


#pragma mark - <-- Public Method -->
- (void)setVideoConfig:(DVVideoConfig *)videoConfig {
    if (self.isLiving) {
        [self printfLog:@"请先关闭推流和断开连接，再配置视频参数"];
        return;
    }
    
    _videoConfig = videoConfig;

    // 1.初始化摄像头
    if (isBeauty) {
        if (!self.videoBFCapture) {
            self.videoBFCapture = [[DVBFVideoCamera alloc] initWithVideoConfiguration:videoConfig delegate:self];
        } else {
            [self.videoBFCapture updateConfig:videoConfig];
        }
    }else{
        if (!self.videoCapture) {
            self.videoCapture = [[DVVideoCapture alloc] initWithConfig:videoConfig delegate:self];
            [self.videoCapture updateCamera:^(DVVideoCamera * _Nonnull camera) {
                camera.stabilizationMode = AVCaptureVideoStabilizationModeAuto;
            }];
        } else {
            [self.videoCapture updateConfig:videoConfig];
        }
    }

    
    // 2.初始化视频编码器
    if (self.videoEncoder) {
        [self.videoEncoder closeEncoder];
        self.videoEncoder = nil;
    }
    self.videoEncoder = [self newVideoEncoderWithVideoConfig:videoConfig];
    
    
    // 3.设置rtmp头信息
    [self.rtmpSocket setMetaHeader:[self metaHeader]];
}

- (void)setAudioConfig:(DVAudioConfig *)audioConfig {
    if (self.isLiving) {
        [self printfLog:@"请先关闭推流和断开连接，再配置音频参数"];
        return;
    }
    
    _audioConfig = audioConfig;
    
    // 1.初始化录音
    if (!self.audioUnit) {
        AudioComponentDescription desc = [DVAudioComponentDesc kComponentDesc_Output_IO];
        NSError *error = nil;
        self.audioUnit = [[DVAudioUnit alloc] initWithComponentDesc:desc
                                                           delegate:self
                                                              error:&error];
        [self.audioUnit setupUnitConfig:^(DVAudioUnit * _Nonnull au) {
            au.IO.audioFormat = [DVAudioStreamBaseDesc pcmBasicDescWithConfig:audioConfig];
            au.IO.inputPortStatus = YES;
            au.IO.inputCallBackSwitch = YES;
            au.IO.outputPortStatus = YES;
            au.IO.bypassVoiceProcessingStatus = YES;

        }];
        
        [self printfError:error];
    } else {
        [self.audioUnit clearUnitConfig];
        [self.audioUnit setupUnitConfig:^(DVAudioUnit * _Nonnull au) {
            au.IO.audioFormat = [DVAudioStreamBaseDesc pcmBasicDescWithConfig:audioConfig];
            au.IO.inputPortStatus = YES;
            au.IO.inputCallBackSwitch = YES;
            au.IO.outputPortStatus = YES;
            au.IO.bypassVoiceProcessingStatus = YES;

        }];
    }
    
   
    // 2.初始化音频编码器
    if (self.audioEncoder) {
        [self.audioEncoder closeEncoder];
        self.audioEncoder = nil;
    }
    self.audioEncoder = [self newAudioEncoderWithAudioConfig:audioConfig];
    
    
    // 3.设置rtmp头信息
    [self.rtmpSocket setMetaHeader:[self metaHeader]];
    [self.rtmpSocket setAudioHeader:[self audioHeader]];
}

- (void)connectToURL:(NSString *)url {
    [self.rtmpSocket connectToURL:url];
}

- (void)disconnect {
    [self.rtmpSocket disconnect];
}

- (void)startLive {
    if (!_videoConfig || !_audioConfig) {
        [self printfLog:@"推流开启失败, 请先设置 VideoConfig 和 AudioConfig"];
        return;
    }
    if (isBeauty) {
        if (self.videoBFCapture) [self.videoBFCapture start];
    }else{
        if (self.videoCapture) [self.videoCapture start];
    }
    if (self.audioUnit) [self.audioUnit start];
    if (!self.timer) [self upDataNTPTime];
}

- (void)stopLive {
    if (!_videoConfig || !_audioConfig) {
        [self printfLog:@"推流关闭失败, 请先设置 VideoConfig 和 AudioConfig"];
        return;
    }
    if (isBeauty) {
        if (self.videoBFCapture) [self.videoBFCapture stop];
    }else{
        if (self.videoCapture) [self.videoCapture stop];
    }
    if (self.audioUnit) [self.audioUnit stop];
    //停止定时器
    dispatch_source_cancel(self.timer);
    self.timer = nil;
}

- (UIImage *)screenshot {
    return nil;
}

- (void)saveScreenshotToPhotoAlbum {
    
}

- (void)startRecordToURL:(NSString *)url {
    if (self.isRecording) {
        [self printfLog:@"正在录影中, 先停止录影"];
        return;
    }
    
    self.isRecording = YES;
}

- (void)startRecordToPhotoAlbum {
    if (self.isRecording) {
        [self printfLog:@"正在录影中, 先停止录影"];
        return;
    }
    
    self.isRecording = YES;
}

- (void)stopRecord {

}


#pragma mark - <-- Private Method -->
- (DVMetaFlvTagData *)metaHeader {
    if (!self.videoConfig || !self.audioConfig) return nil;
    
    DVMetaFlvTagData *tagData = [[DVMetaFlvTagData alloc] init];
    
    tagData.videoWidth = self.videoConfig.size.width;
    tagData.videoHeight = self.videoConfig.size.height;
    tagData.videoBitRate = self.videoConfig.bitRate;
    tagData.videoFps = self.videoConfig.fps;
    
    tagData.audioSampleRate = self.audioConfig.sampleRate;
    tagData.audioBits = self.audioConfig.bitsPerChannel;
    tagData.audioChannels = self.audioConfig.numberOfChannels;
    tagData.audioDataRate = self.audioConfig.bitRate;
    
    return tagData;
}

- (DVVideoFlvTagData *)videoHeaderWithVPS:(NSData *)vps sps:(NSData *)sps pps:(NSData *)pps {
    if (!self.videoConfig) return nil;
    
    DVVideoFlvTagData *tagData = nil;
    
    if (self.videoConfig.encoderType == DVVideoEncoderType_H264_Hardware) {
        DVAVCVideoPacket *packet = [DVAVCVideoPacket headerPacketWithSps:sps pps:pps];
        tagData = [DVVideoFlvTagData tagDataWithFrameType:DVVideoFlvTagFrameType_Key avcPacket:packet];
    }
    else if (self.videoConfig.encoderType == DVVideoEncoderType_HEVC_Hardware) {
        DVHEVCVideoPacket *packet = [DVHEVCVideoPacket headerPacketWithVps:vps sps:sps pps:pps];
        tagData = [DVVideoFlvTagData tagDataWithFrameType:DVVideoFlvTagFrameType_Key hevcPacket:packet];
    }
    
    return tagData;
}

- (DVAudioFlvTagData *)audioHeader {
    if (!self.audioConfig) return nil;
    
    DVAACAudioPacket *aacPacket = [DVAACAudioPacket headerPacketWithSampleRate:self.audioConfig.sampleRate
                                                                      channels:self.audioConfig.numberOfChannels];
    DVAudioFlvTagData *tagData = [DVAudioFlvTagData tagDataWithAACPacket:aacPacket];
    
    return tagData;
}

- (DVRtmpPacket *)videoPacketWithData:(NSData *)data
                           isKeyFrame:(BOOL)isKeyFrame
                            timeStamp:(uint64_t)timeStamp SEI:(BOOL)sei{
    
    DVRtmpPacket * packet = [[DVRtmpPacket alloc] init];
    NSData *videoData;
    if (sei) {
        if (isUpDataNTP == NO) {
            timeStamploc = timeStamp; //保存旧时间
            isUpDataNTP = YES;
        }
        videoData = [self creatSEIVideoData:data timeStamp:timeStamp];
    }else{
        videoData = data;
    }
    packet.timeStamp = (uint32_t)timeStamp;
    DVVideoFlvTagFrameType frameType = isKeyFrame ? DVVideoFlvTagFrameType_Key : DVVideoFlvTagFrameType_NotKey;
    
    if (_videoConfig.encoderType == DVVideoEncoderType_H264_Hardware) {
        DVAVCVideoPacket *avcPacket = [DVAVCVideoPacket packetWithAVC:videoData timeStamp:0];
        packet.videoData = [DVVideoFlvTagData tagDataWithFrameType:frameType avcPacket:avcPacket];
    }
    else if (_videoConfig.encoderType == DVVideoEncoderType_HEVC_Hardware) {
        DVHEVCVideoPacket *hevcPacket = [DVHEVCVideoPacket packetWithHEVC:data timeStamp:0];
        packet.videoData = [DVVideoFlvTagData tagDataWithFrameType:frameType hevcPacket:hevcPacket];
    }
    
    return packet;
}
-(NSData *)creatSEIVideoData:(NSData *)videoData timeStamp:(uint64_t)timeStamp{
    //     计算差值
    NSTimeInterval difference = (NSTimeInterval)(timeStamp - timeStamploc);
    NSTimeInterval  ntpTime = timeInterval + difference;
    /// SEI 信息拼接
    NSMutableData *data = [[NSMutableData alloc] init];
    /// SEI 帧特征 - 头
    uint8_t header6[] = {0x06, 0x05};
    [data appendBytes:header6 length:2];
    /// 标识后面自定义包体长度  -- 默认33位
    uint8_t customLength[] = {0x21};
    [data appendBytes:customLength length:1];
    /// 是16 字节的 uuid 固定不变
    uint8_t uuid[] = {0x6c, 0x63, 0x70, 0x73, 0x62, 0x35, 0x64, 0x61, 0x39, 0x66, 0x34, 0x36, 0x35, 0x64, 0x33, 0x66};
    [data appendBytes:uuid length:16];
    /// 标识此扩展的子分类 帧同步固定为 01
    uint8_t type[] = {0x01};
    [data appendBytes:type length:1];
    /// 分类信息体长度--此时默认15-时间字符串形式-「210615112934112」--表示 21年06月15号11时29分34秒112毫秒
    uint8_t length[] = {0x0f};
    [data appendBytes:length length:1];
    /// 信息体 --是时间字符串表示形式，例如 20年06月24日14时15分30秒123毫秒
    NSData *seiMsg=[NSMutableData dataWithData:[[self timestampSwitchTime:ntpTime andFormatter:@"YYMMddHHmmssSSS"] dataUsingEncoding:NSUTF8StringEncoding]];
    [data appendData:seiMsg];
    /// SEI 帧特征 - 尾
    uint8_t tail[] = {0x80};
    [data appendBytes:tail length:1];
    NSInteger i = 0;
    NSInteger rtmpLength = data.length + 4;
    unsigned char *body = (unsigned char *)malloc(rtmpLength);
    /// 取出视频原始数据长度
    body[i++] = (data.length >> 24) & 0xff;
    body[i++] = (data.length >> 16) & 0xff;
    body[i++] = (data.length >>  8) & 0xff;
    body[i++] = (data.length) & 0xff;
    memcpy(&body[i], data.bytes, data.length);
    NSData *seiData = [NSData dataWithBytes:body length:rtmpLength];
    NSMutableData *dataVideo = [[NSMutableData alloc] init];
    [dataVideo appendData:seiData];
    [dataVideo appendData:videoData];
    return dataVideo;
}
- (NSString *)timestampSwitchTime:(NSInteger)timestamp andFormatter:(NSString *)format{
    
    NSTimeInterval _interval = timestamp/ 1000.000;
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:_interval];
    NSDateFormatter *objDateformat = [[NSDateFormatter alloc] init];
    [objDateformat setDateFormat:@"YYMMddHHmmssSSS"];
//    NSString  *time = [objDateformat stringFromDate: date];
    return [objDateformat stringFromDate: date];
}
-(void)upDataNTPTime{
    //创建队列
   dispatch_queue_t queue = dispatch_get_main_queue();
   //创建定时器
   self.timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
   //设置定时器时间
   dispatch_time_t start = dispatch_time(DISPATCH_TIME_NOW, 0);
   //60秒执行一次
   uint64_t interval = (uint64_t)(60.0 * NSEC_PER_SEC);
   dispatch_source_set_timer(self.timer, start, interval, 0);
   //设置回调
   dispatch_source_set_event_handler(self.timer, ^{
       //重复执行的事件
       self->timeInterval = [NTPManger GetNtpTimeForHost:@"ntp.aodianyun.com"];
       NSLog(@"进行 更新NTP：%f",self->timeInterval);
       self->isUpDataNTP = NO;
   });
   //启动定时器
   dispatch_resume(self.timer);
}
- (DVRtmpPacket *)audioPacketWithData:(NSData *)data
                            timeStamp:(uint64_t)timeStamp {
   
    DVRtmpPacket *packet = [[DVRtmpPacket alloc] init];
    packet.timeStamp = (uint32_t)timeStamp;
    
    DVAACAudioPacket *aacPacket = [DVAACAudioPacket packetWithAAC:data];
    packet.audioData = [DVAudioFlvTagData tagDataWithAACPacket:aacPacket];
       
    return packet;
}

- (id<DVVideoEncoder>)newVideoEncoderWithVideoConfig:(DVVideoConfig *)videoConfig {
    id<DVVideoEncoder> videoEncoder;
    
    if (videoConfig.encoderType == DVVideoEncoderType_H264_Hardware) {
        videoEncoder = [[DVVideoH264HardwareEncoder alloc] initWithConfig:videoConfig delegate:self];
    }
    else if (videoConfig.encoderType == DVVideoEncoderType_HEVC_Hardware) {
        videoEncoder = [[DVVideoHEVCHardwareEncoder alloc] initWithConfig:videoConfig delegate:self];
    }
    
    return videoEncoder;
}

- (id<DVAudioEncoder>)newAudioEncoderWithAudioConfig:(DVAudioConfig *)audioConfig {
    id<DVAudioEncoder> audioEncoder;
    
    AudioStreamBasicDescription inputDesc = [DVAudioStreamBaseDesc pcmBasicDescWithConfig:audioConfig];
    AudioStreamBasicDescription outputDesc = [DVAudioStreamBaseDesc aacBasicDescWithConfig:audioConfig];
    audioEncoder = [[DVAudioAACHardwareEncoder alloc] initWithInputBasicDesc:inputDesc
                                                             outputBasicDesc:outputDesc
                                                                    delegate:self];
    
    return audioEncoder;
}

- (void)createFileAtPath:(NSString *)path {
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
       NSError *error;
       [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
       [self printfError:error];
   }
   
   [[NSFileManager defaultManager] createFileAtPath:path contents:nil attributes:nil];
}


#pragma mark - <-- Printf Method -->
- (void)printfLog:(NSString *)log {
    if (self.isEnableLog && log) NSLog(@"[DVLive LOG]: %@", log);
}

- (void)printfError:(NSError *)error {
    if (self.isEnableLog && error) NSLog(@"[DVLive ERROR]: %@", error.localizedDescription);
}


#pragma mark - <-- Capture Delegate -->
-(void)DVBFVideoCamera:(DVBFVideoCamera *)capture outputSampleBuffer:(CVPixelBufferRef)sampleBuffer isBeauty:(BOOL)isBeauty{
    if (self.videoEncoder) {
        NSNumber *timeStampNum = [NSNumber numberWithUnsignedLongLong:RTMP_TIMESTAMP_NOW];
        [self.videoEncoder encodeVideoPxBuffer:sampleBuffer userInfo:(__bridge void *)timeStampNum];
    }
}
- (void)DVVideoCapture:(DVVideoCapture *)capture
    outputSampleBuffer:(CMSampleBufferRef)sampleBuffer
                 error:(DVVideoError *)error {
    
    if (self.videoEncoder && !error) {
        NSNumber *timeStampNum = [NSNumber numberWithUnsignedLongLong:RTMP_TIMESTAMP_NOW];
        [self.videoEncoder encodeVideoBuffer:sampleBuffer userInfo:(__bridge void *)timeStampNum];
    }
}

//- (void)DVAudioUnit:(DVAudioUnit *)audioUnit recordData:(void *)mdata size:(UInt32)mSize error:(DVAudioError *)error
//{
//        if (self.audioEncoder && !error) {
//            NSNumber *timeStampNum = [NSNumber numberWithUnsignedLongLong:RTMP_TIMESTAMP_NOW];
//            [self.audioEncoder encodeAudioData:mdata size:mSize userInfo:(__bridge void *)timeStampNum];
//        }
//}
- (void)DVAudioUnit:(DVAudioUnit *)audioUnit recordData:(NSData *)data error:(DVAudioError *)error {

    if (self.audioEncoder && !error) {
        NSNumber *timeStampNum = [NSNumber numberWithUnsignedLongLong:RTMP_TIMESTAMP_NOW];
        [self.audioEncoder encodeAudioData:data userInfo:(__bridge void *)timeStampNum];
    }
}


#pragma mark - <-- Encoder Delegate -->
- (void)DVVideoEncoder:(id<DVVideoEncoder>)encoder vps:(NSData *)vps sps:(NSData *)sps pps:(NSData *)pps {
    [self printfLog:[NSString stringWithFormat:@"取得 vps:%lu sps:%lu  pps:%lu", (unsigned long)vps.length, (unsigned long)sps.length, (unsigned long)pps.length]];
        
    DVVideoFlvTagData *tagData = [self videoHeaderWithVPS:vps sps:sps pps:pps];
    if (tagData) [self.rtmpSocket setVideoHeader:tagData];
    
    
    if (self.isRecording) {
        dispatch_async(self.fileQueue, ^{
            if(vps) [self.fileHandle writeData:[encoder convertToNALUWithSpsOrPps:vps]];
            if(sps) [self.fileHandle writeData:[encoder convertToNALUWithSpsOrPps:sps]];
            if(pps) [self.fileHandle writeData:[encoder convertToNALUWithSpsOrPps:pps]];
        });
    }
}

- (void)DVVideoEncoder:(id<DVVideoEncoder>)encoder
             codedData:(NSData *)data
            isKeyFrame:(BOOL)isKeyFrame
              userInfo:(void *)userInfo SEI:(BOOL)sei{
    
    NSNumber *value = (__bridge NSNumber *)userInfo;
    uint64_t timeStamp = (uint64_t)[value unsignedLongLongValue];
    
    DVRtmpPacket *packet = [self videoPacketWithData:data isKeyFrame:isKeyFrame timeStamp:timeStamp SEI:sei];
    
    [self.rtmpSocket sendPacket:packet];

    
    if (isKeyFrame) [self printfLog:[NSString stringWithFormat:@"取得关键帧 -> %llu", timeStamp]];
    
    if (self.isRecording) {
        dispatch_async(self.fileQueue, ^{
            [self.fileHandle writeData:[encoder convertToNALUWithData:data isKeyFrame:isKeyFrame]];
        });
    }
}

- (void)DVAudioEncoder:(id<DVAudioEncoder>)encoder codedData:(NSData *)data userInfo:(void *)userInfo {
    
    NSNumber *value = (__bridge NSNumber *)userInfo;
    uint64_t timeStamp = (uint64_t)[value unsignedLongLongValue];

    DVRtmpPacket *packet = [self audioPacketWithData:data timeStamp:timeStamp];
    [self.rtmpSocket sendPacket:packet];
}


#pragma mark - <-- RTMP Delegate -->
- (void)DVRtmp:(id<DVRtmp>)rtmp status:(DVRtmpStatus)status {
    self.liveStatus = (DVLiveStatus)status;
    if (self.delegate) [self.delegate DVLive:self status:self.liveStatus];
    
    NSString *desc = nil;
    switch (status) {
        case DVRtmpStatus_Disconnected:
            desc = @"未连接";
            break;
        case DVRtmpStatus_Connecting:
            desc = @"连接中";
            break;
        case DVRtmpStatus_Connected:
            desc = @"已连接";
            break;
        case DVRtmpStatus_Reconnecting:
            desc = @"重新连接中";
            break;
        default:
            break;
    }
    
    [self printfLog:desc];
}

- (void)DVRtmp:(id<DVRtmp>)rtmp error:(DVRtmpError *)error {
    [self printfError:error];
}

- (void)DVRtmpBuffer:(DVRtmpBuffer *)rtmpBuffer bufferStatus:(DVRtmpBufferStatus)bufferStatus {
    switch (bufferStatus) {
        case DVRtmpBufferStatus_Steady:
            [self printfLog:@"缓冲平稳"];
            break;
        case DVRtmpBufferStatus_Increase:
            [self printfLog:@"缓冲持续上涨"];
            
            if (self.videoConfig.adaptiveBitRate) {
                self.videoEncoder.bitRate -= 100 * 1024;
                if (self.videoEncoder.bitRate < self.videoConfig.minBitRate) {
                    self.videoEncoder.bitRate = self.videoConfig.minBitRate;
                }
            }

            break;
        case DVRtmpBufferStatus_Decrease:
            [self printfLog:@"缓冲持续下降"];

            if (self.videoConfig.adaptiveBitRate) {
                self.videoEncoder.bitRate += 100 * 1024;
                if (self.videoEncoder.bitRate > self.videoConfig.maxBitRate) {
                    self.videoEncoder.bitRate = self.videoConfig.maxBitRate;
                }
            }
            
            break;
        default:
            break;
    }
    
    NSUInteger kbs = self.videoEncoder.bitRate / 1024;
    [self printfLog:[NSString stringWithFormat:@"码率: %lu kb/s", (unsigned long)kbs]];
}

- (void)DVRtmpBuffer:(DVRtmpBuffer *)rtmpBuffer
  bufferOverMaxCount:(NSArray<DVRtmpPacket *> *)bufferList
        deleteBuffer:(void (^)(NSArray<DVRtmpPacket *> * _Nonnull))deleteBlock {
    

}

@end
