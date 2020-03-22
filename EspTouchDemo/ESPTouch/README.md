# EspTouch

## Example
- [example](../UI/V1/)

## APIs
- Create task instance
  ```Objective-C
  ESPTouchTask *task = [[ESPTouchTask alloc] initWithApSsid:apSsid andApBssid:apBssid andApPwd:apPwd];
  [task setEsptouchDelegate:delegate]; // Set result callback
  [Task setPackageBroadcast:YES]; // if YES send broadcast packets, else send multicast packets
  ```

- Execute task
  ```Objective-C
  int expectCount = 1;
  NSArray * results = [task executeForResults:expectCount];
  ESPTouchResult *first = [results objectAtIndex:0];
  if (first.isCancelled) {
      // User cancel the task
      return;
  }
  if (first.isSuc) {
      // EspTouch successfully
  }
  ```

- Cancel task
  ```Objective-C
  [task interrupt];
  ```