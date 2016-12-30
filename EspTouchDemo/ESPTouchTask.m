//
//  ESPTouchTask.m
//  EspTouchDemo
//
//  Created by 白 桦 on 4/14/15.
//  Copyright (c) 2015 白 桦. All rights reserved.
//

//  The usage of NSCondition refer to: https://gist.github.com/prachigauriar/8118909

#import "ESPTouchTask.h"
#import "ESP_ByteUtil.h"
#import "ESPTouchGenerator.h"
#import "ESPUDPSocketClient.h"
#import "ESPUDPSocketServer.h"
#import "ESP_NetUtil.h"
#import "ESPTouchTaskParameter.h"

#define ONE_DATA_LEN    3
#define ESPTOUCH_VERSION    @"v0.3.5.3"

@interface ESPTouchTask ()

@property (nonatomic,strong) NSString *_apSsid;

@property (nonatomic,strong) NSString *_apBssid;

@property (nonatomic,strong) NSString *_apPwd;

@property (atomic,assign) BOOL _isSuc;

@property (atomic,assign) BOOL _isInterrupt;

@property (nonatomic,strong) ESPUDPSocketClient *_client;

@property (nonatomic,strong) ESPUDPSocketServer *_server;

@property (atomic,strong) NSMutableArray *_esptouchResultArray;

@property (atomic,strong) NSCondition *_condition;

@property (nonatomic,assign) __block BOOL _isWakeUp;

@property (nonatomic,assign) volatile BOOL _isExecutedAlready;

@property (nonatomic,assign) BOOL _isSsidHidden;

@property (nonatomic,strong) ESPTaskParameter *_parameter;

@property (atomic,strong) NSMutableDictionary *_bssidTaskSucCountDict;

@property (atomic,strong) NSCondition *_esptouchResultArrayCondition;

@property (nonatomic,assign) __block UIBackgroundTaskIdentifier _backgroundTask;

@property (nonatomic,strong) id<ESPTouchDelegate> _esptouchDelegate;

@property (nonatomic,strong) NSData *_localInetAddrData;

@end

@implementation ESPTouchTask

- (id) initWithApSsid: (NSString *)apSsid andApBssid: (NSString *) apBssid andApPwd: (NSString *)apPwd
{
    NSLog(@"Welcome Esptouch %@",ESPTOUCH_VERSION);
    if (apSsid==nil||[apSsid isEqualToString:@""])
    {
        perror("ESPTouchTask initWithApSsid() apSsid shouldn't be null or empty");
    }
    // the apSsid should be null or empty
    assert(apSsid!=nil&&![apSsid isEqualToString:@""]);
    if (apPwd == nil)
    {
        apPwd = @"";
    }
    
    self = [super init];
    if (self)
    {
        if (DEBUG_ON)
        {
            NSLog(@"ESPTouchTask init");
        }
        self._apSsid = apSsid;
        self._apPwd = apPwd;
        self._apBssid = apBssid;
        self._parameter = [[ESPTaskParameter alloc]init];
        
        // check whether IPv4 and IPv6 is supported
        NSString *localInetAddr4 = [ESP_NetUtil getLocalIPv4];
        if (![ESP_NetUtil isIPv4PrivateAddr:localInetAddr4]) {
            localInetAddr4 = nil;
        }
        NSString *localInetAddr6 = [ESP_NetUtil getLocalIPv6];
        [self._parameter setIsIPv4Supported:localInetAddr4!=nil];
        [self._parameter setIsIPv6Supported:localInetAddr6!=nil];
        
        // create udp client and udp server
        self._client = [[ESPUDPSocketClient alloc]init];
        self._server = [[ESPUDPSocketServer alloc]initWithPort: [self._parameter getPortListening]
                                              AndSocketTimeout: [self._parameter getWaitUdpTotalMillisecond]];
        // update listening port for IPv6
        [self._parameter setListeningPort6:self._server.port];
        if (DEBUG_ON) {
            NSLog(@"ESPTouchTask app server port is %d",self._server.port);
        }
        
        if (localInetAddr4!=nil) {
            self._localInetAddrData = [ESP_NetUtil getLocalInetAddress4ByAddr:localInetAddr4];
        } else {
            int localPort = [self._parameter getPortListening];
            self._localInetAddrData = [ESP_NetUtil getLocalInetAddress6ByPort:localPort];
        }
        
        if (DEBUG_ON)
        {
            // for ESPTouchGenerator only receive 4 bytes for local address no matter IPv4 or IPv6
            NSLog(@"ESPTouchTask executeForResult() localInetAddr: %@", [ESP_NetUtil descriptionInetAddr4ByData:self._localInetAddrData]);
        }
        
        self._isSuc = NO;
        self._isInterrupt = NO;
        self._isWakeUp = NO;
        self._isExecutedAlready = NO;
        self._condition = [[NSCondition alloc]init];
        self._isSsidHidden = YES;
        self._esptouchResultArray = [[NSMutableArray alloc]init];
        self._bssidTaskSucCountDict = [[NSMutableDictionary alloc]init];
        self._esptouchResultArrayCondition = [[NSCondition alloc]init];
    }
    return self;
}

