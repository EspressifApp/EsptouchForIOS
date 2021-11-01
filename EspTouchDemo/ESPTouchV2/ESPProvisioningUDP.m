//
//  ESPSendDeviceUDP.m
//  EspTouchDemo
//
//  Created by fanbaoying on 2019/12/10.
//  Copyright © 2019 Espressif. All rights reserved.
//

#import "ESPProvisioningUDP.h"
#import "ESPTools.h"
#import "ESPProvisioningResult.h"
#import "ESPProvisioningParams.h"
#import "ESPPacketUtils.h"
#import "ESP_NetUtil.h"

#define SYNC_INTERVAL 0.1
#define PROVISION_INTERVAL 0.015
#define PROVISION_INTERVAL2 0.1
#define PROVISION_TIMEOUT 90.0

@interface ESPProvisioningUDP()<GCDAsyncUdpSocketDelegate>

@property(strong, nonatomic)GCDAsyncUdpSocket *syncSocket;
@property(strong, nonatomic)NSCondition *syncCondition;
@property(strong, nonatomic)NSData *syncData;

@property(strong, nonatomic)GCDAsyncUdpSocket *provisionSocket;
@property(strong, nonatomic)NSCondition *provisionCondition;

@property(strong, nonatomic)NSData *apSsid;
@property(strong, nonatomic)NSData *apBssid;
@property(strong, nonatomic)NSData *apPwd;

@property(strong, nonatomic)NSMutableSet *responseMacs;
@property(strong, nonatomic)NSOperationQueue *cbQueue;
@property(strong, nonatomic)NSLock *cbLock;

@property(strong, nonatomic)ESPProvisionResultCB provisionResultCB;
@property(strong, nonatomic)ESPProvisionErrorCB provisionErrorCB;

@end

static const long TAG_SYNC = 1;
static const long TAG_PROVISION = 2;
static const long TAG_ACK = 3;

@implementation ESPProvisioningUDP
//单例模式
+ (instancetype)share {
    static ESPProvisioningUDP *share = nil;
    static dispatch_once_t oneToken;
    dispatch_once(&oneToken, ^{
        share = [[ESPProvisioningUDP alloc] init];
    });
    return share;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _syncSocket = nil;
        _syncCondition = [[NSCondition alloc] init];
        _syncData = [ESPPacketUtils getSyncPacket];
        NSLog(@"SYNC Len = %lu", (unsigned long)_syncData.length);
        
        _provisionSocket = nil;
        _provisionCondition = [[NSCondition alloc] init];
        
        _cbQueue = [[NSOperationQueue alloc] init];
        _responseMacs = [[NSMutableSet alloc] init];
        _cbLock = [[NSLock alloc] init];
    }
    return self;
}

- (BOOL)isSyncing {
    return _syncSocket != nil;
}

- (BOOL)isProvisioning {
    return _provisionSocket != nil;
}

- (GCDAsyncUdpSocket *)createUDPSocket {
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    GCDAsyncUdpSocket *socket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:queue];
    NSError *error = nil;
    [socket enableReusePort:YES error:&error];
    if (error) {
        NSLog(@"ESPSendDeviceUDP enableReusePort error:\n %@", error);
    }
    error = nil;
    [socket enableBroadcast:true error:&error];
    if (error) {
        NSLog(@"ESPSendDeviceUDP enableBroadcast error:\n %@", error);
    }
    
    return socket;
}

