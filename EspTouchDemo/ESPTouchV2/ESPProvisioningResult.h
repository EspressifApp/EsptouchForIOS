//
//  ESPProvisioningResult.h
//  EspTouchDemo
//
//  Created by AE on 2020/2/26.
//  Copyright © 2020 Espressif. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ESPProvisioningResult : NSObject

@property(strong, nonatomic, readonly) NSString *address;
@property(strong, nonatomic, readonly) NSString *bssid;

-(instancetype)initWithAddress:(NSString *)address bssid:(NSString *)bssid;

@end

NS_ASSUME_NONNULL_END
