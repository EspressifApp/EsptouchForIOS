//
//  ESPNetUtil.h
//  EspTouchDemo
//
//  Created by fby on 5/15/15.
//  Copyright (c) 2015 fby. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ESP_NetUtil : NSObject

/**
 * get local ip v4 or nil
 *
 * @return local ip v4 or nil
 */
+ (NSString *) getLocalIPv4;

/**
 * get local ip v6 or nil
 *
 * @return local ip v6 or nil
 */
+ (NSString *) getLocalIPv6;

/**
 * whether the ipAddr is v4
 *
 * @return whether the ipAddr is v4
 */
+ (BOOL) isIPv4Addr:(NSString *)ipAddr;

/**
 * whether the ipAddr v4 is private
 *
 * @return whether the ipAddr v4 is private
 */
+ (BOOL) isIPv4PrivateAddr:(NSString *)ipAddr;

/**
 * get the local ip address by local inetAddress ip4
 *
 * @param localInetAddr4 local inetAddress ip4
 */
+ (NSData *) getLocalInetAddress4ByAddr:(NSString *) localInetAddr4;

/**
 * get the invented local ip address by local port
 *
 */
+ (NSData *) getLocalInetAddress6ByPort:(int) localPort;

/**
 * parse InetAddress
 */
+ (NSData *) parseInetAddrByData: (NSData *) inetAddrData andOffset: (int) offset andCount: (int) count;

/**
 * descrpion inetAddrData for print pretty IPv4
 */
+ (NSString *) descriptionInetAddr4ByData: (NSData *) inetAddrData;

/**
 * descrpion inetAddrData for print pretty IPv6
 */
+ (NSString *) descriptionInetAddr6ByData: (NSData *) inetAddrData;

/**
 * parse bssid
 *
 * @param bssid the bssid
 * @return byte converted from bssid
 */
+ (NSData *) parseBssid2bytes: (NSString *) bssid;

/**
 * send a dummy GET to "https://8.8.8.8" just to get Network Permission after ios10.0(including)
 */
+ (void) tryOpenNetworkPermission;

@end
