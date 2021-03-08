//
//  ESPProvisioningParams.h
//  EspTouchDemo
//
//  Created by AE on 2020/2/24.
//  Copyright © 2020 Espressif. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ESPProvisioningParams : NSObject

@property(strong, nonatomic) NSData * ssid;
@property(strong, nonatomic) NSData * bssid;
@property(strong, nonatomic) NSData * password;
@property(strong, nonatomic) NSData * reservedData;
@property(strong, nonatomic) NSString * aesKey;
@property(assign, nonatomic) int appPortMark;

- (instancetype)initWithSsid:(NSData *)ssid bssid:(NSData *)bssid password:(NSData *)password reservedData:(NSData *)reservedData aesKey:(NSString *)key appPortMark:(int)mark;

- (NSArray<NSData *> *)getDataPackets;

@end

NS_ASSUME_NONNULL_END
