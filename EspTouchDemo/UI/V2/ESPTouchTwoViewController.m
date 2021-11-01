//
//  ESPTouchTwoViewController.m
//  EspTouchDemo
//
//  Created by fanbaoying on 2019/12/3.
//  Copyright © 2019 Espressif. All rights reserved.
//

#import "ESPTouchTwoViewController.h"
#import "ESPViewController.h"
#import "UILabel+LabelHeightAndWidth.h"
#import "ESPTools.h"
#import "ESPProvisioningViewController.h"

#import "ESPProvisioner.h"
#import "AFNetworking.h"
#import "ESP_ByteUtil.h"
#import "ESP_NetUtil.h"

#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height
#define statusHeight [[UIApplication sharedApplication] statusBarFrame].size.height
#define TabBarHeight ([[UIApplication sharedApplication] statusBarFrame].size.height>20.1?34.0:0.0)
@interface ESPTouchTwoViewController ()<UITextFieldDelegate, ESPProvisionerDelegate>

@property(strong, nonatomic)UILabel *ssidTitle;
@property(strong, nonatomic)UILabel *ssidContentLab;
@property(strong, nonatomic)UILabel *bssidTitle;
@property(strong, nonatomic)UILabel *bssidContentLab;
@property(strong, nonatomic)UILabel *pwdTitle;
@property(strong, nonatomic)UITextField *pwdContentTextField;
@property(strong, nonatomic)UILabel *deviceCountTitle;
@property(strong, nonatomic)UITextField *deviceCountTextField;
@property(strong, nonatomic)UILabel *aesKeyTitle;
@property(strong, nonatomic)UITextField *aesKeyContentTextField;
@property(strong, nonatomic)UILabel *customDataTitle;
@property(strong, nonatomic)UITextField *customDataContentTextField;
@property(strong, nonatomic)UILabel *messageView;
@property(strong, nonatomic)UIButton *confirmBtn;
@property(strong, nonatomic)UILabel *versionLab;
@property(strong, nonatomic)UIButton *pwdTextSwitchBtn;
@property(strong, nonatomic)UIButton *aesKeySwitchBtn;

@property(strong, nonatomic)NSDictionary *netInfo;

@property(strong, nonatomic)NSOperation *onSyncStopOp;

@end

@implementation ESPTouchTwoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.navigationItem.title = NSLocalizedString(@"EspTouchV2-Title", nil);
    //程序进入前台并处于活动状态调用
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(wifiViewUpdates) name:UIApplicationDidBecomeActiveNotification object:nil];
    //注册Wi-Fi变化通知
    AFNetworkReachabilityManager *manager = [AFNetworkReachabilityManager sharedManager];
    [manager startMonitoring];
    [manager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        [self wifiViewUpdates];
    }];
    
    [self versionTwoViewUI];
    [self checkWiFi];
//    [[ESPProvisioner share] startSync];
}

