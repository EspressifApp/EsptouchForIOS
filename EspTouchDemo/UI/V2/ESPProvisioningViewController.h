//
//  ESPProvisioningViewController.h
//  EspTouchDemo
//
//  Created by AE on 2020/3/2.
//  Copyright © 2020 Espressif. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ESPProvisioningRequest.h"

NS_ASSUME_NONNULL_BEGIN

@interface ESPProvisioningViewController : UIViewController

- (instancetype)initWithProvisionRequest:(ESPProvisioningRequest *)request;

@end

NS_ASSUME_NONNULL_END
