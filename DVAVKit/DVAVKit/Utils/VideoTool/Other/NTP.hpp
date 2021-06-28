//
//  NTP.hpp
//  DVAVKit
//
//  Created by 胡勤超 on 2021/6/22.
//  Copyright © 2021 MyKit. All rights reserved.
//

#ifndef NTP_hpp
#define NTP_hpp

#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/ioctl.h>
#include <sys/socket.h>
#include <sys/wait.h>
#include <sys/time.h>
#include <netdb.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include <pthread.h>
#include <dirent.h>
#include <time.h>
#include <fcntl.h>
#include <errno.h>

int getNtpTime(struct hostent* phost,struct timeval *ptimeval);
    


#endif /* NTP_hpp */
