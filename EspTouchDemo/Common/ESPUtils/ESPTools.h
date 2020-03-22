//
//  EspNetUtils.h
//  Esp32Mesh
//
//  Created by AE on 2018/4/19.
//  Copyright © 2018年 AE. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@interface ESPTools : NSObject

+ (nullable NSString *)getCurrentWiFiSsid;
+ (nullable NSString *)getCurrentBSSID;

+ (NSString *)getIPAddress:(BOOL)preferIPv4;

+ (NSDictionary *)getIPAddresses;
NS_ASSUME_NONNULL_END
@end

