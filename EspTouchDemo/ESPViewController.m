//
//  ESPViewController.m
//  EspTouchDemo
//
//  Created by 白 桦 on 3/23/15.
//  Copyright (c) 2015 白 桦. All rights reserved.
//

#import "ESPViewController.h"
#import "ESPTouchTask.h"
#import "ESPTouchResult.h"
#import "ESP_NetUtil.h"
#import "ESPTouchDelegate.h"
#import "ESPAES.h"
#import "AFNetworking.h"

#import "ESPTools.h"
#import <CoreLocation/CoreLocation.h>

// the three constants are used to hide soft-keyboard when user tap Enter or Return
#define HEIGHT_KEYBOARD 216
#define HEIGHT_TEXT_FIELD 30
#define HEIGHT_SPACE (6+HEIGHT_TEXT_FIELD)

@interface EspTouchDelegateImpl : NSObject<ESPTouchDelegate>

@end

@implementation EspTouchDelegateImpl

-(void) dismissAlert:(UIAlertView *)alertView
{
    [alertView dismissWithClickedButtonIndex:[alertView cancelButtonIndex] animated:YES];
}

-(void) showAlertWithResult: (ESPTouchResult *) result
{
    NSString *title = nil;
    NSString *message = [NSString stringWithFormat:@"%@ is connected to the wifi" , result.bssid];
    NSTimeInterval dismissSeconds = 3.5;
    UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:title message:message delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
    [alertView show];
    [self performSelector:@selector(dismissAlert:) withObject:alertView afterDelay:dismissSeconds];
}

-(void) onEsptouchResultAddedWithResult: (ESPTouchResult *) result
{
    NSLog(@"EspTouchDelegateImpl onEsptouchResultAddedWithResult bssid: %@", result.bssid);
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showAlertWithResult:result];
    });
}

@end

@interface ESPViewController ()

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *_spinner;
@property (weak, nonatomic) IBOutlet UITextField *_pwdTextView;
@property (weak, nonatomic) IBOutlet UITextField *_taskResultCountTextView;
@property (weak, nonatomic) IBOutlet UIButton *_confirmCancelBtn;
@property (weak, nonatomic) IBOutlet UILabel *_versionLabel;

@property (weak, nonatomic) IBOutlet UILabel *ssidTitle;
@property (weak, nonatomic) IBOutlet UILabel *bssidTitle;
@property (weak, nonatomic) IBOutlet UILabel *pwdTitle;
@property (weak, nonatomic) IBOutlet UILabel *deviceCountTitle;
@property (weak, nonatomic) IBOutlet UILabel *reminderContent;


// to cancel ESPTouchTask when
@property (atomic, strong) ESPTouchTask *_esptouchTask;

// the state of the confirm/cancel button
@property (nonatomic, assign) BOOL _isConfirmState;

// without the condition, if the user tap confirm/cancel quickly enough,
// the bug will arise. the reason is follows:
// 0. task is starting created, but not finished
// 1. the task is cancel for the task hasn't been created, it do nothing
// 2. task is created
// 3. Oops, the task should be cancelled, but it is running
@property (nonatomic, strong) NSCondition *_condition;

@property (nonatomic, strong) UIButton *_doneButton;
@property (nonatomic, strong) EspTouchDelegateImpl *_esptouchDelegate;

@property (nonatomic, strong)NSDictionary *netInfo;

@end

@implementation ESPViewController{
    CLLocationManager *_locationManagerSystem;
}

- (IBAction)tapConfirmCancelBtn:(UIButton *)sender
{
    [self tapConfirmForResults];
}


