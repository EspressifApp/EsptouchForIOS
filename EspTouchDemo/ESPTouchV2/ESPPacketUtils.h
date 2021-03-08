//
//  ESPPacketUtils.h
//  EspTouchDemo
//
//  Created by AE on 2020/4/13.
//  Copyright © 2020 Espressif. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ESPPacketUtils : NSObject

+ (NSData *)getSyncPacket;

+ (NSData *)getSequenceSizePacket:(NSInteger)size;

+ (NSData *)getSequencePacket:(NSInteger)sequence;

+ (NSData *)getDataPacket:(NSInteger)data index:(NSInteger)index;

@end

NS_ASSUME_NONNULL_END