- (void)versionTwoViewUI {
    self.netInfo = [self fetchNetInfo];
    
    const CGFloat contentWidth = SCREEN_WIDTH - 40;
    const CGFloat contentHeight = SCREEN_HEIGHT - statusHeight - 60 - TabBarHeight - 80;
    UIView *contentView = [[UIView alloc]initWithFrame:CGRectMake(20, statusHeight + 60, contentWidth, contentHeight)];
    [self.view addSubview:contentView];
    
    self.ssidTitle = [[UILabel alloc]init];
    self.ssidTitle.text = NSLocalizedString(@"EspTouchV2-SSID", nil);
    [contentView addSubview:_ssidTitle];
    CGFloat SsidWith = [UILabel getWidthWithTitle:_ssidTitle.text font:_ssidTitle.font];
    self.ssidTitle.frame = CGRectMake(0, 0, SsidWith, 30);
    
    self.ssidContentLab = [[UILabel alloc]initWithFrame:CGRectMake(SsidWith + 5, 0, contentView.bounds.size.width - SsidWith - 5, 30)];
    self.ssidContentLab.text = [_netInfo objectForKey:@"ssid"];
    self.ssidContentLab.accessibilityIdentifier = @"ssidIdentifier";
    self.ssidContentLab.accessibilityLabel = self.ssidContentLab.text;
    [contentView addSubview:_ssidContentLab];
    
    self.bssidTitle = [[UILabel alloc]init];
    self.bssidTitle.text = NSLocalizedString(@"EspTouchV2-BSSID", nil);
    [contentView addSubview:_bssidTitle];
    CGFloat BssidWith = [UILabel getWidthWithTitle:_bssidTitle.text font:_bssidTitle.font];
    self.bssidTitle.frame = CGRectMake(0, 35, BssidWith, 30);
    
    self.bssidContentLab = [[UILabel alloc]initWithFrame:CGRectMake(BssidWith + 5, 35, contentView.bounds.size.width - BssidWith - 5, 30)];
    self.bssidContentLab.text = [_netInfo objectForKey:@"bssid"];
    self.bssidContentLab.accessibilityIdentifier = @"bssidIdentifier";
    self.bssidContentLab.accessibilityLabel = self.bssidContentLab.text;
    [contentView addSubview:_bssidContentLab];
    
    self.pwdTitle = [[UILabel alloc]init];
    self.pwdTitle.text = NSLocalizedString(@"EspTouchV2-Password", nil);
    [contentView addSubview:_pwdTitle];
    CGFloat PwdWith = [UILabel getWidthWithTitle:_pwdTitle.text font:_pwdTitle.font];
    self.pwdTitle.frame = CGRectMake(0, 80, PwdWith, 35);
    
    self.pwdContentTextField = [[UITextField alloc]initWithFrame:CGRectMake(PwdWith + 5, 75, contentView.bounds.size.width - PwdWith - 5, 45)];
    self.pwdContentTextField.accessibilityIdentifier = @"wifiPassword";
    self.pwdContentTextField.accessibilityLabel = self.pwdContentTextField.text;
    self.pwdContentTextField.borderStyle = UITextBorderStyleRoundedRect;
    self.pwdContentTextField.delegate = self;
    self.pwdContentTextField.secureTextEntry = YES;
    self.pwdContentTextField.keyboardType = UIKeyboardTypeASCIICapable;
    [contentView addSubview:_pwdContentTextField];
    
    self.pwdTextSwitchBtn = [[UIButton alloc]initWithFrame:CGRectMake(self.pwdContentTextField.bounds.size.width + PwdWith - 35, 80, 35, 35)];
    [_pwdTextSwitchBtn setImage:[UIImage imageNamed:@"eyeClose"] forState:0];
    [_pwdTextSwitchBtn addTarget:self action:@selector(pwdTextSwitch:) forControlEvents:UIControlEventTouchUpInside];
    [contentView addSubview:_pwdTextSwitchBtn];
    
    self.deviceCountTitle = [[UILabel alloc]init];
    self.deviceCountTitle.text = NSLocalizedString(@"EspTouchV2-deviceCount", nil);
    [contentView addSubview:_deviceCountTitle];
    CGFloat DCWith = [UILabel getWidthWithTitle:_deviceCountTitle.text font:_deviceCountTitle.font];
    self.deviceCountTitle.frame = CGRectMake(0, 135, DCWith, 35);
    
    self.deviceCountTextField = [[UITextField alloc]initWithFrame:CGRectMake(DCWith + 5, 130, contentView.bounds.size.width - DCWith - 5, 45)];
    self.deviceCountTextField.accessibilityIdentifier = @"deviceCount";
    self.deviceCountTextField.accessibilityLabel = self.pwdContentTextField.text;
    self.deviceCountTextField.borderStyle = UITextBorderStyleRoundedRect;
    self.deviceCountTextField.delegate = self;
    self.deviceCountTextField.keyboardType = UIKeyboardTypeNumberPad;
    [contentView addSubview:_deviceCountTextField];
    
    self.aesKeyTitle = [[UILabel alloc] init];
    self.aesKeyTitle.text = NSLocalizedString(@"EspTouchV2-AES-Key", nil);
    [contentView addSubview:_aesKeyTitle];
    CGFloat AESKeyWith = [UILabel getWidthWithTitle:_aesKeyTitle.text font:_aesKeyTitle.font];
    self.aesKeyTitle.frame = CGRectMake(0, 190, AESKeyWith, 35);
    
    self.aesKeyContentTextField = [[UITextField alloc] initWithFrame:CGRectMake(AESKeyWith + 5, 185, contentView.bounds.size.width - AESKeyWith - 5, 45)];
    self.aesKeyContentTextField.accessibilityIdentifier = @"aesKeyContent";
    self.aesKeyContentTextField.accessibilityLabel = self.aesKeyContentTextField.text;
    self.aesKeyContentTextField.borderStyle = UITextBorderStyleRoundedRect;
    self.aesKeyContentTextField.delegate = self;
    self.aesKeyContentTextField.secureTextEntry = YES;
    self.aesKeyContentTextField.keyboardType = UIKeyboardTypeASCIICapable;
    [contentView addSubview:_aesKeyContentTextField];
    
    self.aesKeySwitchBtn = [[UIButton alloc]initWithFrame:CGRectMake(self.aesKeyContentTextField.bounds.size.width + AESKeyWith - 35, 190, 35, 35)];
    [_aesKeySwitchBtn setImage:[UIImage imageNamed:@"eyeClose"] forState:0];
    [_aesKeySwitchBtn addTarget:self action:@selector(aesKeyTextSwitch:) forControlEvents:UIControlEventTouchUpInside];
    [contentView addSubview:_aesKeySwitchBtn];
    
    self.customDataTitle = [[UILabel alloc] init];
    self.customDataTitle.text = NSLocalizedString(@"EspTouchV2-Custom-Data", nil);
    [contentView addSubview:_customDataTitle];
    CGFloat CustomDataWith = [UILabel getWidthWithTitle:_customDataTitle.text font:_customDataTitle.font];
    self.customDataTitle.frame = CGRectMake(0, 245, CustomDataWith, 35);
    
    self.customDataContentTextField = [[UITextField alloc] initWithFrame:CGRectMake(CustomDataWith + 5, 240, contentView.bounds.size.width - CustomDataWith - 5, 45)];
    self.customDataContentTextField.accessibilityIdentifier = @"customDataContent";
    self.customDataContentTextField.accessibilityLabel = self.customDataContentTextField.text;
    self.customDataContentTextField.borderStyle = UITextBorderStyleRoundedRect;
    self.customDataContentTextField.delegate = self;
    self.customDataContentTextField.keyboardType = UIKeyboardTypeDefault;
    [contentView addSubview:_customDataContentTextField];
    
    self.messageView = [[UILabel alloc] initWithFrame:CGRectMake(0, 205, contentWidth, 50)];
    self.messageView.numberOfLines = 2;
    self.messageView.textColor = [UIColor redColor];
    [contentView addSubview:_messageView];
    
    self.confirmBtn = [[UIButton alloc]initWithFrame:CGRectMake(20, SCREEN_HEIGHT - TabBarHeight - 70, SCREEN_WIDTH - 40, 35)];
    self.confirmBtn.accessibilityIdentifier = @"confirmCancelBtnId";
    [self.confirmBtn setTitleColor:[UIColor colorWithRed:0/255.0 green:111/255.0 blue:255/255.0 alpha:1] forState:0];
    [self.confirmBtn setTitleColor:[UIColor grayColor] forState:UIControlStateDisabled];
    [self.confirmBtn setTitle:NSLocalizedString(@"EspTouchV2-confirm", nil) forState:UIControlStateNormal];
    [self.confirmBtn addTarget:self action:@selector(confirmProvision:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_confirmBtn];
    
    // 版本号
    self.versionLab = [[UILabel alloc]initWithFrame:CGRectMake(20, SCREEN_HEIGHT - TabBarHeight - 30, SCREEN_WIDTH - 40, 30)];
    self.versionLab.textColor = [UIColor blackColor];
    NSString *currentVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    self.versionLab.text = [NSString stringWithFormat:@"APP-v%@ / %@",currentVersion, ESPTOUCH_V2_VERSION];
    [self.view addSubview:_versionLab];
}

- (void)pwdTextSwitch:(UIButton *)sender {
    sender.selected = !sender.selected;
    if (sender.selected) {
        [_pwdTextSwitchBtn setImage:[UIImage imageNamed:@"eyeOpen"] forState:0];
        _pwdContentTextField.secureTextEntry = NO;
    } else {
        [_pwdTextSwitchBtn setImage:[UIImage imageNamed:@"eyeClose"] forState:0];
        _pwdContentTextField.secureTextEntry = YES;
    }
}
- (void)aesKeyTextSwitch:(UIButton *)sender {
    sender.selected = !sender.selected;
    if (sender.selected) {
        [_aesKeySwitchBtn setImage:[UIImage imageNamed:@"eyeOpen"] forState:0];
        _aesKeyContentTextField.secureTextEntry = NO;
    } else {
        [_aesKeySwitchBtn setImage:[UIImage imageNamed:@"eyeClose"] forState:0];
        _aesKeyContentTextField.secureTextEntry = YES;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [self systemLightAndDark];
}

- (void)viewDidAppear:(BOOL)animated {
    NSLog(@"EspTouchV2 viewDidAppear");
    _onSyncStopOp = nil;
    [[ESPProvisioner share] startSyncWithDelegate:self];
}

- (void)viewWillDisappear:(BOOL)animated {
    NSLog(@"EspTouchV2 viewWillDisappear");
    _onSyncStopOp = nil;
    [[ESPProvisioner share] stopSync];
}

- (void)confirmProvision:(UIButton *)sender {
    NSString *apSsid = self.ssidContentLab.text;
    NSString *apPwd = self.pwdContentTextField.text;
    NSString *apBssid = self.bssidContentLab.text;
    NSString *aesKey = self.aesKeyContentTextField.text;
    NSString *customData = self.customDataContentTextField.text;
    NSString *deviceCount = _deviceCountTextField.text;
    if ([deviceCount isEqualToString:@""]) {
        deviceCount = @"0";
    }
    
    ESPProvisioningRequest *request = [[ESPProvisioningRequest alloc] init];
    request.ssid = [ESP_ByteUtil getBytesByNSString:apSsid];
    request.password = [ESP_ByteUtil getBytesByNSString:apPwd];
    request.bssid = [ESP_NetUtil parseBssid2bytes:apBssid];
    request.deviceCount = deviceCount;
    request.aesKey = aesKey;
    request.reservedData = [ESP_ByteUtil getBytesByNSString:customData];
    
    if (request.reservedData.length > 64) {
        self.messageView.text = NSLocalizedString(@"EspTouchV2-custom-data-length-message", nil);
        return;
    } else {
        self.messageView.text = @"";
    }
    
    [_confirmBtn setEnabled:false];
    _onSyncStopOp = [NSBlockOperation blockOperationWithBlock:^{
        [self.confirmBtn setEnabled:YES];
        ESPProvisioningViewController *provVC = [[ESPProvisioningViewController alloc] initWithProvisionRequest:request];
        [self.navigationController pushViewController:provVC animated:YES];
    }];
    if ([[ESPProvisioner share] isSyncing]) {
        [[ESPProvisioner share] stopSync];
    } else {
        [_onSyncStopOp start];
    }
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
    self.ssidTitle.textColor = [UIColor blackColor];
    self.ssidContentLab.textColor = [UIColor blackColor];
    self.bssidTitle.textColor = [UIColor blackColor];
    self.bssidContentLab.textColor = [UIColor blackColor];
    self.pwdTitle.textColor = [UIColor blackColor];
    self.aesKeyTitle.textColor = [UIColor blackColor];
    self.customDataTitle.textColor = [UIColor blackColor];
    self.versionLab.textColor = [UIColor blackColor];
}

- (void)systemDark {
    self.view.backgroundColor = [UIColor blackColor];
    self.ssidTitle.textColor = [UIColor whiteColor];
    self.ssidContentLab.textColor = [UIColor whiteColor];
    self.bssidTitle.textColor = [UIColor whiteColor];
    self.bssidContentLab.textColor = [UIColor whiteColor];
    self.pwdTitle.textColor = [UIColor whiteColor];
    self.aesKeyTitle.textColor = [UIColor whiteColor];
    self.customDataTitle.textColor = [UIColor whiteColor];
    self.versionLab.textColor = [UIColor whiteColor];
}

- (void)wifiViewUpdates {
    [self systemLightAndDark];
    self.netInfo = [self fetchNetInfo];
    dispatch_async(dispatch_get_main_queue(), ^(){
        self.ssidContentLab.text = [self.netInfo objectForKey:@"ssid"];
        self.bssidContentLab.text = [self.netInfo objectForKey:@"bssid"];
        [self checkWiFi];
    });
}

- (void)checkWiFi {
    NSString *bssid = self.bssidContentLab.text;
    if (!bssid || bssid.length == 0) {
        // No Wi-Fi connection
        [self.confirmBtn setEnabled:NO];
        self.messageView.text = NSLocalizedString(@"EspTouchV2-no-wifi-message", nil);
    } else {
        [self.confirmBtn setEnabled:YES];
        self.messageView.text = @"";
    }
}

- (NSDictionary *)fetchNetInfo {
    NSMutableDictionary *wifiDic = [NSMutableDictionary dictionaryWithCapacity:2];
    wifiDic[@"ssid"] = ESPTools.getCurrentWiFiSsid;
    wifiDic[@"bssid"] = ESPTools.getCurrentBSSID;
    return wifiDic;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}

- (void)onSyncStart {
    NSLog(@">>> onSyncStart");
}

- (void)onSyncError:(NSException *)exception {
    NSLog(@">>> onSyncError: %@", exception);
    [[ESPProvisioner share] stopSync];
}

- (void)onSyncStop {
    NSLog(@">>> onSyncStop");
    if (_onSyncStopOp) {
        NSOperation *op = _onSyncStopOp;
        [[NSOperationQueue mainQueue] addOperation:op];
        _onSyncStopOp = nil;
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