- (void) tapConfirmForResults
{
    self.netInfo = [self fetchNetInfo];
    self.ssidLabel.text = [_netInfo objectForKey:@"ssid"];
    self.bssidLabel.text = [_netInfo objectForKey:@"bssid"];
    
    // do confirm
    if (self._isConfirmState)
    {
        NSString *apSsid = self.ssidLabel.text;
        NSString *apPwd = self._pwdTextView.text;
        NSString *apBssid = self.bssidLabel.text;
        int taskCount = [self._taskResultCountTextView.text intValue];
        BOOL broadcast = self.broadcastSC.selectedSegmentIndex == 0 ? YES : NO;
        
        [self._spinner startAnimating];
        [self enableCancelBtn];
        NSLog(@"ESPViewController do confirm action...");
        dispatch_queue_t  queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        dispatch_async(queue, ^{
            NSLog(@"ESPViewController do the execute work...");
            // execute the task
            NSArray *esptouchResultArray = [self executeForResultsWithSsid:apSsid bssid:apBssid password:apPwd taskCount:taskCount broadcast:broadcast];
            // show the result to the user in UI Main Thread
            dispatch_async(dispatch_get_main_queue(), ^{
                [self._spinner stopAnimating];
                [self enableConfirmBtn];
                
                ESPTouchResult *firstResult = [esptouchResultArray objectAtIndex:0];
                // check whether the task is cancelled and no results received
                if (!firstResult.isCancelled)
                {
                    NSMutableString *mutableStr = [[NSMutableString alloc]init];
                    NSUInteger count = 0;
                    // max results to be displayed, if it is more than maxDisplayCount,
                    // just show the count of redundant ones
                    const int maxDisplayCount = 5;
                    if ([firstResult isSuc])
                    {
                        
                        for (int i = 0; i < [esptouchResultArray count]; ++i)
                        {
                            ESPTouchResult *resultInArray = [esptouchResultArray objectAtIndex:i];
                            [mutableStr appendString:[resultInArray description]];
                            [mutableStr appendString:@"\n"];
                            count++;
                            if (count >= maxDisplayCount)
                            {
                                break;
                            }
                        }
                        
                        if (count < [esptouchResultArray count])
                        {
                            [mutableStr appendString:[NSString stringWithFormat:@"\nthere's %lu more result(s) without showing\n",(unsigned long)([esptouchResultArray count] - count)]];
                        }
                        
//                       [[[UIAlertView alloc]initWithTitle:@"Execute Result" message:mutableStr delegate:nil cancelButtonTitle:@"I know" otherButtonTitles:nil]show];
                        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Execute Result" message:mutableStr preferredStyle:UIAlertControllerStyleAlert];
                        alert.accessibilityLabel = @"executeResult";
                        
                        UIAlertAction *action1 = [UIAlertAction actionWithTitle:@"I know" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                            
                        }];
                        [alert addAction:action1];
                        [self presentViewController:alert animated:YES completion:nil];
                    }
                    
                    else
                    {
//                        [[[UIAlertView alloc]initWithTitle:@"Execute Result" message:@"Esptouch did not find the device" delegate:nil cancelButtonTitle:@"I know" otherButtonTitles:nil]show];
                        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Execute Result" message:@"Esptouch did not find the device" preferredStyle:UIAlertControllerStyleAlert];
                        alert.accessibilityLabel = @"executeResult";
                        
                        UIAlertAction *action1 = [UIAlertAction actionWithTitle:@"I know" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                            
                        }];
                        [alert addAction:action1];
                        [self presentViewController:alert animated:YES completion:nil];
                    }
                }
                
            });
        });
    }
    // do cancel
    else
    {
        [self._spinner stopAnimating];
        [self enableConfirmBtn];
        NSLog(@"ESPViewController do cancel action...");
        [self cancel];
    }
}

#pragma mark - the example of how to cancel the executing task

- (void) cancel
{
    [self._condition lock];
    if (self._esptouchTask != nil)
    {
        [self._esptouchTask interrupt];
    }
    [self._condition unlock];
}

