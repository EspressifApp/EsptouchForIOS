//
//  ESPProvisioningParams.m
//  EspTouchDemo
//
//  Created by AE on 2020/2/24.
//  Copyright © 2020 Espressif. All rights reserved.
//

#import "ESPProvisioningParams.h"
#import <CommonCrypto/CommonCryptor.h>
#import "ESP_CRC8.h"
#import "ESP_NetUtil.h"
#import "ESPProvisioningUDP.h"
#import "ESPPacketUtils.h"

@interface ESPProvisioningParams()

@property(strong, nonatomic) NSData *emptyData;

@property(assign, nonatomic) BOOL willEncrypt;
@property(strong, nonatomic) NSString *aesIV;

@property(assign, nonatomic) BOOL passwordEncode;
@property(assign, nonatomic) BOOL reservedEncode;
@property(assign, nonatomic) BOOL ssidEncode;
@property(strong, nonatomic) NSData *head;

@property(strong, nonatomic) NSMutableArray<NSData *> *dataPackets;

@end

static const BOOL DBUG = NO;

static const Byte VERSION = 0;
static const NSInteger SEQUENCE_FIRST = -1;

@implementation ESPProvisioningParams

- (instancetype)initWithSsid:(NSData *)ssid bssid:(NSData *)bssid password:(NSData *)password reservedData:(NSData *)reservedData aesKey:(NSString *)key appPortMark:(int)mark {
    self = [super init];
    if (self) {
        Byte emptyBytes[0];
        _emptyData = [NSData dataWithBytes:emptyBytes length:0];
        
        _ssid = ssid ? ssid : _emptyData;
        _bssid = bssid;
        _password = password ? password : _emptyData;
        _reservedData = reservedData ? reservedData : _emptyData;
        _aesKey = key ? key : @"";
        _appPortMark = mark;
        Byte aesIVBytes[16] = {};
        _aesIV = [[NSString alloc] initWithData:[NSData dataWithBytes:aesIVBytes length:16] encoding:NSUTF8StringEncoding];
        
        _dataPackets = [[NSMutableArray alloc] init];
        
        [self parse];
        [self generate];
    }
    return self;
}

- (NSArray<NSData *> *)getDataPackets {
    return [NSArray arrayWithArray:_dataPackets];
}

- (BOOL)checkCharEncode:(NSData *) data {
    Byte *buf = (Byte *)data.bytes;
    for(int i = 0; i < data.length; ++i) {
        Byte asciiCode = buf[i];
        if (asciiCode > 127) {
            return YES;
        }
    }
    return NO;
}

- (UInt8)crc:(NSData *)crcData {
    ESP_CRC8 *crc = [[ESP_CRC8 alloc] init];
    int dataLen = (int)[crcData length];
    Byte *bytes = (Byte *)crcData.bytes;
    [crc updateWithBuf:bytes Nbytes:dataLen];
    UInt8 result = [crc getValue];
    return result;
}

- (NSData *)randomData:(NSInteger)length {
    Byte buf[length];
    for (NSInteger i = 0; i < length; ++i) {
        buf[i] = arc4random() & 127;
    }
    return [[NSData alloc] initWithBytes:buf length:length];
}

- (NSData *)aesCBC:(NSData *)data {
    char keyPtr[kCCKeySizeAES128 + 1];  //kCCKeySizeAES128是加密位数 可以替换成256位的
    bzero(keyPtr, sizeof(keyPtr));
    [_aesKey getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF8StringEncoding];
    // IV
    char ivPtr[kCCBlockSizeAES128 + 1];
    bzero(ivPtr, sizeof(ivPtr));
    [_aesIV getCString:ivPtr maxLength:sizeof(ivPtr) encoding:NSUTF8StringEncoding];
    
    size_t bufferSize = [data length] + kCCBlockSizeAES128;
    void *buffer = malloc(bufferSize);
    size_t numBytesEncrypted = 0;
    CCCryptorStatus cryptorStatus = CCCrypt(kCCEncrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding, keyPtr, kCCKeySizeAES128, ivPtr, [data bytes], [data length], buffer, bufferSize, &numBytesEncrypted);
    
    if (cryptorStatus == kCCSuccess) {
        return [NSData dataWithBytesNoCopy:buffer length:numBytesEncrypted];
    }
    
    free(buffer);
    return nil;
}