- (id) initWithApSsid: (NSString *)apSsid andApBssid: (NSString *) apBssid andApPwd: (NSString *)apPwd andIsSsidHiden: (BOOL) isSsidHidden
{
    return [self initWithApSsid:apSsid andApBssid:apBssid andApPwd:apPwd];
}

- (id) initWithApSsid: (NSString *)apSsid andApBssid: (NSString *) apBssid andApPwd: (NSString *)apPwd andTimeoutMillisecond: (int) timeoutMillisecond
{
    ESPTouchTask *_self = [self initWithApSsid:apSsid andApBssid:apBssid andApPwd:apPwd];
    if (_self)
    {
        [_self._parameter setWaitUdpTotalMillisecond:timeoutMillisecond];
    }
    return _self;
}

- (id) initWithApSsid: (NSString *)apSsid andApBssid: (NSString *) apBssid andApPwd: (NSString *)apPwd andIsSsidHiden: (BOOL) isSsidHidden andTimeoutMillisecond: (int) timeoutMillisecond
{
    return [self initWithApSsid:apSsid andApBssid:apBssid andApPwd:apPwd andTimeoutMillisecond:timeoutMillisecond];
}

- (void) __putEsptouchResultIsSuc: (BOOL) isSuc AndBssid: (NSString *)bssid AndInetAddr:(NSData *)inetAddr
{
    [self._esptouchResultArrayCondition lock];
    // check whether the result receive enough UDP response
    BOOL isTaskSucCountEnough = NO;
    NSNumber *countNumber = [self._bssidTaskSucCountDict objectForKey:bssid];
    int count = 0;
    if (countNumber != nil)
    {
        count = [countNumber intValue];
    }
    ++count;
    if (DEBUG_ON)
    {
        NSLog(@"ESPTouchTask __putEsptouchResult(): count = %d",count);
    }
    countNumber = [[NSNumber alloc]initWithInt:count];
    [self._bssidTaskSucCountDict setObject:countNumber forKey:bssid];
    isTaskSucCountEnough = count >= [self._parameter getThresholdSucBroadcastCount];
    if (!isTaskSucCountEnough)
    {
        if (DEBUG_ON)
        {
            NSLog(@"ESPTouchTask __putEsptouchResult(): count = %d, isn't enough", count);
        }
        [self._esptouchResultArrayCondition unlock];
        return;
    }
    // check whether the result is in the mEsptouchResultList already
    BOOL isExist = NO;
    for (id esptouchResultId in self._esptouchResultArray)
    {
        ESPTouchResult *esptouchResultInArray = esptouchResultId;
        if ([esptouchResultInArray.bssid isEqualToString:bssid])
        {
            isExist = YES;
            break;
        }
    }
    // only add the result who isn't in the mEsptouchResultList
    if (!isExist)
    {
        if (DEBUG_ON)
        {
            NSLog(@"ESPTouchTask __putEsptouchResult(): put one more result");
        }
        ESPTouchResult *esptouchResult = [[ESPTouchResult alloc]initWithIsSuc:isSuc andBssid:bssid andInetAddrData:inetAddr];
        [self._esptouchResultArray addObject:esptouchResult];
        if (self._esptouchDelegate != nil)
        {
            [self._esptouchDelegate onEsptouchResultAddedWithResult:esptouchResult];
        }
    }
    [self._esptouchResultArrayCondition unlock];
}

-(NSArray *) __getEsptouchResultList
{
    [self._esptouchResultArrayCondition lock];
    if ([self._esptouchResultArray count] == 0)
    {
        ESPTouchResult *esptouchResult = [[ESPTouchResult alloc]initWithIsSuc:NO andBssid:nil andInetAddrData:nil];
        esptouchResult.isCancelled = self.isCancelled;
        [self._esptouchResultArray addObject:esptouchResult];
    }
    [self._esptouchResultArrayCondition unlock];
    return self._esptouchResultArray;
}


- (void) beginBackgroundTask
{
    if (DEBUG_ON)
    {
        NSLog(@"ESPTouchTask beginBackgroundTask() entrance");
    }
    self._backgroundTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        if (DEBUG_ON)
        {
            NSLog(@"ESPTouchTask beginBackgroundTask() endBackgroundTask");
        }
        [self endBackgroundTask];
    }];
}