#pragma mark - the example of how to use executeForResults
- (NSArray *) executeForResultsWithSsid:(NSString *)apSsid bssid:(NSString *)apBssid password:(NSString *)apPwd taskCount:(int)taskCount broadcast:(BOOL)broadcast
{
    [self._condition lock];
    self._esptouchTask = [[ESPTouchTask alloc]initWithApSsid:apSsid andApBssid:apBssid andApPwd:apPwd];
    // set delegate
    [self._esptouchTask setEsptouchDelegate:self._esptouchDelegate];
    [self._esptouchTask setPackageBroadcast:broadcast];
    [self._condition unlock];
//    ESPTouchResult *ESPTR = self._esptouchTask.executeForResult;
    NSArray * esptouchResults = [self._esptouchTask executeForResults:taskCount];
    NSLog(@"ESPViewController executeForResult() result is: %@",esptouchResults);
    return esptouchResults;
}

// enable confirm button
- (void)enableConfirmBtn
{
    self._isConfirmState = YES;
    [self._confirmCancelBtn setTitle:@"Confirm" forState:UIControlStateNormal];
}

// enable cancel button
- (void)enableCancelBtn
{
    self._isConfirmState = NO;
    [self._confirmCancelBtn setTitle:@"Cancel" forState:UIControlStateNormal];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    self.navigationItem.title = @"EspTouch";
    
    self._isConfirmState = NO;
    self._pwdTextView.delegate = self;
    self._pwdTextView.keyboardType = UIKeyboardTypeASCIICapable;
    self._taskResultCountTextView.delegate = self;
    self._taskResultCountTextView.keyboardType = UIKeyboardTypeNumberPad;
    self._condition = [[NSCondition alloc]init];
    self._esptouchDelegate = [[EspTouchDelegateImpl alloc]init];
    NSString *currentVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    self._versionLabel.text = [NSString stringWithFormat:@"APP-v%@ / %@",currentVersion, ESPTOUCH_VERSION];
    [self enableConfirmBtn];
    
    [self userLocationAuth];
    //程序进入前台并处于活动状态调用
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(wifiViewUpdates) name:UIApplicationDidBecomeActiveNotification object:nil];
    //注册Wi-Fi变化通知
    AFNetworkReachabilityManager *manager = [AFNetworkReachabilityManager sharedManager];
    [manager startMonitoring];
    [manager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        [self wifiViewUpdates];
    }];
}

- (void)viewWillAppear:(BOOL)animated {
    [self systemLightAndDark];
}

- (void)systemLightAndDark {
    if (@available(iOS 13.0, *)) {
        if (self.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
            [self systemDark];
        }else {
            [self systemLight];
        }
    } else {
        [self systemLight];
    }
}

- (void)systemLight {
    self.view.backgroundColor = [UIColor whiteColor];
    self.ssidLabel.textColor = [UIColor blackColor];
    self.ssidTitle.textColor = [UIColor blackColor];
    self.bssidLabel.textColor = [UIColor blackColor];
    self.bssidTitle.textColor = [UIColor blackColor];
    self.pwdTitle.textColor = [UIColor blackColor];
    self.deviceCountTitle.textColor = [UIColor blackColor];
    self.reminderContent.textColor = [UIColor blackColor];
    self._versionLabel.textColor = [UIColor blackColor];
    self._spinner.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
}

- (void)systemDark {
    self.view.backgroundColor = [UIColor blackColor];
    self.ssidLabel.textColor = [UIColor whiteColor];
    self.ssidTitle.textColor = [UIColor whiteColor];
    self.bssidLabel.textColor = [UIColor whiteColor];
    self.bssidTitle.textColor = [UIColor whiteColor];
    self.pwdTitle.textColor = [UIColor whiteColor];
    self.deviceCountTitle.textColor = [UIColor whiteColor];
    self.reminderContent.textColor = [UIColor whiteColor];
    self._versionLabel.textColor = [UIColor whiteColor];
    self._spinner.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhite;
}

- (void)wifiViewUpdates {
    [self systemLightAndDark];
    self.netInfo = [self fetchNetInfo];
    self.ssidLabel.text = [_netInfo objectForKey:@"ssid"];
    self.bssidLabel.text = [_netInfo objectForKey:@"bssid"];
}