- (void)parse {
    NSString *localInetAddr4 = [ESP_NetUtil getLocalIPv4];
    BOOL isIPv4 = [ESP_NetUtil isIPv4Addr:localInetAddr4];
    
    _willEncrypt = _aesKey.length > 0 && (_password.length > 0 || _reservedData.length > 0);
    _ssidEncode = [self checkCharEncode:_ssid];
    _passwordEncode = [self checkCharEncode:_password];
    _reservedEncode = [self checkCharEncode:_reservedData];
    
    NSInteger ssidInfo = _ssid.length | (_ssidEncode ? 0b10000000 : 0);
    NSInteger pwdInfo = _password.length | (_passwordEncode ? 0b10000000 : 0);
    NSInteger reservedInfo = _reservedData.length | (_reservedEncode ? 0b10000000 : 0);
    
    Byte bssidCrc = [self crc:_bssid];
    
    int flag = (isIPv4 ? 1 : 0) // bit0: ipv4 or ipv6
    | (_willEncrypt ? 0b010 : 0) // bit1 bit2: crypt
    | ((_appPortMark & 0b11) << 3) // bit3 bit4: app port
    | ((VERSION & 0b11) << 6); // bit6 bit7: version
    
    Byte head[] = {
            ssidInfo,
            pwdInfo,
            reservedInfo,
            bssidCrc,
            flag,
            0 // head crc
    };
    Byte headerCrc = [self crc:[NSData dataWithBytes:head length:5]];
    head[5] = headerCrc;
    _head = [NSData dataWithBytes:head length:6];
}

- (void)generate {
    ESP_CRC8 *crcCalc = [[ESP_CRC8 alloc] init];
    
    NSInteger padding;
    
    NSData *password;
    NSData *passwordPadding;
    NSInteger passwordPaddingFactor;
    BOOL passwordEncode;
    
    NSData *reservedData;
    NSData *reservedPadding;
    NSInteger reservedPaddingFactor;
    BOOL reservedEncode;
    
    NSData *ssid;
    NSData *ssidPadding;
    NSInteger ssidPaddingFactor;
    BOOL ssidEncode;
    
    if (_willEncrypt) {
        NSMutableData *willEncryptData = [NSMutableData data];
        [willEncryptData appendData:_password];
        [willEncryptData appendData:_reservedData];
        NSData *encryptedData = [self aesCBC:willEncryptData];
        password = encryptedData;
        passwordEncode = YES;
        passwordPaddingFactor = 5;
        passwordPadding = _emptyData;
        padding = passwordPaddingFactor - encryptedData.length % passwordPaddingFactor;
        if (padding < passwordPaddingFactor) {
            passwordPadding = [self randomData:padding];
        }
        
        reservedData = _emptyData;
        reservedPadding = _emptyData;
        reservedPaddingFactor = -1;
        reservedEncode = NO;
    } else if (!_passwordEncode && !_reservedEncode) {
        NSMutableData *nonEncryptData = [[NSMutableData alloc] init];
        [nonEncryptData appendData:_password];
        [nonEncryptData appendData:_reservedData];
        password = nonEncryptData;
        passwordEncode = NO;
        passwordPaddingFactor = 6;
        passwordPadding = _emptyData;
        padding = passwordPaddingFactor - nonEncryptData.length % passwordPaddingFactor;
        if (padding < 6) {
            passwordPadding = [self randomData:padding];
        }
        
        reservedData = _emptyData;
        reservedPadding = _emptyData;
        reservedPaddingFactor = -1;
        reservedEncode = NO;
    } else {
        password = _password;
        passwordEncode = _passwordEncode;
        passwordPaddingFactor = passwordEncode ? 5 : 6;
        passwordPadding = _emptyData;
        padding = passwordPaddingFactor - password.length % passwordPaddingFactor;
        if (padding < passwordPaddingFactor) {
            passwordPadding = [self randomData:padding];
        }
        
        reservedData = _reservedData;
        reservedEncode = _reservedEncode;
        reservedPaddingFactor = reservedEncode ? 5 : 6;
        reservedPadding = _emptyData;
        padding = reservedPaddingFactor - reservedData.length % reservedPaddingFactor;
        if (padding < reservedPaddingFactor) {
            reservedPadding = [self randomData:padding];
        }
    }

    ssid = _ssid;
    ssidEncode = _ssidEncode;
    ssidPaddingFactor = ssidEncode ? 5 : 6;
    ssidPadding = _emptyData;
    padding = ssidPaddingFactor - ssid.length % ssidPaddingFactor;
    if (padding < ssidPaddingFactor) {
        ssidPadding = [self randomData:padding];
    }
    
    NSMutableData *bufData = [[NSMutableData alloc] init];
    [bufData appendData:_head];
    [bufData appendData:password];
    [bufData appendData:passwordPadding];
    [bufData appendData:reservedData];
    [bufData appendData:reservedPadding];
    [bufData appendData:ssid];
    [bufData appendData:ssidPadding];
    
    NSInteger reservedBeginPosition = _head.length + password.length + passwordPadding.length;
    NSInteger ssidBeginPosition = reservedBeginPosition + reservedData.length + reservedPadding.length;
    NSInteger offset = 0;
    NSInputStream *is = [NSInputStream inputStreamWithData:bufData];
    [is open];
    NSInteger sequence = SEQUENCE_FIRST;
    NSInteger count = 0;
    while ([is hasBytesAvailable]) {
        NSInteger expectLength;
        BOOL tailIsCrc;
        if (sequence < SEQUENCE_FIRST + 1) {
            // First packet
            tailIsCrc = false;
            expectLength = 6;
        } else {
            if (offset < reservedBeginPosition) {
                // Password data
                tailIsCrc = !passwordEncode;
                expectLength = passwordPaddingFactor;
            } else if (offset < ssidBeginPosition) {
                // Reserved data
                tailIsCrc = !reservedEncode;
                expectLength = reservedPaddingFactor;
            } else {
                // SSID data
                tailIsCrc = !ssidEncode;
                expectLength = ssidPaddingFactor;
            }
        }
        Byte buf[6] = {};
        NSInteger read = [is read:buf maxLength:expectLength];
        if (read == 0) {
            break;
        }
        offset += read;
        
        [crcCalc reset];
        [crcCalc updateWithBuf:buf Nbytes:(int)read];
        Byte seqCrc = [crcCalc getValue];
        if (expectLength < 6) {
            buf[5] = seqCrc;
        }
        [self addDataFor6Bytes:buf sequence:sequence crc:seqCrc tailIsCrc:tailIsCrc];
        ++sequence;
        ++count;
    }
    [is close];
    
    [self setTotalSequenceSize:count];
}

