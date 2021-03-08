//
//  ESPBaseViewController.m
//  EspTouchDemo
//
//  Created by fanbaoying on 2020/2/25.
//  Copyright © 2020 Espressif. All rights reserved.
//

#import "ESPBaseViewController.h"

#import <CoreLocation/CoreLocation.h>
#import "ESPViewController.h"
#import "ESPTouchTwoViewController.h"

#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height
#define statusHeight [[UIApplication sharedApplication] statusBarFrame].size.height
@interface ESPBaseViewController ()<UITableViewDelegate, UITableViewDataSource, CLLocationManagerDelegate>

@property (nonatomic, strong) UITableView *espTouchTableView;

@property (nonatomic, strong) NSArray *dataArr;

@end

@implementation ESPBaseViewController{
    CLLocationManager *_locationManagerSystem;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationItem.title = NSLocalizedString(@"EspTouch-Main-Title", nil);
    self.navigationItem.accessibilityLabel = NSLocalizedString(@"EspTouch-Main-Title", nil);
    
    self.dataArr = @[@"EspTouch", @"EspTouch V2"];
//    self.navigationController.automaticallyAdjustsScrollViewInsets = NO;
//    self.navigationController.navigationBar.translucent = YES;
    
    [self userLocationAuth];
    
    self.espTouchTableView = [[UITableView alloc]initWithFrame:CGRectMake(0, statusHeight + 44, SCREEN_WIDTH, 140)];
    self.espTouchTableView.delegate = self;
    self.espTouchTableView.dataSource = self;
    self.espTouchTableView.scrollEnabled = NO;
    [self.view addSubview:_espTouchTableView];
    
}

- (void)userLocationAuth {
    if (![self getUserLocationAuth]) {
        _locationManagerSystem = [[CLLocationManager alloc]init];
        _locationManagerSystem.delegate = self;
        [_locationManagerSystem requestWhenInUseAuthorization];
    }
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    BOOL result = NO;
    switch (status) {
           case kCLAuthorizationStatusNotDetermined:
               break;
           case kCLAuthorizationStatusRestricted:
               break;
           case kCLAuthorizationStatusDenied:
                result = YES;
               break;
           case kCLAuthorizationStatusAuthorizedAlways:
               break;
           case kCLAuthorizationStatusAuthorizedWhenInUse:
               break;
               
           default:
               break;
       }
    if (result) {
         UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"EspTouch-location-title", nil) message:NSLocalizedString(@"EspTouch-location-content", nil) preferredStyle:UIAlertControllerStyleAlert];
         
         UIAlertAction *action1 = [UIAlertAction actionWithTitle:NSLocalizedString(@"EspTouch-cancel", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {}];
         UIAlertAction *action2 = [UIAlertAction actionWithTitle:NSLocalizedString(@"EspTouch-set", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
             [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
         }];
         [alert addAction:action1];
         [alert addAction:action2];
         [self presentViewController:alert animated:YES completion:nil];
    }
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

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _dataArr.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 70;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *cellID = @"cellID";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (cell == nil) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
    }
    cell.textLabel.text = _dataArr[indexPath.row];
    if (indexPath.row == 0) {
        cell.accessibilityIdentifier = @"enter_espTouch";
    } else {
        cell.accessibilityIdentifier = @"enter_espTouch_v2";
    }
    cell.accessibilityLabel = cell.textLabel.text;

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.row == 0) {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        UIViewController *viewController = [storyboard instantiateViewControllerWithIdentifier:@"espViewController"];
        [self.navigationController pushViewController:viewController animated:YES];
    }else {
        ESPTouchTwoViewController *touch2vc = [[ESPTouchTwoViewController alloc]init];
        [self.navigationController pushViewController:touch2vc animated:YES];
    }
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