- (void)userLocationAuth {
    if (![self getUserLocationAuth]) {
        _locationManagerSystem = [[CLLocationManager alloc]init];
        [_locationManagerSystem requestWhenInUseAuthorization];
    }
}

- (NSDictionary *)fetchNetInfo
{
    NSMutableDictionary *wifiDic = [NSMutableDictionary dictionaryWithCapacity:0];
    wifiDic[@"ssid"] = ESPTools.getCurrentWiFiSsid;
    wifiDic[@"bssid"] = ESPTools.getCurrentBSSID;
    return wifiDic;
}

- (BOOL)getUserLocationAuth {
    BOOL result = NO;
    switch ([CLLocationManager authorizationStatus]) {
        case kCLAuthorizationStatusNotDetermined:
            break;
        case kCLAuthorizationStatusRestricted:
            break;
        case kCLAuthorizationStatusDenied:
            break;
        case kCLAuthorizationStatusAuthorizedAlways:
            result = YES;
            break;
        case kCLAuthorizationStatusAuthorizedWhenInUse:
            result = YES;
            break;
            
        default:
            break;
    }
    return result;
}

#pragma mark - the follow codes are just to make soft-keyboard disappear at necessary time

// when out of pwd textview, resign the keyboard
- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (![self._pwdTextView isExclusiveTouch])
    {
        [self._pwdTextView resignFirstResponder];
    }
    if (![self._taskResultCountTextView isExclusiveTouch]) {
        [self._taskResultCountTextView resignFirstResponder];
    }
}

#pragma mark -  the follow three methods are used to make soft-keyboard disappear when user finishing editing

// when textField begin editing, soft-keyboard apeear, do the callback
-(void)textFieldDidBeginEditing:(UITextField *)textField
{
    CGRect frame = textField.frame;
    int offset = frame.origin.y - (self.view.frame.size.height - (HEIGHT_KEYBOARD+HEIGHT_SPACE));
    
    NSTimeInterval animationDuration = 0.30f;
    [UIView beginAnimations:@"ResizeForKeyboard" context:nil];
    [UIView setAnimationDuration:animationDuration];
    
    if(offset > 0)
    {
        self.view.frame = CGRectMake(0.0f, -offset, self.view.frame.size.width, self.view.frame.size.height);
    }
    
    [UIView commitAnimations];
}

// when user tap Enter or Return, disappear the keyboard
-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

// when finish editing, make view restore origin state
-(void)textFieldDidEndEditing:(UITextField *)textField
{
    self.view.frame =CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
}

- (void) addButtonToKeyboard {
    // create custom button
    if (self._doneButton == nil) {
        self._doneButton  = [[UIButton alloc] initWithFrame:CGRectMake(0, 163, 106, 53)];
    }
    else {
        [self._doneButton setHidden:NO];
    }
    
    [self._doneButton addTarget:self action:@selector(doneButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    // locate keyboard view
    UIWindow* tempWindow = [[[UIApplication sharedApplication] windows] objectAtIndex:1];
    UIView* keyboard = nil;
    for(int i=0; i<[tempWindow.subviews count]; i++) {
        keyboard = [tempWindow.subviews objectAtIndex:i];
        // keyboard found, add the button
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 3.2) {
            if([[keyboard description] hasPrefix:@"<UIPeripheralHost"] == YES)
                [keyboard addSubview:self._doneButton];
        } else {
            if([[keyboard description] hasPrefix:@"<UIKeyboard"] == YES)
                [keyboard addSubview:self._doneButton];
        }
    }
}

- (void) doneButtonClicked:(id)Sender {
    //Write your code whatever you want to do on done button tap
    //Removing keyboard or something else
    if (![self._taskResultCountTextView isExclusiveTouch]) {
        [self._taskResultCountTextView resignFirstResponder];
    }
}

@end

