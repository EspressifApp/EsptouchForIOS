//
//  ESPProvisioningRequest.h
//  EspTouchDemo
//
//  Created by fanbaoying on 2020/1/8.
//  Copyright © 2020 Espressif. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#define SECURITY_V1 1
#define SECURITY_V2 2

@interface ESPProvisioningRequest : NSObject

@property(strong, nonatomic) NSData * ssid;
@property(strong, nonatomic) NSData * bssid;
@property(strong, nonatomic) NSData * password;
@property(strong, nonatomic) NSString * deviceCount;
@property(strong, nonatomic) NSData * reservedData;
@property(strong, nonatomic) NSString * aesKey;
@property(assign, nonatomic) int securityVer;

@end

NS_ASSUME_NONNULL_END
