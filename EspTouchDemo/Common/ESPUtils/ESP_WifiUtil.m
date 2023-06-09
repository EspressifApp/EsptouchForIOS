//
//  ESP_WifiUtil.m
//  EspTouchDemo
//
//  Created by fby on 6/15/16.
//  Copyright © 2016 fby. All rights reserved.
//

#import "ESP_WifiUtil.h"

#include <ifaddrs.h>
#include <arpa/inet.h>
#include <net/if.h>

#define IOS_CELLULAR    @"pdp_ip0"
#define IOS_WIFI        @"en0"
#define IOS_VPN         @"utun0"
#define IP_ADDR_IPv4    @"ipv4"
#define IP_NETMASK_IPv4 @"netmask_ipv4"
#define IP_ADDR_IPv6    @"ipv6"

@implementation ESP_WifiUtil

+ (NSString *)getIPAddress:(BOOL)preferIPv4
{
    NSArray *searchArray = preferIPv4 ?
    @[ IOS_VPN @"/" IP_ADDR_IPv4, IOS_VPN @"/" IP_ADDR_IPv6, IOS_WIFI @"/" IP_ADDR_IPv4, IOS_WIFI @"/" IP_ADDR_IPv6, IOS_CELLULAR @"/" IP_ADDR_IPv4, IOS_CELLULAR @"/" IP_ADDR_IPv6 ] :
    @[ IOS_VPN @"/" IP_ADDR_IPv6, IOS_VPN @"/" IP_ADDR_IPv4, IOS_WIFI @"/" IP_ADDR_IPv6, IOS_WIFI @"/" IP_ADDR_IPv4, IOS_CELLULAR @"/" IP_ADDR_IPv6, IOS_CELLULAR @"/" IP_ADDR_IPv4 ] ;
    
    NSDictionary *addresses = [self getIPAddresses];
//    NSLog(@"addresses: %@", addresses);
    
    __block NSString *address;
    [searchArray enumerateObjectsUsingBlock:^(NSString *key, NSUInteger idx, BOOL *stop)
     {
         address = addresses[key];
         if(address) *stop = YES;
     } ];
    return address ? address : @"0.0.0.0";
}

+ (NSDictionary *)getIPAddresses
{
    NSMutableDictionary *addresses = [NSMutableDictionary dictionaryWithCapacity:8];
    
    // retrieve the current interfaces - returns 0 on success
    struct ifaddrs *interfaces;
    if(!getifaddrs(&interfaces)) {
        // Loop through linked list of interfaces
        struct ifaddrs *interface;
        for(interface=interfaces; interface; interface=interface->ifa_next) {
            if(!(interface->ifa_flags & IFF_UP) /* || (interface->ifa_flags & IFF_LOOPBACK) */ ) {
                continue; // deeply nested code harder to read
            }
            struct sockaddr_in *addr = (struct sockaddr_in *)interface->ifa_addr;
            char addrBuf[ MAX(INET_ADDRSTRLEN, INET6_ADDRSTRLEN) ];
            if(addr && (addr->sin_family==AF_INET || addr->sin_family==AF_INET6)) {
                NSString *name = [NSString stringWithUTF8String:interface->ifa_name];
                if(addr->sin_family == AF_INET) {
                    if(inet_ntop(AF_INET, &addr->sin_addr, addrBuf, INET_ADDRSTRLEN)) {
                        NSString *key = [NSString stringWithFormat:@"%@/%@", name, IP_ADDR_IPv4];
                        addresses[key] = [NSString stringWithUTF8String:addrBuf];
                    }
                    addr = (struct sockaddr_in *)interface->ifa_netmask;
                    if(addr->sin_family == AF_INET) {
                        if(inet_ntop(AF_INET, &addr->sin_addr, addrBuf, INET_ADDRSTRLEN)) {
                            NSString *key = [NSString stringWithFormat:@"%@/%@", name, IP_NETMASK_IPv4];
                            addresses[key] = [NSString stringWithUTF8String:addrBuf];
                        }
                    }
                } else {
                    const struct sockaddr_in6 *addr6 = (const struct sockaddr_in6*)interface->ifa_addr;
                    if(inet_ntop(AF_INET6, &addr6->sin6_addr, addrBuf, INET6_ADDRSTRLEN)) {
                        NSString *key = [NSString stringWithFormat:@"%@/%@", name, IP_ADDR_IPv6];
                        addresses[key] = [NSString stringWithUTF8String:addrBuf];
                    }
                }
            }
        }
        // Free memory
        freeifaddrs(interfaces);
    }
    return [addresses count] ? addresses : nil;
}

+ (NSString *)getIPAddress4
{
    NSString *key = [NSString stringWithFormat:@"%@/%@",IOS_WIFI,IP_ADDR_IPv4];
    NSString *ipv4 = [[self getIPAddresses]objectForKey:key];
    return ipv4;
}

+ (NSString *)getIPSubNetmask4
{
    NSString *key = [NSString stringWithFormat:@"%@/%@", IOS_WIFI, IP_NETMASK_IPv4];
    NSString *netmask = [[self getIPAddresses]objectForKey:key];
    return netmask;
}

+ (NSString *)getIpAddress6
{
    NSString *key = [NSString stringWithFormat:@"%@/%@",IOS_WIFI,IP_ADDR_IPv6];
    NSString *ipv6 = [[self getIPAddresses]objectForKey:key];
    return ipv6;
}

@end
