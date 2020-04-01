//
//  ESP_WifiUtil.h
//  EspTouchDemo
//
//  Created by fby on 6/15/16.
//  Copyright © 2016 fby. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ESP_WifiUtil : NSObject

// refer to http://stackoverflow.com/questions/7072989/iphone-ipad-osx-how-to-get-my-ip-address-programmatically
+ (NSString *)getIPAddress:(BOOL)preferIPv4;

// refer to http://stackoverflow.com/questions/7072989/iphone-ipad-osx-how-to-get-my-ip-address-programmatically
+ (NSDictionary *)getIPAddresses;

/**
 * get local ip address by IPv4
 *
 * @return local ip address by IPv4(or nil when en0/ipv4 unaccessible)
 */
+ (NSString *)getIPAddress4;

/**
 * get local ip address by IPv6
 *
 * @return local ip address by IPv6(or nil when en0/ipv6 unaccessible)
 */
+ (NSString *)getIpAddress6;

@end
