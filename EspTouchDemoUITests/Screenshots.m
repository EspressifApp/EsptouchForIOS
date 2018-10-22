//
//  EspTouchDemoUITests.m
//  EspTouchDemoUITests
//
//  Created by Florian BUREL on 22/10/2018.
//  Copyright © 2018 Espressif. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "EspTouchDemoUITests-Swift.h"

@interface EspTouchDemoUITests : XCTestCase

@end

@implementation EspTouchDemoUITests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.

    // In UI tests it is usually best to stop immediately when a failure occurs.
    self.continueAfterFailure = NO;

    // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
    XCUIApplication * app = [[XCUIApplication alloc] init];
    
     // Setup fastlane snapshot
    [Snapshot setupSnapshot:app];
    
    // warn the app that she should run in screenshot mode
    app.launchArguments = [app.launchArguments arrayByAddingObject:@"Screenshots"];
    
    // Finally launches the app
    [app launch];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void) test_01 {
    // Use recording to get started writing UI tests.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    
    // take capture of the main screen
    [Snapshot snapshot:@"MainScreen" timeWaitingForIdle:2];
    
}

@end
