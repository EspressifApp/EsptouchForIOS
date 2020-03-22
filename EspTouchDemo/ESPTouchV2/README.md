# EspTouch V2

## Example
- [example](../UI/V2/)

## APIs
- The provisioner delegate
  ```Objective-C
  @protocol ESPProvisionerDelegate <NSObject>

  @optional

  - (void)onSyncStart;

  - (void)onSyncStop;

  - (void)onSyncError:(NSException *)exception;

  - (void)onProvisionStart;

  - (void)onProvisionStop;

  - (void)onProvisonScanResult:(ESPProvisionResult *)result;

  - (void)onProvisionError:(NSException *)exception;

  @end
  ```

- Start send Sync packets
  ```Objective-C
  [[ESPProvisioner share] startSyncWithDelegate:delegate]; // delegate is nullable.
  ```

- Stop send Sync packets
    - Provison task will run for one minute
  ```Objective-C
  [[ESPProvisioner share] stopSync];
  ```

- Start provision
  ```Objective-C
  ESPProvisionRequest *request = [[ESPProvisionRequest alloc] init];
  request.ssid = []; // AP's SSID data, nullable
  request.password = []; // AP's BSSID data, nonnull
  request.bssid = []; // AP's password data, nullable if the AP is open
  request.reservedData = []; // User's custom data, nullable. If not null, the max length is 127
  request.aesKey = @"1234567890123456"; // nullable, if not null, it must be 16 bytes. App developer should negotiate an AES key with Device developer first.
    
  [[ESPProvisioner share] startProvision:request withDelegate:delegate]; // delegate is nullable
  ```

- Stop provision
  ```Objective-C
  [[ESPProvisioner share] stopProvision];
  ```