//
//  ESPProvisioner.h
//  EspTouchDemo
//
//  Created by fanbaoying on 2019/12/10.
//  Copyright © 2019 Espressif. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ESPProvisioningUDP.h"
#import "ESPProvisioningResult.h"
#import "ESPProvisioningListeners.h"

#define ESPTOUCH_V2_VERSION    @"SDK-v2.1.0"

NS_ASSUME_NONNULL_BEGIN

@protocol ESPProvisionerDelegate <NSObject>

@optional

- (void)onSyncStart;

- (void)onSyncStop;

- (void)onSyncError:(NSException *)exception;

- (void)onProvisioningStart;

- (void)onProvisioningStop;

- (void)onProvisoningScanResult:(ESPProvisioningResult *)result;

- (void)onProvisioningError:(NSException *)exception;

@end


@interface ESPProvisioner : NSObject

/**
 * 单例构造方法
 * @return BabyBluetooth共享实例
 */
+ (instancetype)share;

// 开始发送 Sync 包
- (void)startSyncWithDelegate:(id<ESPProvisionerDelegate> _Nullable)delegate;

// 停止发送 Sync 包
- (void)stopSync;

- (BOOL)isSyncing;

// 开始发送配网信息
- (void)startProvisioning:(ESPProvisioningRequest *)request withDelegate:(id<ESPProvisionerDelegate> _Nullable)delegate;

// 停止发送配网信息
- (void)stopProvisioning;

- (BOOL)isProvisioning;
@end

NS_ASSUME_NONNULL_END
