//
//  ESPTaskParameter.h
//  EspTouchDemo
//
//  Created by 白 桦 on 5/20/15.
//  Copyright (c) 2015 白 桦. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ESPTaskParameter : NSObject

/**
 * get interval millisecond for guide code(the time between each guide code sending)
 * @return interval millisecond for guide code(the time between each guide code sending)
 */
- (long) getIntervalGuideCodeMillisecond;

/**
 * get interval millisecond for data code(the time between each data code sending)
 * @return interval millisecond for data code(the time between each data code sending)
 */
- (long) getIntervalDataCodeMillisecond;

/**
 * get timeout millisecond for guide code(the time how much the guide code sending)
 * @return timeout millisecond for guide code(the time how much the guide code sending)
 */
- (long) getTimeoutGuideCodeMillisecond;

/**
 * get timeout millisecond for data code(the time how much the data code sending)
 * @return timeout millisecond for data code(the time how much the data code sending)
 */
- (long) getTimeoutDataCodeMillisecond;

/**
 * get timeout millisecond for total code(guide code and data code altogether)
 * @return timeout millisecond for total code(guide code and data code altogether)
 */
- (long) getTimeoutTotalCodeMillisecond;

/**
 * get total repeat time for executing esptouch task
 * @return total repeat time for executing esptouch task
 */
- (int) getTotalRepeatTime;

/**
 * the length of the Esptouch result 1st byte is the total length of ssid and
 * password, the other 6 bytes are the device's bssid
 */

/**
 * get esptouchResult length of one
 * @return length of one
 */
- (int) getEsptouchResultOneLen;

/**
 * get esptouchResult length of mac
 * @return length of mac
 */
- (int) getEsptouchResultMacLen;

/**
 * get esptouchResult length of ip
 * @return length of ip
 */
- (int) getEsptouchResultIpLen;

/**
 * get esptouchResult total length
 * @return total length
 */
- (int) getEsptouchResultTotalLen;

/**
 * get port for listening(used by server)
 * @return port for listening(used by server)
 */
- (int) getPortListening;

/**
 * get target hostname
 * @return target hostame(used by client)
 */
- (NSString *) getTargetHostname;

/**
 * get target port
 * @return target port(used by client)
 */
- (int) getTargetPort;

/**
 * get millisecond for waiting udp receiving(receiving without sending)
 * @return millisecond for waiting udp receiving(receiving without sending)
 */
- (int) getWaitUdpReceivingMillisecond;

/**
 * get millisecond for waiting udp sending(sending including receiving)
 * @return millisecond for waiting udep sending(sending including receiving)
 */
- (int) getWaitUdpSendingMillisecond;

/**
 * get millisecond for waiting udp sending and receiving
 * @return millisecond for waiting udp sending and receiving
 */
- (int) getWaitUdpTotalMillisecond;

/**
 * get the threshold for how many correct broadcast should be received
 * @return the threshold for how many correct broadcast should be received
 */
- (int) getThresholdSucBroadcastCount;

/**
 * set the millisecond for waiting udp sending and receiving
 * @param waitUdpTotalMillisecond the millisecond for waiting udp sending and receiving
 */
- (void) setWaitUdpTotalMillisecond: (int) waitUdpTotalMillisecond;


/**
 * get the count of expect task results
 * @return the count of expect task results
 */
- (int) getExpectTaskResultCount;

/**
 * set the count of expect task results
 * @param expectTaskResultCount the count of expect task results
 */
- (void) setExpectTaskResultCount: (int) expectTaskResultCount;

/**
 * get whether the router support IPv4
 * @return whether the router support IPv4
 */
- (BOOL) isIPv4Supported;

/**
 * set whether the router support IPv4
 * @param isIPv4Supported whether the router support IPv4
 */
- (void) setIsIPv4Supported:(BOOL) isIPv4Supported;

/**
 * get whether the router support IPv6
 * @return whether the router support IPv6
 */
- (BOOL) isIPv6Supported;

/**
 * set whether the router support IPv6
 * @param isIPv4Supported whether the router support IPv6
 */
- (void) setIsIPv6Supported:(BOOL) isIPv6Supported;

/**
 * set listening port for IPv6
 */
- (void) setListeningPort6:(int) listeningPort6;

/**
 * Set broadcast or multicast
 */
- (void) setBroadcast:(BOOL) broadcast;

@end
