//
//  ESPUDPSocketServer.m
//  EspTouchDemo
//
//  Created by fby on 4/13/15.
//  Copyright (c) 2015 fby. All rights reserved.
//

#import "ESPUDPSocketServer.h"
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <sys/types.h>
#include "ESPTouchTask.h"

#define SOCKET_NULL     -1

@interface ESPUDPSocketServer ()

@property(nonatomic,assign) int _sck_fd4;
@property(nonatomic,assign) int _sck_fd6;

// it is used to check whether the socket is closed already to prevent close more than once.
// especially, when you close the socket second time, it is created just now, it will crash.
//
//      // suppose fd1 = 4, fd1 belong to obj1
// e.g. int fd1 = socket(AF_INET,SOCK_DRAM,0);
//      close(fd1);
//
//      // suppose fd2 = 4 as well, fd2 belong to obj2
//      int fd2 = socket(AF_INET,SOCK_DRAM,0);
//
//      // obj1's dealloc() is called by system, so
//      close(fd1);
//
//      // Amazing!!! at the moment, fd2 is close by others
//
@property(nonatomic,assign) volatile bool _isClosed;
// it is used to lock the close method
@property(nonatomic,strong) volatile NSLock *_lock;

@end

@implementation ESPUDPSocketServer

- (BOOL) initWithPort4: (int) port AndSocketTimeout: (int) socketTimeout
{
    self._sck_fd4 = socket(AF_INET,SOCK_DGRAM,0);
    if (DEBUG_ON)
    {
        NSLog(@"##########################server init(): _sck_fd4=%d", self._sck_fd4);
    }
    if (self._sck_fd4 < 0)
    {
        if (DEBUG_ON)
        {
            perror("server: _skd_fd4 init() fail\n");
        }
        return NO;
    }
    // init socket4 params
    struct sockaddr_in server_addr;
    socklen_t addr_len;
    memset(&server_addr, 0, sizeof(server_addr));
    server_addr.sin_family = AF_INET;
    server_addr.sin_port = htons(port);
    server_addr.sin_addr.s_addr = INADDR_ANY;
    addr_len = sizeof(server_addr);
    // set broadcast
    const int opt = 1;
    if (setsockopt(self._sck_fd4,SOL_SOCKET,SO_BROADCAST,(char *)&opt, sizeof(opt)) < 0)
    {
        if (DEBUG_ON)
        {
            perror("server init() sck4: setsockopt SO_BROADCAST fail\n");
        }
        [self close];
        return NO;
    }
    // set socket timeout
    if (![self setSocketTimeout:socketTimeout SocketFd:self._sck_fd4]) {
        if (DEBUG_ON) {
            perror("server: sck4: setsockopt SO_RCVTIMEO fail\n");
        }
        [self close];
        return NO;
    }
    // set SO_REUSEADDR for ipv4
    if (setsockopt(self._sck_fd4, SOL_SOCKET, SO_REUSEADDR, (char *)&opt, sizeof(opt))< 0) {
        if (DEBUG_ON)
        {
            perror("server init() sck4: setsockopt SO_REUSEADDR fail\n");
        }
        [self close];
        return NO;
    }
    // bind for ipv4
    if (bind(self._sck_fd4, (struct sockaddr*)&server_addr, addr_len) < 0)
    {
        if (DEBUG_ON)
        {
            perror("server init() sck4: bind fail\n");
        }
        [self close];
        return NO;
    }
    
    return YES;
}

- (BOOL) initWithPort6: (int) port AndSocketTimeout: (int) socketTimeout
{
    self._sck_fd6 = socket(AF_INET6,SOCK_DGRAM,0);
    if (DEBUG_ON)
    {
        NSLog(@"##########################server init(): _sck_fd6=%d", self._sck_fd6);
    }
    if (self._sck_fd6 < 0)
    {
        if (DEBUG_ON)
        {
            perror("server: _skd_fd6 init() fail\n");
        }
        return NO;
    }
    // init socket6 params
    struct sockaddr_in6 server_addr6;
    socklen_t addr6_len = sizeof(server_addr6);
    memset(&server_addr6, 0, addr6_len);
    server_addr6.sin6_family = AF_INET6;
    server_addr6.sin6_port = htons(port);
    server_addr6.sin6_addr = in6addr_any;
    // set socket timeout
    if (![self setSocketTimeout:socketTimeout SocketFd:self._sck_fd6]) {
        if (DEBUG_ON) {
            perror("server: sck4: setsockopt SO_RCVTIMEO fail\n");
        }
        [self close];
        return NO;
    }
    // set SO_REUSEADDR for ipv6
    const int opt = 1;
    if (setsockopt(self._sck_fd6, SOL_SOCKET, SO_REUSEADDR, (char *)&opt, sizeof(opt))< 0) {
        if (DEBUG_ON)
        {
            perror("server init() sck6: setsockopt SO_REUSEADDR fail\n");
        }
        [self close];
        return NO;
    }
    // bind for ipv6
    if (bind(self._sck_fd6, (struct sockaddr*)&server_addr6, addr6_len) < 0)
    {
        if (DEBUG_ON)
        {
            perror("server init() sck6: bind fail\n");
        }
        [self close];
        return NO;
    }

    return YES;
}