- (void) endBackgroundTask
{
    if (DEBUG_ON)
    {
        NSLog(@"ESPTouchTask endBackgroundTask() entrance");
    }
    [[UIApplication sharedApplication] endBackgroundTask: self._backgroundTask];
    self._backgroundTask = UIBackgroundTaskInvalid;
}

- (void) __listenAsyn: (const int) expectDataLen
{
    dispatch_queue_t  queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        [self beginBackgroundTask];
        if (DEBUG_ON)
        {
            NSLog(@"ESPTouchTask __listenAsyn() start an asyn listen task, current thread is: %@", [NSThread currentThread]);
        }
        NSTimeInterval startTimestamp = [[NSDate date] timeIntervalSince1970];
        NSString *apSsidAndPwd = [NSString stringWithFormat:@"%@%@",self._apSsid,self._apPwd];
        Byte expectOneByte = [ESP_ByteUtil getBytesByNSString:apSsidAndPwd].length + 9;
        if (DEBUG_ON)
        {
            NSLog(@"ESPTouchTask __listenAsyn() expectOneByte: %d",expectOneByte);
        }
        Byte receiveOneByte = -1;
        NSData *receiveData = nil;
        while ([self._esptouchResultArray count] < [self._parameter getExpectTaskResultCount] && !self._isInterrupt)
        {
            if ([self._parameter isIPv4Supported]) {
                receiveData = [self._server receiveSpecLenBytes4:expectDataLen];
            } else {
                receiveData = [self._server receiveSpecLenBytes6:expectDataLen];
            }
            if (receiveData != nil)
            {
                [receiveData getBytes:&receiveOneByte length:1];
            }
            else
            {
                receiveOneByte = -1;
            }
            if (receiveOneByte == expectOneByte)
            {
                if (DEBUG_ON)
                {
                    NSLog(@"ESPTouchTask __listenAsyn() receive correct broadcast");
                }
                // change the socket's timeout
                NSTimeInterval consume = [[NSDate date] timeIntervalSince1970] - startTimestamp;
                int timeout = (int)([self._parameter getWaitUdpTotalMillisecond] - consume*1000);
                if (timeout < 0)
                {
                    if (DEBUG_ON)
                    {
                        NSLog(@"ESPTouchTask __listenAsyn() esptouch timeout");
                    }
                    break;
                }
                else
                {
                    if (DEBUG_ON)
                    {
                        NSLog(@"ESPTouchTask __listenAsyn() socketServer's new timeout is %d milliseconds",timeout);
                    }
                    [self._server setSocketTimeout:timeout];
                    if (DEBUG_ON)
                    {
                        NSLog(@"ESPTouchTask __listenAsyn() receive correct broadcast");
                    }
                    if (receiveData != nil)
                    {
                        NSString *bssid =
                        [ESP_ByteUtil parseBssid:(Byte *)[receiveData bytes]
                                          Offset:[self._parameter getEsptouchResultOneLen]
                                           Count:[self._parameter getEsptouchResultMacLen]];
                        NSData *inetAddrData =
                        [ESP_NetUtil parseInetAddrByData:receiveData
                                               andOffset:[self._parameter getEsptouchResultOneLen] + [self._parameter getEsptouchResultMacLen]
                                                andCount:[self._parameter getEsptouchResultIpLen]];
                        [self __putEsptouchResultIsSuc:YES AndBssid:bssid AndInetAddr:inetAddrData];
                    }
                }
            }
            else
            {
                if (DEBUG_ON)
                {
                    NSLog(@"ESPTouchTask __listenAsyn() receive rubbish message, just ignore");
                }
            }
        }
        self._isSuc = [self._esptouchResultArray count] >= [self._parameter getExpectTaskResultCount];
        [self __interrupt];
        if (DEBUG_ON)
        {
            NSLog(@"ESPTouchTask __listenAsyn() finish");
        }
        [self endBackgroundTask];
    });
}

- (void) interrupt
{
    if (DEBUG_ON)
    {
        NSLog(@"ESPTouchTask interrupt()");
    }
    self.isCancelled = YES;
    [self __interrupt];
}

- (void) __interrupt
{
    self._isInterrupt = YES;
    [self._client interrupt];
    [self._server interrupt];
    // notify the ESPTouchTask to wake up from sleep mode
    [self __notify];
}

