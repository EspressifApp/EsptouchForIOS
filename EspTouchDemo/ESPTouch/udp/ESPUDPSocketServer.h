//
//  ESPUDPSocketServer.h
//  EspTouchDemo
//
//  Created by fby on 4/13/15.
//  Copyright (c) 2015 fby. All rights reserved.
//

#import <Foundation/Foundation.h>

#define BUFFER_SIZE 64

@interface ESPUDPSocketServer : NSObject
{
    @private
    Byte _buffer[BUFFER_SIZE];
}

@property (nonatomic, assign) int port;

- (void) close;

- (void) interrupt;

/**
 * Set the socket timeout in milliseconds
 *
 * @param timeout
 *            the timeout in milliseconds or 0 for no timeout.
 * @return true whether the timeout is set suc
 */
- (void) setSocketTimeout: (int) timeout;

/**
 * Receive one byte from the port
 *
 * @return one byte receive from the port or UINT8_MAX(it impossible receive it from the socket)
 */
- (Byte) receiveOneByte4;

- (NSData *) receiveSpecLenBytes4: (int)len;

- (Byte) receiveOneByte6;

- (NSData *) receiveSpecLenBytes6:(int)len;

- (id) initWithPort: (int) port AndSocketTimeout: (int) socketTimeout;

@end