- (id) initWithPort:(int)port AndSocketTimeout:(int)socketTimeout
{
    self = [super init];
    if (self) {
        // create lock
        self._lock = [[NSLock alloc]init];
        // init
        self._isClosed = NO;
        self._sck_fd4 = SOCKET_NULL;
        self._sck_fd6 = SOCKET_NULL;
        // init sck4
        if (![self initWithPort4:port AndSocketTimeout:socketTimeout]) {
            if (DEBUG_ON) {
                NSLog(@"fail to init socket for ipv4");
            }
            return nil;
        }
        if (port==0) {
            struct sockaddr_in local_addr;
            socklen_t len = sizeof(local_addr);
            if (getsockname(self._sck_fd4, (struct sockaddr *)&local_addr, &len)==0) {
                port = ntohs(local_addr.sin_port);
            }
            else {
                if (DEBUG_ON) {
                    NSLog(@"fail to get socket port for ipv4");
                }
                [self close];
                return nil;
            }
        }
        _port = port;
        // init sck6
        if (![self initWithPort6:port AndSocketTimeout:socketTimeout]) {
            if (DEBUG_ON) {
                NSLog(@"fail to init socket for ipv6");
            }
            return nil;
        }
    }
    return self;
}

// make sure the socket will be closed sometime
- (void)dealloc
{
    if (DEBUG_ON)
    {
        NSLog(@"###################server dealloc()");
    }
    [self close];
}

- (void) close
{
    [self._lock lock];
    if (!self._isClosed)
    {
        if (self._sck_fd4!=SOCKET_NULL) {
            if (DEBUG_ON)
            {
                NSLog(@"###################server close() fd4=%d",self._sck_fd4);
            }
            close(self._sck_fd4);
            self._sck_fd4 = SOCKET_NULL;
        }
        if (self._sck_fd6!=SOCKET_NULL) {
            if (DEBUG_ON)
            {
                NSLog(@"###################server close() fd6=%d",self._sck_fd6);
            }
            close(self._sck_fd6);
            self._sck_fd6 = SOCKET_NULL;
        }
        self._isClosed = true;
    }
    [self._lock unlock];
}

- (void) interrupt
{
    [self close];
}

- (BOOL) setSocketTimeout: (int) timeout SocketFd:(int) socketFd
{
    struct timeval tv;
    tv.tv_sec = timeout/1000;
    tv.tv_usec = timeout%1000*1000;
    if (setsockopt(socketFd,SOL_SOCKET,SO_RCVTIMEO,(char *)&tv, sizeof(tv)) < 0)
    {
        if (DEBUG_ON)
        {
            perror("server: setsockopt SO_RCVTIMEO fail\n");
        }
        return NO;
    } else {
        return YES;
    }
}

- (void) setSocketTimeout:(int)timeout
{
    [self setSocketTimeout:timeout SocketFd:self._sck_fd4];
    [self setSocketTimeout:timeout SocketFd:self._sck_fd6];
}

- (Byte) receiveOneByte4
{
    ssize_t recNumber = recv(self._sck_fd4, _buffer, BUFFER_SIZE, 0);
    if (recNumber > 0)
    {
        return _buffer[0];
    }
    else if(recNumber == 0)
    {
        if (DEBUG_ON)
        {
            perror("server: receiveOneByte4 socket is closed by the other\n");
        }
    }
    else
    {
        if (DEBUG_ON)
        {
            perror("server: receiveOneByte4 fail\n");
        }
    }
    return UINT8_MAX;
}

- (Byte) receiveOneByte6
{
    ssize_t recNumber = recv(self._sck_fd6, _buffer, BUFFER_SIZE, 0);
    if (recNumber > 0)
    {
        return _buffer[0];
    }
    else if(recNumber == 0)
    {
        if (DEBUG_ON)
        {
            perror("server: receiveOneByte6 socket is closed by the other\n");
        }
    }
    else
    {
        if (DEBUG_ON)
        {
            perror("server: receiveOneByte6 fail\n");
        }
    }
    return UINT8_MAX;
}

- (NSData *) receiveSpecLenBytes4: (int)len
{
    ssize_t recNumber = recv(self._sck_fd4, _buffer, BUFFER_SIZE, 0);
    if (recNumber==len)
    {
        NSData *data = [[NSData alloc]initWithBytes:_buffer length:recNumber];
        return data;
    }
    else if(recNumber==0)
    {
        if (DEBUG_ON)
        {
            perror("server: receiveOneByte4 socket is closed by the other\n");
        }
    }
    else if(recNumber<0)
    {
        if (DEBUG_ON)
        {
            perror("server: receiveOneByte4 fail\n");
        }
    }
    else
    {
        // receive rubbish message, just ignore it
    }
    return nil;
}

- (NSData *) receiveSpecLenBytes6:(int)len
{
    ssize_t recNumber = recv(self._sck_fd6, _buffer, BUFFER_SIZE, 0);
    if (recNumber==len)
    {
        NSData *data = [[NSData alloc]initWithBytes:_buffer length:recNumber];
        return data;
    }
    else if(recNumber==0)
    {
        if (DEBUG_ON)
        {
            perror("server: receiveOneByte6 socket is closed by the other\n");
        }
    }
    else if(recNumber<0)
    {
        if (DEBUG_ON)
        {
            perror("server: receiveOneByte6 fail\n");
        }
    }
    else
    {
        // receive rubbish message, just ignore it
    }
    return nil;

}

@end
