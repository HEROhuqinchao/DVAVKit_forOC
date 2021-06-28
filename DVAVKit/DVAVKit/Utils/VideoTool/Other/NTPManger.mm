//
//  NTPManger.m
//  DVAVKit
//
//  Created by 胡勤超 on 2021/6/22.
//  Copyright © 2021 MyKit. All rights reserved.
//

#import "NTPManger.h"
#import "NTP.hpp"
@implementation NTPManger
+ (NSTimeInterval )GetNtpTimeForHost:(NSString *)host_OC{
    struct timeval TimeSet;
    memset(&TimeSet ,0 ,sizeof(TimeSet));
    static struct hostent *host = NULL;
    const char * name = [host_OC UTF8String];
    host = gethostbyname(name);
    getNtpTime(host, &TimeSet);
    NSString  *timeval_OC = [NSString stringWithFormat:@"%ld%ld",(long)TimeSet.tv_sec,(long)TimeSet.tv_usec];
    NSString *ntpTime = [timeval_OC substringToIndex:13];
    return [ntpTime integerValue];
}
@end
