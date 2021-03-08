//
//  ESPProvisioningResult.m
//  EspTouchDemo
//
//  Created by AE on 2020/2/26.
//  Copyright © 2020 Espressif. All rights reserved.
//

#import "ESPProvisioningResult.h"

@implementation ESPProvisioningResult

- (instancetype)initWithAddress:(NSString *)address bssid:(NSString *)bssid {
    self = [super init];
    if (self) {
        _address = address;
        _bssid = bssid;
    }
    return self;
}

@end
