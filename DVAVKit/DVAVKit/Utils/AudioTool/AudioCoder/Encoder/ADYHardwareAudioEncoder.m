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
 * 概念
 * AAC - Advanced Audio Coding - 高级音频编码，基于 MPEG-2 的音频编码技术
 * 2000年后,MPEG-4标准发布，为了区别于MPEG-2 AAC 特别加入了SBR技术和PS技术，称之 MPEG-4
 * AAC （kAudioFormatMPEG4AAC）
 * 特点1: 压缩率提升，以更小的文件获得更高的音质
 * 特点2: 支持多通道
 * 特点3: 更高的解析度，最高支持96khz的采样率
 * 特点4: 更高的解码效率，解码占用资源更少
 * AAC音频文件的每一帧由ADTS Header和AAC Audio Data组成
 * AAC 的音频格式ADTS、ADIF
 * ADIF:
 * 音频数据交换格式化，可以确定的找到音频数据的开始处，即解码相关属性参数必须明确定义在文件开始处
 * ADTS: 音频数据传输流，他是一个有同步字的比特流，可以在音频流中任何位置开始，结构是
 * header&body，header&body...
 * 一般头信息有7（or 9）个字节，分为两部分adts_fixed_header()-28bits、adts_variable_header()-28bits、protection_absent=1  7字节      =0 9字节
 * @abstract  奥点官方网站  https://www.aodianyun.com
 
 */



#import "ADYHardwareAudioEncoder.h"
@interface ADYHardwareAudioEncoder (){
    AudioConverterRef m_converter; /* 音频格式转换工具 */
    char *leftBuf;                 /* char 指针--->pcm格式音频数据内存地址*/
    char *aacBuf;                  /* char 指针--->aac格式音频数据内存地址*/
    NSInteger leftLength;          /* 内存数据长度 */
    FILE *fp;                      /* 文件指针（用于打开文件进行操作） 详细参考本博客中pcm转mp3（方案一）*/
    BOOL enabledWriteVideoFile;    /* 是否本地保存转换后音频格式的文件 */
    NSUInteger bufferLength;
//    AudioConverterRef _converterRef;
    AudioStreamBasicDescription _inputBasicDesc;
    AudioStreamBasicDescription _outputBasicDesc;
}

@end

@implementation ADYHardwareAudioEncoder

@synthesize delegate = _delegate;

- (instancetype)initWithInputBasicDesc:(AudioStreamBasicDescription)inputBasicDesc
                       outputBasicDesc:(AudioStreamBasicDescription)outputBasicDesc
                              delegate:(id<DVAudioEncoderDelegate>)delegate {
    self = [super init];
    if (self) {
        self.delegate = delegate;
        _inputBasicDesc = inputBasicDesc;
        _outputBasicDesc = outputBasicDesc;
        bufferLength =1024*2*outputBasicDesc.mChannelsPerFrame;
        if (!leftBuf) {
            leftBuf = malloc(bufferLength);
        }
        
        if (!aacBuf) {
            aacBuf = malloc(bufferLength);
        }
        
        [self createAudioConvert];
    }
    return self;
}