- (void)setTotalSequenceSize:(NSInteger)size {
    NSData *data = [ESPPacketUtils getSequenceSizePacket:(size)];
    [self.dataPackets setObject:data atIndexedSubscript:1];
    [self.dataPackets setObject:data atIndexedSubscript:3];
}

- (void)addDataFor6Bytes:(Byte *)buf sequence:(NSInteger)sequence crc:(Byte)crc tailIsCrc:(BOOL)tailIsCrc {
    if (DBUG) {
        NSString *bufStr = [NSString stringWithFormat:@"[%d, %d, %d, %d, %d, %d]", buf[0], buf[1], buf[2], buf[3], buf[4], buf[5]];
        NSLog(@"buf=%@ , seq=%d , seqCrc=%d , tailIsCrc=%@", bufStr, (int)sequence, crc, tailIsCrc ? @"true" : @"false");
    }
    NSData *sequencePacket;
    if (sequence == SEQUENCE_FIRST) {
        sequencePacket = [ESPPacketUtils getSyncPacket];
        NSMutableData *sequecneSizePaccket = [NSMutableData dataWithLength:0];
        [self.dataPackets addObject:sequencePacket];
        [self.dataPackets addObject:sequecneSizePaccket];
        [self.dataPackets addObject:sequencePacket];
        [self.dataPackets addObject:sequecneSizePaccket];
    } else {
        sequencePacket = [ESPPacketUtils getSequencePacket:sequence];
        [self.dataPackets addObject:sequencePacket];
        [self.dataPackets addObject:sequencePacket];
        [self.dataPackets addObject:sequencePacket];
    }
    
    int bitCount = tailIsCrc ? 7 : 8;
    for (int i = 0; i < bitCount; ++i) {
        int data = (buf[5] >> i & 1)
        | ((buf[4] >> i & 1) << 1)
        | ((buf[3] >> i & 1) << 2)
        | ((buf[2] >> i & 1) << 3)
        | ((buf[1] >> i & 1) << 4)
        | ((buf[0] >> i & 1) << 5);
        
        NSData *dataPacket = [ESPPacketUtils getDataPacket:data index:i];
        [self.dataPackets addObject:dataPacket];
    }
    
    if (tailIsCrc) {
        NSData *dataPacket = [ESPPacketUtils getDataPacket:crc index:7];
        [self.dataPackets addObject:dataPacket];
    }
}

@end
