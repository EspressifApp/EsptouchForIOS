//
//  ESPSendDeviceUDP.h
//  EspTouchDemo
//
//  Created by fanbaoying on 2019/12/10.
//  Copyright © 2019 Espressif. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GCDAsyncUdpSocket.h"
#import "ESPProvisioningRequest.h"
#import "ESPProvisioningResult.h"
#import "ESPProvisioningListeners.h"
#import "ESPProvisioner.h"

NS_ASSUME_NONNULL_BEGIN

#define DEVICE_PORT 7001
#define DEVICE_ACK_PORT 7002
#define DEVICE_ADDRESS6 @"ff02::1%en0"
static const int APP_POSTS_COUNT = 4;
static const uint16_t APP_PORTS[] = {18266, 28266, 38266, 48266};


@interface ESPProvisioningUDP : NSObject

typedef void(^ESPSyncStartCB)(void);

typedef void(^ESPSyncStopCB)(void);

typedef void(^ESPSyncErrorCB)(NSException * _Nonnull exception);

typedef void(^ESPProvisionStartCB)(void);

typedef void(^ESPProvisionStopCB)(void);

typedef void(^ESPProvisionResultCB)(ESPProvisioningResult * _Nonnull result);

typedef void(^ESPProvisionErrorCB)(NSException * _Nonnull exception);

// 单例构造方法
+ (instancetype)share;

// 开始发送
- (void)startSyncOnStart:(ESPSyncStartCB)startCB onStop:(ESPSyncStopCB)stopCB onError:(ESPSyncErrorCB)errorCB ;

// 停止发送
- (void)stopSync;

- (BOOL)isSyncing;

- (void)startProvision:(ESPProvisioningRequest  * _Nonnull)request onStart:(ESPProvisionStartCB _Nullable)startCB onStop:(ESPProvisionStopCB _Nullable)stopCB onResult:(ESPProvisionResultCB _Nullable)resultCB onError:(ESPProvisionErrorCB _Nullable)errorCB;

- (void)stopProvision;

- (BOOL)isProvisioning;
@end

NS_ASSUME_NONNULL_END