- (void)dealloc {
    [self closeEncoder];
    _delegate = nil;
    /*
     void     free(void *);
     释放通过malloc（或calloc、realloc）函数申请的内存空间
     */
    if (aacBuf) free(aacBuf);
    if (leftBuf) free(leftBuf);
}
- (void)closeEncoder {
    [self uninitAudioConverter];
}
- (void)uninitAudioConverter {
    if (m_converter) {
        OSStatus status = AudioConverterDispose(m_converter);
//        AudioCheckStatus(status, @"注销编码器失败");
    }
}
#pragma mark -- ADYAudioEncoder
/**Public*/
-(void)encodeAudioData:(NSData *)audioData userInfo:(void *)timeStamp
{
    
//}
//- (void)encodeAudioData:(nullable NSData*)audioData timeStamp:(uint64_t)timeStamp {
//    if (![self createAudioConvert]) {
//        return;
//    }
    
    /* memcpy: C 和 C++ 常用的内存拷贝函数
     void *memcpy(void *dest, const void *src, size_t n);
     从源src指向的内存地址的起始位置开始拷贝n个字节到到dest指向的内存地址的起始位置处，返回指向dest内存地址的指针
     */
    /*
     预设条件:
     self.configuration.bufferLength = 100 字节
     全局变量初始化 leftLength=0
     char类型数据占用 1 个字节的内存
     
     《《《《《《《《《《 第一次收到数据 audioData.length = 40字节数据  》》》》》》》》》》
     leftLength + audioData.length = 0+40=40 < 100 所以走else逻辑
     1. 从 接收的pcm数据(audioData.bytes)的起始位置 拷贝 40 字节数据到以第0字节为开始的leftBuf内存地址(leftBuf+leftLength=0)
     2. 累积  leftLength = leftLength + audioData.length = 0 + 40 = 40
     
     
     《《《《《《《《《《 第二次收到数据 audioData.length = 55字节数据  》》》》》》》》》》
     leftLength + audioData.length = 40 + 55=95 < 100 所以走else逻辑
     1. 从 接收的pcm数据(audioData.bytes)的起始位置 拷贝 55 字节数据到以第40字节开始的leftBuf内存地址(0+40=40)
     2. 累积  leftLength = leftLength + audioData.length = 40 + 55 = 95
     
     
     《《《《《《《《《《 第三次收到数据 audioData.length = 120字节数据  》》》》》》》》》》
     audioData.length = 120
     leftLength + audioData.length = 95 + 120=215 > 100 所以走if逻辑
     
     1. 计算当前总字节数 totalSize = leftLength + audioData.length = 95 + 120 = 215
     2. 计算 循环发送编码数据次数 encodeCount = totalSize/self.configuration.bufferLength = 215 / 100 = 2
     3. 声明一个totalBuf指向 申请一块 totalSize 字节的内存空间地址的指针，指针不会发生偏移，一直指向开始位置
     4. 声明 p是一个变量指针（支持算数运算）记录发送的位置，指针会发生偏移
     5. 将 totalBuf 指向的内存空间清空（用于重新存放数据）
     6. 从 leftBuf 内存地址的0开始位置拷贝 leftLength = 95 字节数据到以第0字节开始的totalBuf内存地址中
     7. 从 pcm数据(audioData.bytes)的起始位置 拷贝 120 字节数据到以第95字节开始的totalBuf内存地址中(totalBuf+leftLength=0+95=95)
     8. 开始循环编码 （循环 encodeCount = 2 次）
     8-1. 从totalBuf起始位置0，发送 self.configuration.bufferLength = 100 字节数据进行编码
     8-2. 从totalBuf起始位置100，发送 self.configuration.bufferLength = 100 字节数据进行编码，
     8-3. 循环结束
     9. 计算剩余字节数 leftLength = totalSize%self.configuration.bufferLength = 215%100 = 15 字节
     10. 清空leftBuf
     11. 从 totalBuf 中 以第200（0+(215-15)）字节开始拷贝剩余的15字节到以第0字节开始的leftBuf内存地址中，继续累积
     12. 释放（系统回收） 申请的 totalBuf 的内存空间
     
     
     《《《《《《《《《《 第四次收到数据 audioData.length = 30字节数据  》》》》》》》》》》
     leftLength + audioData.length = 15+30=45 < 100 所以走else逻辑
     1. 从 接收的pcm数据(audioData.bytes)的起始位置 拷贝 30 字节数据到以第15字节开始的leftBuf内存地址(leftBuf+leftLength=15)
     2. 累积  leftLength = leftLength + audioData.length = 15 + 30 = 45
     
     
     《《《《《《《《《《 第 N 次收到数据 audioData.length = X字节数据  》》》》》》》》》》
     
     */
    /* 参考：https://www.jianshu.com/p/4dd2009b0902 对下面代码的逻辑解释*/
    if(leftLength + audioData.length >= bufferLength){
        ///<  发送
        NSInteger totalSize = leftLength + audioData.length;
        NSInteger encodeCount = totalSize/bufferLength;
        char *totalBuf = malloc(totalSize);
        char *p = totalBuf;
        /**函数解释：将totalBuf中当前位置后面的0个字节 （typedef unsigned int size_t ）用 totalSize 替换并返回 totalBuf 。*/
        memset(totalBuf, (int)totalSize, 0);
        memcpy(totalBuf, leftBuf, leftLength);
        memcpy(totalBuf + leftLength, audioData.bytes, audioData.length);
        
        for(NSInteger index = 0;index < encodeCount;index++){
            [self encodeBuffer:p  timeStamp:timeStamp];
            p += bufferLength;
        }
        
        leftLength = totalSize%bufferLength;
        memset(leftBuf, 0, bufferLength);
        memcpy(leftBuf, totalBuf + (totalSize -leftLength), leftLength);
        // 释放申请的内存空间
        free(totalBuf);
        
    }else{
        ///< 积累
        /*
         memcpy(leftBuf, audioData.bytes, audioData.length);
         如果按照上面的写法会导致把上一次copy的data给覆盖，就无法实现叠加效果。
         用一个全局变量 leftLength 保存上一次copy的data的长度，下一次在此基础上叠加，
         这样能够实现指针偏移的目的（指针偏移到上一次data的末尾处），但是指针指向也发生了变化。
         */
        memcpy(leftBuf+leftLength, audioData.bytes, audioData.length);
        leftLength = leftLength + audioData.length;
    }
}
/**
 *  AAC编码
 *
 *  @param buf audioBufferList
 *
 *  @return 返回经过AAC编码后的NSData
 */
