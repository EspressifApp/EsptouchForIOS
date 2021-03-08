//
//  ESPAppDelegate.m
//  EspTouchDemo
//
//  Created by fby on 3/23/15.
//  Copyright (c) 2015 fby. All rights reserved.
//

#import "ESPAppDelegate.h"
#import "ESPViewController.h"
#import "ESP_NetUtil.h"
#import "ESPBaseViewController.h"

@implementation ESPAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    [ESP_NetUtil tryOpenNetworkPermission];
    
    UINavigationController *navigationController = [[UINavigationController alloc]initWithRootViewController:[ESPBaseViewController new]];
    self.window.rootViewController = navigationController;
    navigationController.navigationBarHidden = NO;
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    if (application.backgroundTimeRemaining > 10)
    {
        NSLog(@"ESPAppDelegate: some thread goto background, remained: %f seconds", application.backgroundTimeRemaining);
    }
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

// it is used to show the current connected wifi's Ssid
- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
//    ESPViewController *vc = (ESPViewController *)self.window.rootViewController;
//    NSDictionary *netInfo = [self fetchNetInfo];
//    vc.ssidLabel.text = [netInfo objectForKey:@"SSID"];
//    vc.bssidLabel.text = [netInfo objectForKey:@"BSSID"];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

//- (NSString *)fetchSsid
//{
//    NSDictionary *ssidInfo = [self fetchNetInfo];
//
//    return [ssidInfo objectForKey:@"SSID"];
//}
//
//- (NSString *)fetchBssid
//{
//    NSDictionary *bssidInfo = [self fetchNetInfo];
//
//    return [bssidInfo objectForKey:@"BSSID"];
//}

// refer to http://stackoverflow.com/questions/5198716/iphone-get-ssid-without-private-library
//- (NSDictionary *)fetchNetInfo
//{
//
//    if (![self getUserLocationAuth]) {
//        _locationManagerSystem = [[CLLocationManager alloc]init];
//        [_locationManagerSystem requestWhenInUseAuthorization];
//    }
//
//    NSArray *interfaceNames = CFBridgingRelease(CNCopySupportedInterfaces());
////    NSLog(@"%s: Supported interfaces: %@", __func__, interfaceNames);
//
//    NSDictionary *SSIDInfo;
//    for (NSString *interfaceName in interfaceNames) {
//        SSIDInfo = CFBridgingRelease(
//                                     CNCopyCurrentNetworkInfo((__bridge CFStringRef)interfaceName));
//        NSLog(@"%s: %@ => %@", __func__, interfaceName, SSIDInfo);
//
//        BOOL isNotEmpty = (SSIDInfo.count > 0);
//        if (isNotEmpty) {
//            break;
//        }
//    }
//    return SSIDInfo;
//}
//
//- (BOOL)getUserLocationAuth {
//    BOOL result = NO;
//    switch ([CLLocationManager authorizationStatus]) {
//        case kCLAuthorizationStatusNotDetermined:
//            break;
//        case kCLAuthorizationStatusRestricted:
//            break;
//        case kCLAuthorizationStatusDenied:
//            break;
//        case kCLAuthorizationStatusAuthorizedAlways:
//            result = YES;
//            break;
//        case kCLAuthorizationStatusAuthorizedWhenInUse:
//            result = YES;
//            break;
//
//        default:
//            break;
//    }
//    return result;
//}

@end
