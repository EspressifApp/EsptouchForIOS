//
//  ESPCheckAppVersion.m
//  ESPMeshLibrary
//
//  Created by fanbaoying on 2019/1/4.
//  Copyright © 2019年 zhaobing. All rights reserved.
//

#import "ESPCheckAppVersion.h"
#import <UIKit/UIKit.h>

@interface ESPCheckAppVersion ()<UIAlertViewDelegate>

@property (nonatomic, strong) NSString *appId;

@end
@implementation ESPCheckAppVersion

+ (ESPCheckAppVersion *)sharedInstance
{
    static ESPCheckAppVersion *instance = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        instance = [[ESPCheckAppVersion alloc] init];
        
    });
    
    return instance;
}

- (ESPVersionStatus)checkAppVersion:(NSString *)appId
{
    NSURL *appUrl = [NSURL URLWithString:[NSString stringWithFormat:@"http://itunes.apple.com/lookup?id=%@",appId]];
    NSString *appMsg = [NSString stringWithContentsOfURL:appUrl encoding:NSUTF8StringEncoding error:nil];
    NSDictionary *appMsgDict = [self jsonStringToDictionary:appMsg];
    NSDictionary *appResultsDict = [appMsgDict[@"results"] lastObject];
    NSString *appStoreVersion = appResultsDict[@"version"];
//    float newVersionFloat = [appStoreVersion floatValue];//新发布的版本号
    
    NSString *currentVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
//    float currentVersionFloat = [currentVersion floatValue];//使用中的版本号
    
    return [self compareVersion2:appStoreVersion to:currentVersion];
    
    
}

/**
 比较两个版本号的大小
 
 @param v1 第一个版本号
 @param v2 第二个版本号
 @return 版本号相等,返回0; v1小于v2,返回-1; 否则返回1.
 */
- (ESPVersionStatus)compareVersion2:(NSString *)v1 to:(NSString *)v2 {
    // 都为空，相等，返回0
    if (!v1 && !v2) {
        return 0;
    }

    // v1为空，v2不为空，返回-1
    if (!v1 && v2) {
        return -1;
    }

    // v2为空，v1不为空，返回1
    if (v1 && !v2) {
        return 1;
    }

    // 获取版本号字段
    NSArray *v1Array = [v1 componentsSeparatedByString:@"."];
    NSArray *v2Array = [v2 componentsSeparatedByString:@"."];
    // 取字段最大的，进行循环比较
    NSInteger bigCount = (v1Array.count > v2Array.count) ? v1Array.count : v2Array.count;

    for (int i = 0; i < bigCount; i++) {
        // 字段有值，取值；字段无值，置0。
        NSInteger value1 = (v1Array.count > i) ? [[v1Array objectAtIndex:i] integerValue] : 0;
        NSInteger value2 = (v2Array.count > i) ? [[v2Array objectAtIndex:i] integerValue] : 0;
        if (value1 > value2) {
            // v1版本字段大于v2版本字段，返回1
            return ESPVersionAscending;
        } else if (value1 < value2) {
            // v2版本字段大于v1版本字段，返回-1
            return ESPVersionDescending;
        }
        
        // 版本相等，继续循环。
    }

    // 版本号相等
    return ESPVersionSame;
}

- (NSDictionary *)checkAppVersionNumber:(NSString *)appId
{
    if (![appId isEqualToString:@""]) {
        NSURL *appUrl = [NSURL URLWithString:[NSString stringWithFormat:@"http://itunes.apple.com/lookup?id=%@",appId]];
        id appMsg = [NSString stringWithContentsOfURL:appUrl encoding:NSUTF8StringEncoding error:nil];
        //    NSLog(@"%@",appMsg);
        NSDictionary *appMsgDict = [self jsonStringToDictionary:appMsg];
        NSDictionary *appResultsDict = [appMsgDict[@"results"] lastObject];
        
        return appResultsDict;
    }else {
        return @{};
    }
}

- (BOOL)appVersionUpdate:(NSString *)appId {
    NSString *appIdStr = [NSString stringWithFormat:@"https://itunes.apple.com/cn/app/id%@?mt=8", appId];
    BOOL updateBool= [[UIApplication sharedApplication] openURL:[NSURL URLWithString:appIdStr]];
    return updateBool;
}

- (NSDictionary *)jsonStringToDictionary:(NSString *)jsonStr
{
    if (jsonStr == nil)
    {
        return nil;
    }
    
    NSData *jsonData = [jsonStr dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error;
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:jsonData
                                                         options:NSJSONReadingMutableContainers
                                                           error:&error];
    if (error)
    {
        //NSLog(@"json格式string解析失败:%@",error);
        return nil;
    }
    
    return dict;
}

- (void)gotoSystemSetting {
    NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
    if ([[UIApplication sharedApplication] canOpenURL:url]) {
        if (@available(iOS 10.0, *)) {
            [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:^(BOOL success) {
                if (success) {
                    NSLog(@"success");
                }else{
                    NSLog(@"fail");
                }
            }];
        } else {
            [[UIApplication sharedApplication] openURL:url];
        }
    }
}

- (void)openBrowserWithURL:(NSString *)urlStr {
    NSURL *url = [NSURL URLWithString:urlStr];
    if ([[UIApplication sharedApplication] canOpenURL:url]) {
        if (@available(iOS 10.0, *)) {
            [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:^(BOOL success) {
                if (success) {
                    NSLog(@"success");
                }else{
                    NSLog(@"fail");
                }
            }];
        } else {
            [[UIApplication sharedApplication] openURL:url];
        }
    }
}

@end