- (void)encodeBuffer:(char*)buf timeStamp:(void *)timeStamp{
    /*
     设置输入缓冲
     */
    AudioBuffer inBuffer;
    inBuffer.mNumberChannels = 1;
    inBuffer.mData = buf;
    inBuffer.mDataByteSize = (UInt32)bufferLength;
    
    AudioBufferList buffers;
    buffers.mNumberBuffers = 1;
    buffers.mBuffers[0] = inBuffer;
    
    /*
     设置输出缓冲
     初始化一个输出缓冲列表
     */
    AudioBufferList outBufferList;
    outBufferList.mNumberBuffers = 1;
    outBufferList.mBuffers[0].mNumberChannels = inBuffer.mNumberChannels;
    outBufferList.mBuffers[0].mDataByteSize = inBuffer.mDataByteSize;   // 设置缓冲区大小
    outBufferList.mBuffers[0].mData = aacBuf;           // 设置AAC缓冲区
    UInt32 outputDataPacketSize = 1;
    /*
     音频格式转换（实现所有音频格式之间的转换，不限于AAC），返回AAC的原始音频数据流，然后需要添加ADTS头数据
     而 AudioConverterConvertComplexBuffer 把音频数据从线性PCM转换成其他格式，而转换的格式必须具有相同的采样率、通道等参数。
     
     param1. 编码器
     param2. 回调函数 编码过程中，会要求这个函数来填充输入数据（把原始PCM数据输入给编码器）
     param3. 输入缓冲数据的地址《指针类型》
     param4. 输出的包大小《指针类型》
     param5. 输出的缓冲数据的地址《指针类型》
     param6. 输出数据的描述
     */
    if (AudioConverterFillComplexBuffer(
                                        m_converter,
                                        inputDataProc,
                                        &buffers,
                                        &outputDataPacketSize,
                                        &outBufferList,
                                        NULL
                                        ) != noErr) {
        return;
    }
    
    
    NSData *outputData = [NSData dataWithBytes:aacBuf
                                        length:outBufferList.mBuffers[0].mDataByteSize];
    [self.delegate DVAudioEncoder:self codedData:outputData userInfo:timeStamp];
    
    
//    ADYAudioFrame *audioFrame = [ADYAudioFrame new];
//    audioFrame.timestamp = timeStamp;
//    audioFrame.data = [NSData dataWithBytes:aacBuf length:outBufferList.mBuffers[0].mDataByteSize];
    /*
     添加ADTS头信息 参考https://blog.csdn.net/jay100500/article/details/52955232
     
     self.asc[0] = 0x10 | ((sampleRateIndex>>1) & 0x7);
     self.asc[1] = ((sampleRateIndex & 0x1)<<7) | ((self.numberOfChannels & 0xF) << 3);
     */
//    char exeData[2];
//    exeData[0] = _configuration.asc[0];
//    exeData[1] = _configuration.asc[1];
//    audioFrame.audioInfo = [NSData dataWithBytes:exeData length:2];
//    if (self.aacDeleage && [self.aacDeleage respondsToSelector:@selector(audioEncoder:audioFrame:)]) {
//        [self.aacDeleage audioEncoder:self audioFrame:audioFrame];
//    }

    
}

