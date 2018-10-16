//
//  ESPTouchDelegate.h
//  EspTouchDemo
//
//  Created by 白 桦 on 8/14/15.
//  Copyright (c) 2015 白 桦. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ESPTouchResult.h"


@protocol ESPTouchDelegate <NSObject>

/**
 * when new esptouch result is added, the listener will call
 * onEsptouchResultAdded callback
 *
 * @param result
 *            the Esptouch result
 */
-(void) onEsptouchResultAddedWithResult: (ESPTouchResult *) result;

@end
