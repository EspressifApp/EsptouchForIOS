//
//  ESPProvisioningRequest.m
//  EspTouchDemo
//
//  Created by fanbaoying on 2020/1/8.
//  Copyright © 2020 Espressif. All rights reserved.
//

#import "ESPProvisioningRequest.h"
#import "ESP_NetUtil.h"
#import "ESP_CRC8.h"
#import "ESPProvisioningParams.h"
#import "ESPProvisioningUDP.h"

#define SECURITY_V1 1
#define SECURITY_V2 2

@interface ESPProvisioningRequest ()

@end

@implementation ESPProvisioningRequest

- (instancetype)init
{
    self = [super init];
    if (self) {
    }
    return self;
}

@end
