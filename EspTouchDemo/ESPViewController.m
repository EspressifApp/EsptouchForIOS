//
//  ESPViewController.m
//  EspTouchDemo
//
//  Created by 白 桦 on 3/23/15.
//  Copyright (c) 2015 白 桦. All rights reserved.
//

#import "ESPViewController.h"
#import "EspTouch/ESPTouch.h"
#import <KVNProgress/KVNProgress.h>

#define FIELD_SSID @"SSID"
#define FIELD_BSSID @"BSSID"
#define FIELD_PASSWORD @"PASSWORD"
#define FIELD_COUNT @"COUNT"
#define FIELD_MODE @"MODE"

#define ACTION_BTN @"MODE"

#define MODES @[@"BroadCast", @"MultiCast"]


@interface ESPViewController ()
<ESPTouchDelegate>

// to cancel ESPTouchTask when
@property (atomic, strong) ESPTouchTask *_esptouchTask;

// without the condition, if the user tap confirm/cancel quickly enough,
// the bug will arise. the reason is follows:
// 0. task is starting created, but not finished
// 1. the task is cancel for the task hasn't been created, it do nothing
// 2. task is created
// 3. Oops, the task should be cancelled, but it is running
@property (nonatomic, strong) NSCondition *_condition;

/// A dictionnary that will store the form values for us
@property (strong, nonatomic) NSMutableDictionary * valueHolder;

@end

@implementation ESPViewController

@synthesize valueHolder = _valueHolder;

// lazy getter for an empty value dictionnary
- (NSMutableDictionary *)valueHolder
{
    if(!_valueHolder)
    {
        _valueHolder = [@{
                         FIELD_SSID : @"",
                         FIELD_BSSID : @"",
                         FIELD_PASSWORD : @"",
                         FIELD_COUNT : @1,
                         FIELD_MODE : MODES[0]
                         } mutableCopy];
    }
    return _valueHolder;
}

/// Set the base UI
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // initialise the form
    
    XLFormDescriptor * form;
    XLFormSectionDescriptor * section;
    XLFormRowDescriptor * row;
    
    form = [XLFormDescriptor formDescriptorWithTitle:@"EspTouch"];
    
    // First section
    section = [XLFormSectionDescriptor formSection];
    [form addFormSection:section];
    
    // SSID
    row = [XLFormRowDescriptor formRowDescriptorWithTag:FIELD_SSID rowType:XLFormRowDescriptorTypeInfo title:@"Wifi"];
    row.value = self.valueHolder[FIELD_SSID];
    [section addFormRow:row];
    
    // BSSID
    row = [XLFormRowDescriptor formRowDescriptorWithTag:FIELD_BSSID rowType:XLFormRowDescriptorTypeInfo title:@"Wifi BSSID"];
    row.value = self.valueHolder[FIELD_BSSID];
    [section addFormRow:row];
    
    // PASSWORD
    row = [XLFormRowDescriptor formRowDescriptorWithTag:FIELD_PASSWORD rowType:XLFormRowDescriptorTypePassword];
    [row.cellConfigAtConfigure setObject:@"Password" forKey:@"textField.placeholder"];
    row.value = self.valueHolder[FIELD_PASSWORD];
    [section addFormRow:row];
    
    // Second Section
    section = [XLFormSectionDescriptor formSection];
    [section setTitle:@"more options"];
    [form addFormSection:section];
    
    // NB DEVICE
    row = [XLFormRowDescriptor formRowDescriptorWithTag:FIELD_COUNT rowType:XLFormRowDescriptorTypeStepCounter title:@"Number of device"];
    row.value = self.valueHolder[FIELD_COUNT];
    [row.cellConfigAtConfigure setObject:@0 forKey:@"stepControl.minimumValue"];
    [section addFormRow:row];
    
    // MODE {BROADCAST|MULTICAST}
    row = [XLFormRowDescriptor formRowDescriptorWithTag:FIELD_MODE rowType:XLFormRowDescriptorTypeSelectorActionSheet title:@"mode"];
    row.value = self.valueHolder[FIELD_MODE];
    row.selectorOptions = MODES;
    [section addFormRow:row];
    
    section = [XLFormSectionDescriptor formSection];
    [form addFormSection:section];
    
    // START BTN
    row = [XLFormRowDescriptor formRowDescriptorWithTag:ACTION_BTN rowType:XLFormRowDescriptorTypeButton title:@"Start"];
    row.action.formSelector = @selector(start);
    [section addFormRow:row];
    
    // big jump
    section = [XLFormSectionDescriptor formSection];
    [form addFormSection:section];
    
    // VERSION
    row = [XLFormRowDescriptor formRowDescriptorWithTag:@"version" rowType:XLFormRowDescriptorTypeInfo title:@"Version"];
    row.value = ESPTOUCH_VERSION;
    [section addFormRow:row];
    
    self.form = form;
    
    //
    self.title = @"ESP Touch";
    self._condition = [[NSCondition alloc]init];
    [self setModeConfirm:YES];
}

