//
//  ESPTaskParameter.m
//  EspTouchDemo
//
//  Created by 白 桦 on 5/20/15.
//  Copyright (c) 2015 白 桦. All rights reserved.
//

#import "ESPTouchTaskParameter.h"

@interface ESPTaskParameter()
@property (nonatomic,assign) long intervalGuideCodeMillisecond;
@property (nonatomic,assign) long intervalDataCodeMillisecond;
@property (nonatomic,assign) long timeoutGuideCodeMillisecond;
@property (nonatomic,assign) long timeoutDataCodeMillisecond;
@property (nonatomic,assign) long timeoutTotalCodeMillisecond;
@property (nonatomic,assign) int totalRepeatTime;
@property (nonatomic,assign) int esptouchResultOneLen;
@property (nonatomic,assign) int esptouchResultMacLen;
@property (nonatomic,assign) int esptouchResultIpLen4;
@property (nonatomic,assign) int esptouchResultIpLen6;
@property (nonatomic,assign) int esptouchResultTotalLen4;
@property (nonatomic,assign) int esptouchResultTotalLen6;
@property (nonatomic,assign) int portListening4;
@property (nonatomic,assign) int portListening6;
@property (nonatomic,assign) int targetPort4;
@property (nonatomic,assign) int targetPort6;
@property (nonatomic,assign) int waitUdpReceivingMillisecond;
@property (nonatomic,assign) int waitUdpSendingMillisecond;
@property (nonatomic,assign) int thresholdSucBroadcastCount;
@property (nonatomic,assign) int expectTaskResultCount;
@property (nonatomic,assign) BOOL isIPv4Supported0;
@property (nonatomic,assign) BOOL isIPv6Supported0;
@property (nonatomic,assign) BOOL broadcast;
@end

@implementation ESPTaskParameter

static int _datagramCount = 0;

- (id) init
{
    self = [super init];
    if (self) {
        self.intervalGuideCodeMillisecond = 8;
        self.intervalDataCodeMillisecond = 8;
        self.timeoutGuideCodeMillisecond = 2000;
        self.timeoutDataCodeMillisecond = 4000;
        self.timeoutTotalCodeMillisecond = 2000 + 4000;
        self.totalRepeatTime = 1;
        self.esptouchResultOneLen = 1;
        self.esptouchResultMacLen = 6;
        self.esptouchResultIpLen4 = 4;
        self.esptouchResultIpLen6 = 16;
        self.esptouchResultTotalLen4 = 1 + 6 + 4;
        self.esptouchResultTotalLen6 = 1 + 6 + 16;
        self.portListening4 = 18266;
        self.portListening6 = 0;
        self.targetPort4 = 7001;
        self.targetPort6 = 7001;
        self.waitUdpReceivingMillisecond = 15000;
        self.waitUdpSendingMillisecond = 45000;
        self.thresholdSucBroadcastCount = 1;
        self.expectTaskResultCount = 1;
        self.isIPv4Supported0 = YES;
        self.isIPv6Supported0 = YES;
    }
    return self;
}

// the range of the result should be 1-100
- (int) __getNextDatagramCount
{
    return 1 + (_datagramCount++) % 100;
}

- (long) getIntervalGuideCodeMillisecond
{
    return self.intervalGuideCodeMillisecond;
}

- (long) getIntervalDataCodeMillisecond
{
    return self.intervalDataCodeMillisecond;
}

- (long) getTimeoutGuideCodeMillisecond
{
    return self.timeoutGuideCodeMillisecond;
}

- (long) getTimeoutDataCodeMillisecond
{
    return self.timeoutDataCodeMillisecond;
}

- (long) getTimeoutTotalCodeMillisecond
{
    return self.timeoutTotalCodeMillisecond;
}

- (int) getTotalRepeatTime
{
    return self.totalRepeatTime;
}

- (int) getEsptouchResultOneLen
{
    return self.esptouchResultOneLen;
}


- (int) getEsptouchResultMacLen
{
    return self.esptouchResultMacLen;
}


- (int) getEsptouchResultIpLen
{
    return _isIPv4Supported0 ? _esptouchResultIpLen4 : _esptouchResultIpLen6;
}


- (int) getEsptouchResultTotalLen
{
    if (_isIPv4Supported0) {
        return _esptouchResultTotalLen4;
    } else {
        return _esptouchResultTotalLen6;
    }
    
}

- (int) getPortListening
{
    if (_isIPv4Supported0) {
        return _portListening4;
    } else {
        return _portListening6;
    }
}

// target hostname is : 234.1.1.1, 234.2.2.2, 234.3.3.3 to 234.100.100.100 for IPv4
// target hostname is : ff02::1 for IPv6
- (NSString *) getTargetHostname
{
    if (_isIPv4Supported0) {
        if (self.broadcast) {
            return @"255.255.255.255";
        } else {
            int count = [self __getNextDatagramCount];
            return [NSString stringWithFormat: @"234.%d.%d.%d", count, count, count];
        }
    } else {
        return @"ff02::1%en0";
    }
}

- (int) getTargetPort
{
    if (_isIPv4Supported0) {
        return _targetPort4;
    } else {
        return _targetPort6;
    }
}

- (int) getWaitUdpReceivingMillisecond
{
    return self.waitUdpReceivingMillisecond;
}

- (int) getWaitUdpSendingMillisecond
{
    return self.waitUdpSendingMillisecond;
}

- (int) getWaitUdpTotalMillisecond
{
    return self.waitUdpReceivingMillisecond + self.waitUdpSendingMillisecond;
}

- (int) getThresholdSucBroadcastCount
{
    return self.thresholdSucBroadcastCount;
}

- (void) setWaitUdpTotalMillisecond: (int) waitUdpTotalMillisecond
{
    if (waitUdpTotalMillisecond < self.waitUdpReceivingMillisecond + [self getTimeoutTotalCodeMillisecond])
    {
        // if it happen, even one turn about sending udp broadcast can't be completed
        NSLog(@"ESPTouchTaskParameter waitUdpTotalMillisecod is invalid, it is less than mWaitUdpReceivingMilliseond + [self getTimeoutTotalCodeMillisecond]");
        assert(0);
    }
    self.waitUdpSendingMillisecond = waitUdpTotalMillisecond - self.waitUdpReceivingMillisecond;
}

- (int) getExpectTaskResultCount
{
    return self.expectTaskResultCount;
}

- (void) setExpectTaskResultCount: (int) expectTaskResultCount
{
    _expectTaskResultCount = expectTaskResultCount;
}

- (BOOL) isIPv4Supported
{
    return _isIPv4Supported0;
}

- (void) setIsIPv4Supported:(BOOL) isIPv4Supported
{
    _isIPv4Supported0 = isIPv4Supported;
}

- (BOOL) isIPv6Supported
{
    return _isIPv6Supported0;
}

- (void) setIsIPv6Supported:(BOOL) isIPv6Supported
{
    _isIPv6Supported0 = isIPv6Supported;
}

- (void) setListeningPort6:(int) listeningPort6
{
    _portListening6 = listeningPort6;
}

- (void)setBroadcast:(BOOL)broadcast {
    _broadcast = broadcast;
}

@end