- (void)udpSocketDidClose:(GCDAsyncUdpSocket *)sock withError:(NSError *)error {
    if (error) {
        NSLog(@">>>>>> udpSocketDidClose error: \n%@", error);
    }
    if (sock == _syncSocket) {
        NSLog(@"SyncSock closed");
        _syncSocket = nil;
        [_syncCondition lock];
        [_syncCondition signal];
        [_syncCondition unlock];
    } else if (sock == _provisionSocket) {
        NSLog(@"ProvisionSocket closed");
        _provisionSocket = nil;
        [_provisionCondition lock];
        [_provisionCondition signal];
        [_provisionCondition unlock];
    }
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didSendDataWithTag:(long)tag {
    if (tag == TAG_SYNC) {
        [_syncCondition lock];
        [_syncCondition signal];
        [_syncCondition unlock];
    } else if (tag == TAG_PROVISION) {
        [_provisionCondition lock];
        [_provisionCondition signal];
        [_provisionCondition unlock];
    } else if (tag == TAG_ACK) {
        [sock close];
    }
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didNotSendDataWithTag:(long)tag dueToError:(NSError *)error {
    NSLog(@"UDP发送信息失败：tag=%ld\n%@", tag, error);
    if (tag == TAG_SYNC) {
        [_syncCondition lock];
        [_syncCondition signal];
        [_syncCondition unlock];
    } else if (tag == TAG_PROVISION) {
        [_provisionCondition lock];
        [_provisionCondition signal];
        [_provisionCondition unlock];
    } else if (tag == TAG_ACK) {
        [sock close];
    }
}

-(void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data fromAddress:(NSData *)address withFilterContext:(id)filterContex {
    NSLog(@"Receive UDP Address:%@, | data: %@", address, data);
    if (data.length < 7) {
        NSLog(@"Invalid EspTouch response, Address=%@ , Data=%@", address, data);
        return;
    }
    
    // Send Ack
    [_cbQueue addOperationWithBlock:^{
        for (int i = 0; i < 2; ++i) {
            GCDAsyncUdpSocket *udpSocket = [self createUDPSocket];
            Byte bytes[1];
            bytes[0] = 1;
            NSData *data = [[NSData alloc] initWithBytes:bytes length:1];
            [udpSocket sendData:data toAddress:address withTimeout:0.1 tag:TAG_ACK];
        }
    }];
    
    
    //取得发送发的ip和端口
    if (_provisionResultCB) {
        ESPProvisionResultCB resultCB = _provisionResultCB;
        Byte *buf = (Byte *)data.bytes;
        NSString *bssid = [NSString stringWithFormat:@"%x:%x:%x:%x:%x:%x", buf[1], buf[2], buf[3], buf[4], buf[5], buf[6]];
        [_cbLock lock];
        if (![_responseMacs containsObject:bssid]) {
            [_responseMacs addObject:bssid];
            
            [_cbQueue addOperationWithBlock:^{
                NSString *hostAddr = [GCDAsyncUdpSocket hostFromAddress:address];
                ESPProvisioningResult *result = [[ESPProvisioningResult alloc] initWithAddress:hostAddr bssid:bssid];
                resultCB(result);
            }];
        }
        [_cbLock unlock];
    }
}

- (void)startSyncOnStart:(ESPSyncStartCB)startCB onStop:(ESPSyncStopCB)stopCB onError:(ESPSyncErrorCB)errorCB {
    NSLog(@"startSendSync");
    @synchronized (self) {
        if (_syncSocket) {
            NSLog(@"Sync task has run");
            if (errorCB) {
                errorCB([[NSException alloc] initWithName:@"EspIllegalException" reason:@"Sync task is running" userInfo:nil]);
            }
            return;
        }
        _syncSocket = [self createUDPSocket];
    }
    
    NSLog(@"DeviceSync >>> Start");
    if (startCB) {
        [_cbQueue addOperationWithBlock:^{
            startCB();
        }];
    }
    while (YES) {
        if (!_syncSocket || _syncSocket.isClosed) {
            break;
        }
        
        [_syncCondition lock];
        NSString *localInetAddr4 = [ESP_NetUtil getLocalIPv4];
        NSArray *arr = [localInetAddr4 componentsSeparatedByString:@"."];
        NSString *deviceAddress4 = [NSString stringWithFormat:@"%@.%@.%@.255",arr[0], arr[1], arr[2]];
        NSString *address = _syncSocket.isIPv4 ? deviceAddress4 : DEVICE_ADDRESS6;
        [_syncSocket sendData:_syncData toHost:address port:DEVICE_PORT withTimeout:-1 tag:TAG_SYNC];
        [_syncCondition wait];
        [_syncCondition unlock];
        if (!_syncSocket || _syncSocket.isClosed) {
            break;
        }
        [NSThread sleepForTimeInterval:PROVISION_INTERVAL];
    }
    if (_syncSocket  && !_syncSocket.isClosed) {
        [_syncSocket close];
    }
    if (stopCB) {
        [_cbQueue addOperationWithBlock:^{
            stopCB();
        }];
    }
    NSLog(@"DeviceSync >>> End");
}

- (void)stopSync {
    NSLog(@"stopSendSync");
    @synchronized (self) {
        if (_syncSocket) {
            [_syncSocket close];
        }
    }
}

- (void)startProvision:(ESPProvisioningRequest  * _Nonnull)request onStart:(ESPProvisionStartCB _Nullable)startCB onStop:(ESPProvisionStopCB _Nullable)stopCB onResult:(ESPProvisionResultCB _Nullable)resultCB onError:(ESPProvisionErrorCB _Nullable)errorCB {
    NSLog(@"DeviceProvision >>> Start");
    int portMark = -1;
    @synchronized (self) {
        if (_syncSocket) {
            NSLog(@"Sync task is running");
            return;
        }
        if (_provisionSocket) {
            NSLog(@"Provision task is running");
            return;
        }
        
        GCDAsyncUdpSocket *socket = [self createUDPSocket];
        BOOL bound = NO;
        for (int i = 0; i < APP_POSTS_COUNT; ++i) {
            NSError *error = nil;
            int port = APP_PORTS[i];
            bound = [socket bindToPort:port error:&error];
            NSLog(@"DeviceProvision >>> Bind APP_PORT %d %@", port, bound ? @"YES" : @"NO");
            if (bound && !error) {
                portMark = i;
                break;
            }
            if (error) {
                NSLog(@"DeviceProvision bindToPort %d error:\n%@", port, error);
            }
        }
        if (!bound) {
            [socket close];
            if (errorCB) {
                [_cbQueue addOperationWithBlock:^{
                    errorCB([[NSException alloc] initWithName:@"EspSocketException" reason:@"BindToPort error" userInfo:nil]);
                }];
            }
            return;
        }
        _provisionSocket = socket;
    }
    
    NSError *error = nil;
    BOOL receiveSuc = [_provisionSocket beginReceiving:&error];
    NSLog(@"DeviceProvision >>> BeginReceiving %@", receiveSuc ? @"YES" : @"NO");
    if (!receiveSuc && error) {
        [_provisionSocket close];
        if (errorCB) {
            [_cbQueue addOperationWithBlock:^{
                errorCB([[NSException alloc] initWithName:@"EspSocketException" reason:@"BeginReceiving error" userInfo:nil]);
            }];
        }
        return;
    }
    
    @synchronized (_responseMacs) {
        [_responseMacs removeAllObjects];
    }
    
    _provisionResultCB = resultCB;
    _provisionErrorCB = errorCB;
    
    ESPProvisioningParams *params = [[ESPProvisioningParams alloc] initWithSsid:request.ssid bssid:request.bssid password:request.password reservedData:request.reservedData aesKey:request.aesKey appPortMark:portMark];
    NSArray *sendDataArr = [params getDataPackets];
    
    if (startCB) {
        [_cbQueue addOperationWithBlock:^{
            startCB();
        }];
    }
    NSLog(@"DeviceProvision >>> Sending Data");
    [NSThread sleepForTimeInterval:0.3];
    const NSTimeInterval start = [NSDate date].timeIntervalSince1970;
    NSTimeInterval interval = PROVISION_INTERVAL;
    while ([[NSDate date] timeIntervalSince1970] - start < PROVISION_TIMEOUT) {
        for (NSData *data in sendDataArr) {
            if (!_provisionSocket || _provisionSocket.isClosed) {
                goto SendEnd;
            }
            [_provisionCondition lock];
            NSString *localInetAddr4 = [ESP_NetUtil getLocalIPv4];
            NSArray *arr = [localInetAddr4 componentsSeparatedByString:@"."];
            NSString *deviceAddress4 = [NSString stringWithFormat:@"%@.%@.%@.255",arr[0], arr[1], arr[2]];
            NSString *address = _provisionSocket.isIPv4 ? deviceAddress4 : DEVICE_ADDRESS6;
            [_provisionSocket sendData:data toHost:address port:DEVICE_PORT withTimeout:-1 tag:TAG_PROVISION];
            [_provisionCondition wait];
            [_provisionCondition unlock];
            if (!_provisionSocket || _provisionSocket.isClosed) {
                goto SendEnd;
            }
            
            [NSThread sleepForTimeInterval:interval];
        }
        
        NSTimeInterval cost = [[NSDate date] timeIntervalSince1970] - start;
        if (cost > PROVISION_TIMEOUT) {
            break;
        } else if (cost > PROVISION_TIMEOUT / 2) {
            interval = PROVISION_INTERVAL2;
        }
        [NSThread sleepForTimeInterval:interval];
    }
    SendEnd:
    if (_provisionSocket && !_provisionSocket.isClosed) {
        [_provisionSocket pauseReceiving];
        [_provisionSocket close];
    }
    if (stopCB) {
        [_cbQueue addOperationWithBlock:^{
            stopCB();
        }];
    }
    _provisionResultCB = nil;
    _provisionErrorCB = nil;
    NSLog(@"DeviceProvision >>> End");
}

- (void)stopProvision {
    @synchronized (self) {
        if (_provisionSocket) {
            [_provisionSocket pauseReceiving];
            [_provisionSocket close];
        }
        @synchronized (_responseMacs) {
            [_responseMacs removeAllObjects];
        }
    }
}

@end