#pragma mark -- CustomMethod
/**
 *  配置PCM到AAC转换器
 */
- (BOOL)createAudioConvert { //根据输入样本初始化一个编码转换器
    if (m_converter != nil) {
        return TRUE;
    }
    /*
     描述输入&输出的音频数据
     配置输入的音频格式,PCM格式
     */
    
//    AudioStreamBasicDescription inputFormat = {0};
//    inputFormat.mSampleRate = _configuration.audioSampleRate;
//    inputFormat.mFormatID = kAudioFormatLinearPCM;
//    inputFormat.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagsNativeEndian | kAudioFormatFlagIsPacked;
//    inputFormat.mChannelsPerFrame = (UInt32)_configuration.numberOfChannels;
//    inputFormat.mFramesPerPacket = 1;
//    inputFormat.mBitsPerChannel = 16;
//    inputFormat.mBytesPerFrame = inputFormat.mBitsPerChannel / 8 * inputFormat.mChannelsPerFrame;
//    inputFormat.mBytesPerPacket = inputFormat.mBytesPerFrame * inputFormat.mFramesPerPacket;
//
//    AudioStreamBasicDescription outputFormat; // 这里开始是输出音频格式
//    memset(&outputFormat, 0, sizeof(outputFormat));
//    outputFormat.mSampleRate = inputFormat.mSampleRate;       // 采样率保持一致
//    outputFormat.mFormatID = kAudioFormatMPEG4AAC;            // AAC编码 kAudioFormatMPEG4AAC kAudioFormatMPEG4AAC_HE_V2
//    outputFormat.mChannelsPerFrame = (UInt32)_configuration.numberOfChannels;;
//    outputFormat.mFramesPerPacket = 1024;                     // AAC一帧是1024个字节
    
    const OSType subtype = kAudioFormatMPEG4AAC;
    /*
     AudioClassDescription: 用于描述系统中安装的编解码工具
     音频编码器组件类型
     音频格式AAC
     软编码和硬编码
     */
    AudioClassDescription requestedCodecs[2] = {
        {
            kAudioEncoderComponentType,
            subtype,
            kAppleSoftwareAudioCodecManufacturer
        },
        {
            kAudioEncoderComponentType,
            subtype,
            kAppleHardwareAudioCodecManufacturer
        }
    };
    /*
     用特定的编码器创建一个音频转换工具对象
     param1. 输入格式
     param2. 输出格式
     param3. 编码器描述类个数
     param4. 编码器描述类
     param5. 编码器地址
     */
    OSStatus result = AudioConverterNewSpecific(&_inputBasicDesc, &_outputBasicDesc, 2, requestedCodecs, &m_converter);;
    UInt32 outputBitrate = 128000;
    UInt32 propSize = sizeof(outputBitrate);
    
    
    if(result == noErr) {
        /*
         设置编码器的码率属性
         */
        result = AudioConverterSetProperty(m_converter, kAudioConverterEncodeBitRate, propSize, &outputBitrate);
    }
    
    return YES;
}


#pragma mark -- AudioCallBack
/*
 inUserData 就是输入给编码器的 pcm 数据（就是AudioConverterFillComplexBuffer中 &inBufferList）
 把输入的pcm数据copy到ioData中，ioData就是编码器工作时用到的输入缓冲数据的地址
 */
OSStatus inputDataProc(AudioConverterRef inConverter, UInt32 *ioNumberDataPackets, AudioBufferList *ioData, AudioStreamPacketDescription * *outDataPacketDescription, void *inUserData) {
    ///< style="font-family: Arial, Helvetica, sans-serif;">AudioConverterFillComplexBuffer 编码过程中，会要求这个函数来填充输入数据，也就是原始PCM数据</span>
    AudioBufferList bufferList = *(AudioBufferList *)inUserData;
    ioData->mBuffers[0].mNumberChannels = 1;
    ioData->mBuffers[0].mData = bufferList.mBuffers[0].mData;
    ioData->mBuffers[0].mDataByteSize = bufferList.mBuffers[0].mDataByteSize;
    return noErr;
}


