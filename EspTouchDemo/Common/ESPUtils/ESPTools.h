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

// iOS 26 起 CNCopyCurrentNetworkInfo 已被废弃（总是返回 nil），
// 统一改用 NEHotspotNetwork fetchCurrent（iOS 13+），低版本自动回退到旧 API。
// 回调可能不在主线程，刷新 UI 前请先切回主线程。
+ (void)fetchCurrentWiFiInfoWithCompletion:(void (^)(NSString * _Nullable ssid, NSString * _Nullable bssid))completion;

+ (NSString *)getIPAddress:(BOOL)preferIPv4;

+ (NSDictionary *)getIPAddresses;
NS_ASSUME_NONNULL_END
@end

