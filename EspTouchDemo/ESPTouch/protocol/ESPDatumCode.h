//
//  ESPDatumCode.h
//  EspTouchDemo
//
//  Created by fby on 4/9/15.
//  Copyright (c) 2015 fby. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ESPDatumCode : NSObject
{
    @private
    NSMutableArray *_dataCodes;
}

/**
 * Constructor of DatumCode
 *
 * @param apSsid
 *            the Ap's ssid
 * @param apBssid
 *            the Ap's bssid
 * @param apPwd
 *            the Ap's password ssid
 * @param ipAddrData
 *            the ip address of the phone or pad
 * @param isSsidHidden
 *            whether the Ap's ssid is hidden
 *
 */
- (id) initWithSsid: (NSData *) apSsid andApBssid: (NSData *) apBssid andApPwd: (NSData*) apPwd andInetAddrData: (NSData *) ipAddrData andIsSsidHidden: (BOOL) isSsidHidden;

- (NSData *) getBytes;

- (NSData *) getU16s;

@end