- (BOOL) __execute: (ESPTouchGenerator *)generator
{
    NSTimeInterval startTime = [[NSDate date] timeIntervalSince1970];
    NSTimeInterval currentTime = startTime;
    NSTimeInterval lastTime = currentTime - [self._parameter getTimeoutTotalCodeMillisecond];
    
    NSArray *gcBytes2 = [generator getGCBytes2];
    NSArray *dcBytes2 = [generator getDCBytes2];
    
    int index = 0;
    
    while (!self._isInterrupt)
    {
        if (currentTime - lastTime >= [self._parameter getTimeoutTotalCodeMillisecond]/1000.0)
        {
            if (DEBUG_ON)
            {
                NSLog(@"ESPTouchTask __execute() send gc code ");
            }
            // send guide code
            while (!self._isInterrupt && [[NSDate date] timeIntervalSince1970] - currentTime < [self._parameter getTimeoutGuideCodeMillisecond]/1000.0)
            {
                [self._client sendDataWithBytesArray2:gcBytes2
                                     ToTargetHostName:[self._parameter getTargetHostname]
                                             WithPort:[self._parameter getTargetPort]
                                          andInterval:[self._parameter getIntervalGuideCodeMillisecond]];
                // check whether the udp is send enough time
                if ([[NSDate date] timeIntervalSince1970] - startTime > [self._parameter getWaitUdpSendingMillisecond]/1000.0)
                {
                    break;
                }
            }
            lastTime = currentTime;
        }
        else
        {
            [self._client sendDataWithBytesArray2:dcBytes2
                                           Offset:index
                                            Count:ONE_DATA_LEN
                                 ToTargetHostName:[self._parameter getTargetHostname]
                                         WithPort:[self._parameter getTargetPort]
                                      andInterval:[self._parameter getIntervalDataCodeMillisecond]];
            index = (index + ONE_DATA_LEN) % [dcBytes2 count];
        }
        currentTime = [[NSDate date] timeIntervalSince1970];
        // check whether the udp is send enough time
        if ([[NSDate date] timeIntervalSince1970] - startTime > [self._parameter getWaitUdpSendingMillisecond]/1000.0)
        {
            break;
        }
    }
    
    return self._isSuc;
}

- (void) __checkTaskValid
{
    if (self._isExecutedAlready)
    {
        perror("ESPTouchTask __checkTaskValid() fail, the task could be executed only once");
    }
    // !!!NOTE: the esptouch task could be executed only once
    assert(!self._isExecutedAlready);
    self._isExecutedAlready = YES;
}

- (ESPTouchResult *) executeForResult
{
    return [[self executeForResults:1] objectAtIndex:0];
}

- (NSArray*) executeForResults:(int) expectTaskResultCount
{
    // set task result count
    if (expectTaskResultCount <= 0)
    {
        expectTaskResultCount = INT32_MAX;
    }
    [self._parameter setExpectTaskResultCount:expectTaskResultCount];
    
    [self __checkTaskValid];
    
    // generator the esptouch byte[][] to be transformed, which will cost
    // some time(maybe a bit much)
    ESPTouchGenerator *generator = [[ESPTouchGenerator alloc]initWithSsid:self._apSsid andApBssid:self._apBssid andApPassword:self._apPwd andInetAddrData:self._localInetAddrData andIsSsidHidden:self._isSsidHidden];
    // listen the esptouch result asyn
    [self __listenAsyn:[self._parameter getEsptouchResultTotalLen]];
    BOOL isSuc = NO;
    for (int i = 0; i < [self._parameter getTotalRepeatTime]; i++)
    {
        isSuc = [self __execute:generator];
        if (isSuc)
        {
            return [self __getEsptouchResultList];
        }
    }
    
    if (!self._isInterrupt)
    {
        [self __sleep: [self._parameter getWaitUdpReceivingMillisecond]];
        [self __interrupt];
    }
    
    return [self __getEsptouchResultList];
}

// sleep some milliseconds
- (BOOL) __sleep :(long) milliseconds
{
    if (DEBUG_ON)
    {
        NSLog(@"ESPTouchTask __sleep() start");
    }
    NSDate *date = [NSDate dateWithTimeIntervalSinceNow: milliseconds/1000.0];
    [self._condition lock];
    BOOL signaled = NO;
    while (!self._isWakeUp && (signaled = [self._condition waitUntilDate:date]))
    {
    }
    [self._condition unlock];
    if (DEBUG_ON)
    {
        NSLog(@"ESPTouchTask __sleep() end, receive signal is %@", signaled ? @"YES" : @"NO");
    }
    return signaled;
}

// notify the sleep thread to wake up
- (void) __notify
{
    if (DEBUG_ON)
    {
        NSLog(@"ESPTouchTask __notify()");
    }
    [self._condition lock];
    self._isWakeUp = YES;
    [self._condition signal];
    [self._condition unlock];
}

- (void) setEsptouchDelegate: (NSObject<ESPTouchDelegate> *) esptouchDelegate
{
    self._esptouchDelegate = esptouchDelegate;
}

@end
