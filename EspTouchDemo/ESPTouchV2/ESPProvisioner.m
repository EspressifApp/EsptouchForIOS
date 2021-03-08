//
//  ESPProvisioner.m
//  EspTouchDemo
//
//  Created by fanbaoying on 2019/12/10.
//  Copyright © 2019 Espressif. All rights reserved.
//

#import "ESPProvisioner.h"

@interface ESPProvisioner()
@end

@implementation ESPProvisioner

+ (instancetype)share {
    static ESPProvisioner *share = nil;
    static dispatch_once_t oneToken;
    dispatch_once(&oneToken, ^{
        share = [[ESPProvisioner alloc] init];
    });
    return share;
}

- (void)startSyncWithDelegate:(id<ESPProvisionerDelegate> _Nullable)delegate {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        ESPSyncStartCB startCB = delegate && [delegate respondsToSelector:@selector(onSyncStart)] ? ^{
            if (delegate) {
                [delegate onSyncStart];
            }
        } : nil;
        ESPSyncStopCB stopCB = delegate && [delegate respondsToSelector:@selector(onSyncStop)] ? ^{
            if (delegate) {
                [delegate onSyncStop];
            }
        } : nil;
        ESPSyncErrorCB errorCB = delegate && [delegate respondsToSelector:@selector(onSyncError:)] ? ^(NSException * _Nonnull exception) {
            if (delegate) {
                [delegate onSyncError:exception];
            }
        } : nil;
        
        [[ESPProvisioningUDP share] startSyncOnStart:startCB onStop:stopCB onError:errorCB];
    });
}

- (void)stopSync {
    [[ESPProvisioningUDP share] stopSync];
}

- (BOOL)isSyncing {
    return [[ESPProvisioningUDP share] isSyncing];
}

- (void)startProvisioning:(ESPProvisioningRequest *)request withDelegate:(id<ESPProvisionerDelegate> _Nullable)delegate {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        ESPProvisionStartCB startCB = delegate && [delegate respondsToSelector:@selector(onProvisioningStart)] ? ^{
            // OnStart
            if (delegate) {
                [delegate onProvisioningStart];
            }
        } : nil;
        ESPProvisionStopCB stopCB = delegate && [delegate respondsToSelector:@selector(onProvisioningStop)] ? ^{
            // OnStop
            if (delegate) {
                [delegate onProvisioningStop];
            }
        } : nil;
        ESPProvisionResultCB resultCB = delegate && [delegate respondsToSelector:@selector(onProvisoningScanResult:)] ? ^(ESPProvisioningResult * _Nonnull result) {
            // onResult
            if (delegate) {
                [delegate onProvisoningScanResult:result];
            }
        } : nil;
        ESPProvisionErrorCB errorCB = delegate && [delegate respondsToSelector:@selector(onProvisioningError:)] ? ^(NSException * _Nonnull exception) {
            // onError
            if (delegate) {
                [delegate onProvisioningError:exception];
            }
        } : nil;
        
        [[ESPProvisioningUDP share] startProvision:request onStart:startCB onStop:stopCB onResult:resultCB onError: errorCB];
    });
}

- (void)stopProvisioning {
    [[ESPProvisioningUDP share] stopProvision];
}

- (BOOL)isProvisioning {
    return [[ESPProvisioningUDP share] isProvisioning];
}

@end
