//
//  ESPNetUtil.m
//  EspTouchDemo
//
//  Created by 白 桦 on 5/15/15.
//  Copyright (c) 2015 白 桦. All rights reserved.
//

#import "ESP_NetUtil.h"
#import "ESP_WifiUtil.h"
#import "ESP_ByteUtil.h"
#import "ESPVersionMacro.h"

#define IP4_LEN 4

#define IP6_LEN 16

@implementation ESP_NetUtil

/**
 * get local ip v4 or nil
 *
 * @return local ip v4 or nil
 */
+ (NSString *) getLocalIPv4
{
    return [ESP_WifiUtil getIPAddress4];
}

/**
 * get local ip v6 or nil
 *
 * @return local ip v6 or nil
 */
+ (NSString *) getLocalIPv6
{
    return [ESP_WifiUtil getIpAddress6];
}

+ (BOOL) isIPv4Addr:(NSString *)ipAddr
{
    NSArray *ip4array = [ipAddr componentsSeparatedByString:@"."];
    return [ip4array count]==4;
}

+ (BOOL) isIPv4PrivateAddr:(NSString *)ipAddr4
{
    NSArray *ip4array = [ipAddr4 componentsSeparatedByString:@"."];
    Byte byte0 = [[ip4array objectAtIndex:0]intValue];
    Byte byte1 = [[ip4array objectAtIndex:1]intValue];
//    Byte byte2 = [[ip4array objectAtIndex:2]intValue];
//    Byte byte3 = [[ip4array objectAtIndex:3]intValue];
    
    if (byte0==10) {
        //    10.0.0.0~10.255.255.255
        return YES;
    } else if (byte0==172&&16<=byte1&&byte1<=31) {
        //    172.16.0.0~172.31.255.255
        return YES;
    } else if (byte0==192&&byte1==168) {
        //    192.168.0.0~192.168.255.255
        return YES;
    }
    return NO;
}

+ (NSData *) getLocalInetAddress4ByAddr:(NSString *) localInetAddr4
{
    NSArray *ip4array = [localInetAddr4 componentsSeparatedByString:@"."];
    Byte byte0 = [[ip4array objectAtIndex:0]intValue];
    Byte byte1 = [[ip4array objectAtIndex:1]intValue];
    Byte byte2 = [[ip4array objectAtIndex:2]intValue];
    Byte byte3 = [[ip4array objectAtIndex:3]intValue];
    Byte bytes[] = {byte0,byte1,byte2,byte3};
    NSData *ip4data = [NSData dataWithBytes:bytes length:IP4_LEN];
    return ip4data;
}

+ (NSData *) getLocalInetAddress6ByPort:(int) localPort
{
    Byte lowPort = localPort & 0xff;
    Byte highPort = (localPort>>8) & 0xff;
    Byte bytes[] = {highPort,lowPort,0xff,0xff};
    NSData *ip6data = [NSData dataWithBytes:bytes length:IP4_LEN];
    return ip6data;
}

+ (NSData *) parseInetAddrByData: (NSData *) inetAddrData andOffset: (int) offset andCount: (int) count
{
    return [inetAddrData subdataWithRange:NSMakeRange(offset, count)];
}

+ (NSString *) descriptionInetAddr4ByData: (NSData *) inetAddrData
{
    // check whether inetAddrData is belong to IPv4
    if ([inetAddrData length]!=IP4_LEN) {
        return nil;
    }
    Byte inetAddrBytes[IP4_LEN];
    [inetAddrData getBytes:inetAddrBytes length:IP4_LEN];
    // hard coding
    return [NSString stringWithFormat:@"%d.%d.%d.%d",inetAddrBytes[0],inetAddrBytes[1],inetAddrBytes[2],inetAddrBytes[3]];
}
+ (NSString *) descriptionInetAddr6ByData: (NSData *) inetAddrData
{
    // check whether inetAddrData is belong to IPv4
    if ([inetAddrData length]!=IP6_LEN) {
        return nil;
    }
    Byte inetAddrBytes[IP6_LEN];
    [inetAddrData getBytes:inetAddrBytes length:IP6_LEN];
    // hard coding
    return [NSString stringWithFormat:@"%02x%02x:%02x%02x:%02x%02x:%02x%02x:%02x%02x:%02x%02x:%02x%02x:%02x%02x",inetAddrBytes[0],inetAddrBytes[1],inetAddrBytes[2],inetAddrBytes[3],inetAddrBytes[4],inetAddrBytes[5],inetAddrBytes[6],inetAddrBytes[7],inetAddrBytes[8],inetAddrBytes[9],inetAddrBytes[10],inetAddrBytes[11],inetAddrBytes[12],inetAddrBytes[13],inetAddrBytes[14],inetAddrBytes[15]];
}

+ (NSData *) parseBssid2bytes: (NSString *) bssid
{
    NSArray *bssidArray = [bssid componentsSeparatedByString:@":"];
    NSInteger size = [bssidArray count];
    Byte bssidBytes[size];
    for (NSInteger i = 0; i < size; i++) {
        NSString *bssidStr = [bssidArray objectAtIndex:i];
        bssidBytes[i] = strtoul([bssidStr UTF8String], 0, 16);
    }
    return [[NSData alloc]initWithBytes:bssidBytes length:size];
}

+ (NSURLSessionConfiguration *) DEFAULT_SESSION_CONFIGURATION
{
    static dispatch_once_t predicate;
    static NSURLSessionConfiguration *DEFAULT_SESSION_CONFIGURATION;
    dispatch_once(&predicate, ^{
        DEFAULT_SESSION_CONFIGURATION = [NSURLSessionConfiguration defaultSessionConfiguration];
    });
    return DEFAULT_SESSION_CONFIGURATION;
}


+ (void) tryOpenNetworkPermission
{
    // only ios 10.0 later required to try open network permission
    if(SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"10.0")) {
        NSURL *url = [NSURL URLWithString:@"https://8.8.8.8"];
        NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:1000];
        
        
        NSURLSession *urlSession = [NSURLSession sessionWithConfiguration:[self DEFAULT_SESSION_CONFIGURATION] delegate:nil delegateQueue:[NSOperationQueue currentQueue]];
        [[urlSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error){
        }] resume];
    }
}

@end
