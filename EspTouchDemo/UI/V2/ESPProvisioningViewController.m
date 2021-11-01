//
//  ESPProvisioningViewController.m
//  EspTouchDemo
//
//  Created by AE on 2020/3/2.
//  Copyright © 2020 Espressif. All rights reserved.
//

#import "ESPProvisioningViewController.h"
#import "ESPProvisioner.h"
#import "ESPProvisioningRequest.h"
#import "ESPProvisioningResult.h"

#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height
#define statusHeight [[UIApplication sharedApplication] statusBarFrame].size.height
#define TabBarHeight ([[UIApplication sharedApplication] statusBarFrame].size.height>20.1?34.0:0.0)
@interface ESPProvisioningViewController ()<UITableViewDelegate, UITableViewDataSource, ESPProvisionerDelegate>

@property(strong, nonatomic)UIActivityIndicatorView *progressView;
@property(strong, nonatomic)UILabel *messageView;

@property(strong, nonatomic)UITableView *resultView;
@property(strong, nonatomic)NSMutableArray<ESPProvisioningResult *> *resultArray;

@property(strong, nonatomic)UIButton *stopBtn;

@property(strong, nonatomic)ESPProvisioningRequest *request;

@property(assign, nonatomic)BOOL isDarkStyle;

@end

@implementation ESPProvisioningViewController

- (instancetype)initWithProvisionRequest:(ESPProvisioningRequest *)request {
    self = [super init];
    if (self) {
        _request = request;
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationItem.title = NSLocalizedString(@"EspProvision-Titile", nil);
    
    CGFloat headHeight = statusHeight + 60;
    CGFloat contentWidth = SCREEN_WIDTH - 40;
    CGFloat contentHeight = SCREEN_HEIGHT - headHeight - TabBarHeight;
    UIView *contentView = [[UIView alloc]initWithFrame:CGRectMake(20, headHeight, contentWidth, contentHeight)];
    [self.view addSubview:contentView];
    
    self.messageView = [[UILabel alloc] init];
    self.messageView.frame = CGRectMake(0, 0, contentWidth, 30);
    self.messageView.accessibilityLabel = self.messageView.text;
    self.messageView.accessibilityIdentifier = @"messageViewId";
    [contentView addSubview:self.messageView];
    
    self.progressView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.progressView.frame = CGRectMake(contentWidth / 2 - 15, 0, 30, 30);
    [contentView addSubview:self.progressView];
    
    self.stopBtn = [[UIButton alloc] init];
    self.stopBtn.frame = CGRectMake(0, contentHeight - 40, contentWidth, 35);
    [self.stopBtn setTitleColor:[UIColor colorWithRed:0/255.0 green:111/255.0 blue:255/255.0 alpha:1] forState:UIControlStateNormal];
    self.stopBtn.accessibilityIdentifier = @"Stop button";
    self.stopBtn.accessibilityLabel = @"confirmStopBtnId";
    [self.stopBtn setTitleColor:[UIColor grayColor] forState:UIControlStateDisabled];
    [self.stopBtn addTarget:self action:@selector(cancelProvision:) forControlEvents:UIControlEventTouchUpInside];
    [self.stopBtn setTitle:NSLocalizedString(@"EspProvision-stop", nil) forState:UIControlStateNormal];
    [contentView addSubview:self.stopBtn];
    
    self.resultArray = [[NSMutableArray alloc] init];
    self.resultView = [[UITableView alloc] init];
    self.resultView.accessibilityIdentifier = @"Result list";
    self.resultView.accessibilityLabel = @"resultViewListId";
    self.resultView.frame = CGRectMake(0, 35, contentWidth, contentHeight - 35 - 45);
    self.resultView.delegate = self;
    self.resultView.dataSource = self;
    self.resultView.scrollEnabled = YES;
    [contentView addSubview:self.resultView];
    
    self.isDarkStyle = NO;
    if (@available(iOS 13.0, *)) {
        if (self.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
            self.isDarkStyle = YES;
        }
    }
    if (self.isDarkStyle) {
        self.progressView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhite;
        self.messageView.textColor = [UIColor whiteColor];
    } else {
        self.progressView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
        self.messageView.textColor = [UIColor blackColor];
    }
    
    [self showProgress:YES];
    [self startProvisioning];
}

- (void)viewWillDisappear:(BOOL)animated {
    NSLog(@"Provision viewWillDisappear");
    [self stopProvisioning:nil];
}

- (void)showProgress:(BOOL)show {
    if (show) {
        [self.progressView startAnimating];
    } else {
        [self.progressView stopAnimating];
    }
}

- (void)cancelProvision:(UIButton *)sender {
    [self stopProvisioning:nil];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.resultArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellID = @"cellID";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (cell == nil) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
        cell.textLabel.numberOfLines = 2;
        cell.textLabel.textColor = self.isDarkStyle ? [UIColor whiteColor] : [UIColor blackColor];
    }
    ESPProvisioningResult *result = self.resultArray[indexPath.row];
    cell.textLabel.text = [NSString stringWithFormat:@"bssid: %@\naddress: %@", result.bssid, result.address];
    cell.accessibilityIdentifier = @"resultCellId";
    cell.accessibilityLabel = cell.textLabel.text;

    return cell;
}

- (void)startProvisioning {
    [[ESPProvisioner share] startProvisioning:self.request withDelegate:self];
}

- (void)stopProvisioning:(NSException *)exception {
    [[ESPProvisioner share] stopProvisioning];
    [self.stopBtn setEnabled:NO];
    [self showProgress:NO];
    if (exception) {
        self.messageView.text = NSLocalizedString(@"EspProvision-exception-message", nil);
    } else if (self.resultArray.count == 0) {
        self.messageView.text = NSLocalizedString(@"EspProvision-no-result-message", nil);
    } else {
        self.messageView.text = @"";
    }
}

- (void)onProvisioningStart {
    NSLog(@"onProvisionStart");
}

- (void)onProvisioningStop {
    NSLog(@"onProvisionStop");
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self stopProvisioning:nil];
    }];
}

- (void)onProvisioningError:(NSException *)exception {
    NSLog(@"onProvisionError: %@", exception);
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self stopProvisioning:exception];
    }];
}

- (void)onProvisoningScanResult:(ESPProvisioningResult *)result {
    NSLog(@"onProvisonScanResult: address=%@, bssid=%@", result.address, result.bssid);
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self.resultArray addObject:result];
        [self.resultView reloadData];
        
        if ([self.request.deviceCount intValue] > 0) {
            // check result array size == expect size
            if (self.resultArray.count >= [self.request.deviceCount intValue]) {
                [self stopProvisioning:nil];
            }
        }
    }];
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