#pragma mark -- Custom Method
/**
 *  Add ADTS header at the beginning of each and every AAC packet.
 *  This is needed as MediaCodec encoder generates a packet of raw
 *  AAC data.
 *
 *  Note the packetLen must count in the ADTS header itself.
 *  See: http://wiki.multimedia.cx/index.php?title=ADTS
 *  Also: http://wiki.multimedia.cx/index.php?title=MPEG-4_Audio#Channel_Configurations
 **/
- (NSData *)adtsData:(NSInteger)channel rawDataLength:(NSInteger)rawDataLength {
    /* adts头信息的长度 7 字节 */
    int adtsLength = 7;
    /* 在堆区申请 7 字节的内存空间 */
    char *packet = malloc(sizeof(char) * adtsLength);
    // Variables Recycled by addADTStoPacket
    /* AAC LC Variables Recycled by addADTStoPacket */
    int profile = 2;  //AAC LC
    //39=MediaCodecInfo.CodecProfileLevel.AACObjectELD;
    /* 获取采样率对应的索引（下标）  39=MediaCodecInfo.CodecProfileLevel.AACObjectELD*/
    NSInteger freqIdx = [self sampleRateIndex:44100];  //44.1KHz
    /* 获取通道数*/
    int chanCfg = (int)channel;  //MPEG-4 Audio Channel Configuration. 1 Channel front-center
    /* 获取 adts头 + aac原始流 的总长度，即每一个aac数据帧的长度*/
    NSUInteger fullLength = adtsLength + rawDataLength;
    // fill in ADTS data
    packet[0] = (char)0xFF;     // 11111111     = syncword
    packet[1] = (char)0xF9;     // 1111 1 00 1  = syncword MPEG-2 Layer CRC
    packet[2] = (char)(((profile-1)<<6) + (freqIdx<<2) +(chanCfg>>2));
    packet[3] = (char)(((chanCfg&3)<<6) + (fullLength>>11));
    packet[4] = (char)((fullLength&0x7FF) >> 3);
    packet[5] = (char)(((fullLength&7)<<5) + 0x1F);
    packet[6] = (char)0xFC;
    NSData *data = [NSData dataWithBytesNoCopy:packet length:adtsLength freeWhenDone:YES];
    return data;
}

- (NSInteger)sampleRateIndex:(NSInteger)frequencyInHz {
    NSInteger sampleRateIndex = 0;
    switch (frequencyInHz) {
        case 96000:
            sampleRateIndex = 0;
            break;
        case 88200:
            sampleRateIndex = 1;
            break;
        case 64000:
            sampleRateIndex = 2;
            break;
        case 48000:
            sampleRateIndex = 3;
            break;
        case 44100:
            sampleRateIndex = 4;
            break;
        case 32000:
            sampleRateIndex = 5;
            break;
        case 24000:
            sampleRateIndex = 6;
            break;
        case 22050:
            sampleRateIndex = 7;
            break;
        case 16000:
            sampleRateIndex = 8;
            break;
        case 12000:
            sampleRateIndex = 9;
            break;
        case 11025:
            sampleRateIndex = 10;
            break;
        case 8000:
            sampleRateIndex = 11;
            break;
        case 7350:
            sampleRateIndex = 12;
            break;
        default:
            sampleRateIndex = 15;
    }
    return sampleRateIndex;
}

- (void)initForFilePath {
    NSString *path = [self GetFilePathByfileName:@"IOSCamDemo_HW.aac"];
    NSLog(@"%@", path);
    self->fp = fopen([path cStringUsingEncoding:NSUTF8StringEncoding], "wb");
}

- (NSString *)GetFilePathByfileName:(NSString*)filename {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *writablePath = [documentsDirectory stringByAppendingPathComponent:filename];
    return writablePath;
}

@end

