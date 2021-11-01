# EspTouch V2

## Example
- [example](../UI/V2/)

## APIs
- Get provisioner instance
  ```Objective-C
  ESPProvisioner *provisioner = [ESPProvisioner share];
  ```

- The provisioner delegate
  ```Objective-C
  @protocol ESPProvisionerDelegate <NSObject>

  @optional

  - (void)onSyncStart;

  - (void)onSyncStop;

  - (void)onSyncError:(NSException *)exception;

  - (void)onProvisioningStart;

  - (void)onProvisioningStop;

  - (void)onProvisoningScanResult:(ESPProvisionResult *)result;

  - (void)onProvisioningError:(NSException *)exception;

  @end
  ```

- Start send Sync packets
  ```Objective-C
  [provisioner startSyncWithDelegate:delegate]; // delegate is nullable.
  ```

- Stop send Sync packets
  ```Objective-C
  [provisioner stopSync];
  ```

- Start provisioning
    - Provison task will run for 90 seconds
  ```Objective-C
  ESPProvisioningRequest *request = [[ESPProvisioningRequest alloc] init];
  request.ssid = []; // AP's SSID data, nullable
  request.password = []; // AP's BSSID data, nonnull
  request.bssid = []; // AP's password data, nullable if the AP is open
  request.reservedData = []; // User's custom data, nullable. If not null, the max length is 64
  request.aesKey = @"1234567890123456"; // nullable, if not null, it must be 16 bytes. App developer should negotiate an AES key with Device developer first.
    
  [provisioner startProvisioning:request withDelegate:delegate]; // delegate is nullable
  ```

- Stop provisioning
  ```Objective-C
  [provisioner stopProvisioning];
  ```
