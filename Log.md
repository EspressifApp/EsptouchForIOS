# Update Log

## v0.3.6.1
- Modify bssid post sequence

## v0.3.6.0
- Post bssid data for device

## v0.3.5.4
- Support AES128 encryption
```
    NSString *secretKey = @"1234567890123456"; // TODO use your own key
    ESPAES *aes = [[ESPAES alloc] initWithKey:secretKey];
    ESPTouchTask *task = [[ESPTouchTask alloc]initWithApSsid:apSsid andApBssid:apBssid andApPwd:apPwd andAES:aes];
```

## v0.3.5.3
- isSsidHidden is YES forever

## v0.3.5.2
- Espressif's RTOS SDK Smart Config is updated to v2.5.5
    - Only RTOS-v2.5.5 and above support IPv6 only environment
    - Esptouch v0.3.5.1 only support Espressif's Smart Config v2.4 and above
    - IPv4 is preferred and the old version is compatible
- Fix a bug about check IPv4 address private
- Try to open network permission when launch app after ios10.0 (Fix the bug some ios10.0 later can't use Esptouch)

## v0.3.5.1
- Espressif's RTOS SDK Smart Config is updated to v2.5.5
    - Only RTOS-v2.5.5 and above support IPv6 only environment
    - Esptouch v0.3.5.1 only support Espressif's Smart Config v2.4 and above
    - IPv4 is preferred and the old version is compatible

## v0.3.5.0
- Espressif's Smart Config is updated to v2.4.
    - Esptouch v0.3.5.0 only support Espressif's Smart Config v2.4
- Significant Change
    - Esptouch v0.3.5.0 support IPv6 only environment.
    - IPv4 is preferred and the old version is compatible.

## v0.3.4.3
- Espressif's Smart Config is updated to v2.4.
    - Esptouch v0.3.4.3 only support Espressif's Smart Config v2.4

## v0.3.4.2
- Espressif's Smart Config is updated to v2.4, and some paremeters are changed.
    - Esptouch v0.3.4 only support Espressif's Smart Config v2.4
- ESPTouchDelegate is added. It support callback when new device is connected to wifi.

## v0.3.4.1
- fix the bug when iphone or ipad lock screen while doing esptouch, it will crash when back from lock screen state.
    - thx for the engineer in Lenovo discovery
- Espressif's Smart Config is updated to v2.4, and some paremeters are changed.
    - Esptouch v0.3.4 only support Espressif's Smart Config v2.4

## v0.3.4
- Espressif's Smart Config is updated to v2.4, and some paremeters are changed.
    - Esptouch v0.3.4 only support Espressif's Smart Config v2.4

## v0.3.3
- Espressif's Smart Config is updated to v2.2, and the protocol is changed.
    - Esptouch v0.3.3 only support Espressif's Smart Config v2.2
```
    The usage of v0.3.0 is supported, besides one new API is added:
    (NSArray*) executeForResults:(int) expectTaskResultCount
    The only differece is that it return array, and require expectTaskResultCount
```

## v0.3.2
- Espressif's Smart Config is updated to v2.2, and the protocol is changed.
    - Esptouch v0.3.2 only support Espressif's Smart Config v2.2

## v0.3.1
- Espressif's Smart Config is updated to v2.1, and the protocol is changed.
    - Esptouch v0.3.1 only support Espressif's Smart Config v2.1
- fix some bugs in v0.3.0

## v0.3.0
- Espressif's Smart Config is updated to v2.1, and the protocol is changed.
    - Esptouch v0.3.0 only support Espressif's Smart Config v2.1
```
    // build esptouch task
    NSString *apSsid = @"wifi-1";
    NSString *apBssid = @"12:34:56:78:9a:bc";
    NSString *apPwd = @"1234567890";
    BOOL isSsidHidden = NO;// whether the Ap's ssid is hidden, it is NO usually
    ESPTouchTask *task = [[ESPTouchTask alloc]initWithApSsid:apSsid
                                                  andApBssid:apBssid
                                                    andApPwd:apPwd
                                        andIsSsidHiden:isSsidHidden];
    // if you'd like to determine the timeout by yourself, use the follow:
    int timeoutMillisecond = 58000;// it should >= 18000, 58000 is default
    ESPTouchTask *task = [[ESPTouchTask alloc]initWithApSsid:apSsid
                                                  andApBssid:apBssid
                                                    andApPwd:apPwd
                                        andIsSsidHiden:isSsidHidden
                            andTimeoutMillisecond:timeoutMillisecond];
    // execute for result
    ESPTouchResult *esptouchReult = [task executeForResult];
    // <b>note: one task can't executed more than once:</b>
    ESPTouchTask *esptouchTask = [[ESPTouchTask alloc]initXXX...];
    // wrong usage, which shouldn't happen
    {
        [esptouchTask executeForResult];
        [esptouchTask executeForResult];
    }
    // correct usage
    {
        [esptouchTask executeForResult];
        EsptouchTask *esptouchTask = [[ESPTouchTask alloc]initXXX...];
        [esptouchTask executeForResult];
    }
``` 

## v0.2.2
-  add isCancelled API in ESPTouchTask and ESPTouchResult to check whether the task is cancelled by user directly.

## v0.2.1
- fix the bug when SSID char is more than one byte value(0xff), esptouch will fail forever
    - thx for the engineer in NATop YoungYang's discovery
- the encoding charset could be set, the default one is "NSUTF8StringEncoding"
    - change the macro ESPTOUCH_NSStringEncoding in ESP_ByteUtil.h
    - It will lead to ESPTOUCH fail for wrong CHARSET is set.
    - Whether the CHARSET is correct is depend on the phone or pad.
    - More info and discussion please refer to http://bbs.espressif.com/viewtopic.php?f=8&t=397)

## v0.2.0
- add check valid mechanism to forbid such situation:
```    
    NSString *apSsid = @"";// or apSsid = null
    NSString *apPassword = @"pwd";
    EsptouchTask *esptouchTask = [[ESPTouchTask alloc] initWithApSsid:apSsid andApPwd:apPwd]; 
```
- add check whether the task is executed to forbid such situation
    - thx for the engineer in smartline YuguiYu's proposal
```
    NSString *apSsid = @"ssid";
    NSString *apPassword = @"pwd";
    EsptouchTask *esptouchTask = [[ESPTouchTask alloc] initWithApSsid:apSsid andApPwd:apPwd]; 
    // wrong usage, which shouldn't happen
    {
        [esptouchTask execute];
        [esptouchTask execute];
    }
    // correct usage
    {
        [esptouchTask execute];
        EsptouchTask *esptouchTask = [[ESPTouchTask alloc] initWithApSsid:apSsid andApPwd:apPwd]; 
        [esptouchTask execute];
    }
```

## v0.1.9
- fix some old bugs in the App
- Add new Interface of Esptouch task( Smart Configure must v1.1 to support it)
```
    The usage of it is like this:
    // create the Esptouch task
    EsptouchTask *esptouchTask = [[ESPTouchTask alloc]initWithApSsid:apSsid andApPwd:apPwd]; 
    // execute syn util it suc or timeout
    EsptouchResult *result = [esptouchTask executeForResult];
    // check whehter the execute is suc
    BOOL isSuc = result.isSuc;
    // get the device's bssid, the format of the bssid is like this format: @"18fe3497f310"
    NSString *bssid = result.bssid;
    // when you'd like to interrupt it, just call the method below, and [esptouchTask execute] will return NO after it:
    [esptouchTask interrupt];
```

## v0.1.7
- The entrance of the Demo is ESPViewController.m
- EsptouchTask.h is the interface of Esptouch task.
```
    The usage of it is like this:
    // create the Esptouch task
    EsptouchTask *esptouchTask = [[ESPTouchTask alloc] initWithApSsid:apSsid andApPwd:apPwd]; 
    // execute syn util it suc or timeout
    BOOL result = [esptouchTask execute];
    // when you'd like to interrupt it, just call the method below, and [esptouchTask execute] will return NO after it:
    [esptouchTask interrupt];
``` 
- The abstract interface is in the group esptouch
- More info about the EspTouch Demo, please read the source code and annotation
