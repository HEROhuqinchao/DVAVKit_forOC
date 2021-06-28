//
//  NTPManger.h
//  DVAVKit
//
//  Created by 胡勤超 on 2021/6/22.
//  Copyright © 2021 MyKit. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NTPManger : NSObject

+ (NSTimeInterval )GetNtpTimeForHost:(NSString *)host_OC;
@end

NS_ASSUME_NONNULL_END
