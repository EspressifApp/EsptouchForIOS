//
//  ESPViewController.h
//  EspTouchDemo
//
//  Created by fby on 3/23/15.
//  Copyright (c) 2015 fby. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ESPViewController : UIViewController<UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UILabel *ssidLabel;
@property (weak, nonatomic) IBOutlet UILabel *bssidLabel;
@property (weak, nonatomic) IBOutlet UISegmentedControl *broadcastSC;

@end
