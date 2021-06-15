//
//  SEIPacket.hpp
//  DVAVKit
//
//  Created by 胡勤超 on 2021/6/10.
//  Copyright © 2021 MyKit. All rights reserved.
//

#ifndef SEIPacket_hpp
#define SEIPacket_hpp

#include <stdint.h>


uint32_t reversebytes(uint32_t value);
 
uint32_t get_sei_packet_size(uint32_t size);
 
int fill_sei_packet(unsigned char * packet, bool isAnnexb, const char * content, uint32_t size);
 
int get_sei_content(unsigned char * packet, uint32_t size, char * buffer, int *count);


#endif /* SEIPacket_hpp */
&