// update the SSID / BSSID field when received from the AppDelegate
- (void)updateDictionnary:(NSDictionary *)netInfos
{
    self.valueHolder[FIELD_SSID] = netInfos[@"SSID"];
    self.valueHolder[FIELD_BSSID] = netInfos[@"BSSID"];
    [[self.form formRowWithTag:FIELD_SSID] setValue:self.valueHolder[FIELD_SSID]];
    [[self.form formRowWithTag:FIELD_BSSID] setValue:self.valueHolder[FIELD_BSSID]];
    [self.tableView reloadData];
}

// Called when the user changed a value of the form, we will just update our dicitonnary with the new value
- (void)formRowDescriptorValueHasChanged:(XLFormRowDescriptor *)formRow oldValue:(id)oldValue newValue:(id)newValue
{
    self.valueHolder[formRow.tag] = newValue;
}

- (void) start
{
    [self setModeConfirm:false];
    
    [KVNProgress showWithStatus:@"please wait"];
    
     NSLog(@"ESPViewController do confirm action...");
    
    NSLog(@"ESPViewController do the execute work...");
    
    [self executeForResultsWithSsid:self.valueHolder[FIELD_SSID]
                              bssid:self.valueHolder[FIELD_BSSID]
                           password:self.valueHolder[FIELD_PASSWORD]
                          taskCount:[self.valueHolder[FIELD_COUNT] intValue]
                          broadcast:[self.valueHolder[FIELD_MODE] isEqualToString:MODES[0]]
                         completion:^(NSArray * esptouchResultArray)
    {
        [KVNProgress dismiss];
        
        [self setModeConfirm:YES];
        
        ESPTouchResult *firstResult = [esptouchResultArray objectAtIndex:0];
        // check whether the task is cancelled and no results received
        if (!firstResult.isCancelled)
        {
            NSMutableString *mutableStr = [[NSMutableString alloc]init];
            NSUInteger count = 0;
            // max results to be displayed, if it is more than maxDisplayCount,
            // just show the count of redundant ones
            const int maxDisplayCount = 5;
            if ([firstResult isSuc])
            {
                
                for (int i = 0; i < [esptouchResultArray count]; ++i)
                {
                    ESPTouchResult *resultInArray = [esptouchResultArray objectAtIndex:i];
                    [mutableStr appendString:[resultInArray description]];
                    [mutableStr appendString:@"\n"];
                    count++;
                    if (count >= maxDisplayCount)
                    {
                        break;
                    }
                }
                
                if (count < [esptouchResultArray count])
                {
                    [mutableStr appendString:[NSString stringWithFormat:@"\nthere's %lu more result(s) without showing\n",(unsigned long)([esptouchResultArray count] - count)]];
                }
                
                [KVNProgress showSuccessWithStatus:mutableStr];
            }
            
            else
            {
                [KVNProgress showErrorWithStatus:@"Esptouch fail"];
            }
        }
    }];
}

- (void) cancel
{
    [KVNProgress dismiss];
    
    [self setModeConfirm:YES];
    
    NSLog(@"ESPViewController do cancel action...");
    
    [self._condition lock];
    if (self._esptouchTask != nil)
    {
        [self._esptouchTask interrupt];
    }
    [self._condition unlock];
}

// The async version of executeForResultsWithSsid . Will perform smartconfig in a separate thread and call completion in the main thread (UI safe)
- (void) executeForResultsWithSsid:(NSString *)apSsid bssid:(NSString *)apBssid password:(NSString *)apPwd taskCount:(int)taskCount broadcast:(BOOL)broadcast completion:(void(^)(NSArray * results))completion
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        [self._condition lock];
        self._esptouchTask = [[ESPTouchTask alloc]initWithApSsid:apSsid andApBssid:apBssid andApPwd:apPwd];
        [self._esptouchTask setEsptouchDelegate:self];
        [self._esptouchTask setPackageBroadcast:broadcast];
        [self._condition unlock];
        NSArray * esptouchResults = [self._esptouchTask executeForResults:taskCount];
        NSLog(@"ESPViewController executeForResult() result is: %@",esptouchResults);
        
        if(completion)
        {
            [self._condition unlock];
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(esptouchResults);
            });
        };
    });
}

// switch button from Confirm to Cancel
- (void)setModeConfirm:(BOOL)isInconfirmMode
{
    XLFormRowDescriptor * btn = [self.form formRowWithTag:ACTION_BTN];
    if(isInconfirmMode)
    {
        [btn setTitle:@"Confirm"];
        btn.action.formSelector = @selector(start);
        [self.tableView reloadData];
    }
    else
    {
        [btn setTitle:@"Cancel"];
        btn.action.formSelector = @selector(cancel);
        [self.tableView reloadData];
    }
}

#pragma mark - ESPTouchTaskDelegate
-(void) onEsptouchResultAddedWithResult: (ESPTouchResult *) result;
{
    NSLog(@"EspTouchDelegateImpl onEsptouchResultAddedWithResult bssid: %@", result.bssid);
    NSString *message = [NSString stringWithFormat:@"%@ is connected to the wifi" , result.bssid];

    dispatch_async(dispatch_get_main_queue(), ^{
        [KVNProgress showSuccessWithStatus:message];
    });

}
@end

