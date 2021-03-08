//
//  ESPPacketUtils.m
//  EspTouchDemo
//
//  Created by AE on 2020/4/13.
//  Copyright © 2020 Espressif. All rights reserved.
//

#import "ESPPacketUtils.h"

@implementation ESPPacketUtils

+ (NSData *)getSyncPacket {
    const NSInteger length = 1048;
    Byte buf[length] = {};
    return [NSData dataWithBytes:buf length:length];
}

+ (NSData *)getSequenceSizePacket:(NSInteger)size {
    const NSInteger length = 1072 + size - 1;
    return [NSMutableData dataWithLength:length];
}

+ (NSData *)getSequencePacket:(NSInteger)sequence {
    const NSInteger length = 128 + sequence;
    return [NSMutableData dataWithLength:length];
}

+ (NSData *)getDataPacket:(NSInteger)data index:(NSInteger)index {
    const NSInteger length = (index << 7) | (1 << 6) | data;
    return [NSMutableData dataWithLength:length];
}

@end
