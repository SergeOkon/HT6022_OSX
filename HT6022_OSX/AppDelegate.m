//
//  AppDelegate.m
//  ht6022
//
//  Created by Serge on 2014-07-04.
//  Copyright (c) 2014 SergeOkon. All rights reserved.
//

#import "AppDelegate.h"
#include "HT6022.h"
#import "Graph.h"

@interface AppDelegate()

@property (nonatomic) HT6022_DeviceTypeDef device;

@property (nonatomic) unsigned char* CH1;
@property (nonatomic) unsigned char* CH2;

// Graph & status
@property (weak) IBOutlet NSTextField *lbStatus;
@property (weak) IBOutlet Graph *graph;

// Trigger settings
@property (weak) IBOutlet NSSlider *sliderTriggerLevel;
@property (weak) IBOutlet NSSlider *sliderTriggerOffset;
@property (weak) IBOutlet NSButton *checkTriggerOnUp;
@property (weak) IBOutlet NSButton *checkTriggerOnDown;

// Radio Buttons
@property (weak) IBOutlet NSMatrix *radioSampleSpeed;
@property (weak) IBOutlet NSMatrix *radioCH1range;
@property (weak) IBOutlet NSMatrix *radioCH2range;


@end


@implementation AppDelegate


-(void) initStep2
{
    // Init the device with firmware uploaded
    NSInteger result = HT6022_DeviceOpen(&_device);
    NSString* status = [NSString stringWithFormat:@"HT6022_DeviceOpen retured %ld", (long) result];
    [self.lbStatus setStringValue:status];
    if (result != 0) return;
    
    // Set up the initial values
    [self.radioSampleSpeed selectCellAtRow:4 column:0];
    [self changeSampleRate:self.radioSampleSpeed];
    [self.radioCH1range selectCellAtRow:0 column:0];
    [self changeCH1range:self.radioCH1range];
    [self.radioCH2range selectCellAtRow:0 column:0];
    [self changeCH2range:self.radioCH2range];
    
    [self.graph setHorizontalGridDivisions:4];
    
    
    // Start a timer to draw the graph
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self drawCallback];
    });
}


- (IBAction)changeSampleRate:(id)sender {
    
    //
    HT6022_SRTypeDef rate;
    switch (self.radioSampleSpeed.selectedRow) {
        case 0: rate = HT6022_24MSa; break;
        case 1: rate = HT6022_16MSa; break;
        case 2: rate = HT6022_8MSa;  break;
        case 3: rate = HT6022_4MSa;  break;
        case 4: rate = HT6022_1MSa;  break;
        case 5: rate = HT6022_500KSa; break;
        case 6: rate = HT6022_200KSa; break;
        case 7: rate = HT6022_100KSa; break;
        default: rate = HT6022_1MSa;
    }
    
    // Set the sampling rate
    NSInteger result = HT6022_SetSR(&_device, rate);
    NSString* status = [NSString stringWithFormat:@"HT6022_SetSR retured %ld", (long) result];
    [self.lbStatus setStringValue:status];
    if (result != 0) return;
}

-(HT6022_IRTypeDef) getIRFromIndex:(NSInteger) index
{
    switch(index) {
        case 0: return HT6022_10V;
        case 1: return HT6022_5V;
        case 2: return HT6022_2V;
        case 3: return HT6022_1V;
        default: return HT6022_10V;
    }
}

- (IBAction)changeCH1range:(id)sender {
    NSInteger result = HT6022_SetCH1IR(&_device, [self getIRFromIndex:self.radioCH1range.selectedRow]);
    NSString* status = [NSString stringWithFormat:@"HT6022_SetCH1IR retured %ld", (long) result];
    [self.lbStatus setStringValue:status];
}

- (IBAction)changeCH2range:(id)sender {
    NSInteger result = HT6022_SetCH2IR(&_device, [self getIRFromIndex:self.radioCH2range.selectedRow]);
    NSString* status = [NSString stringWithFormat:@"HT6022_SetCH2IR retured %ld", (long) result];
    [self.lbStatus setStringValue:status];
}


- (IBAction)checkOnUp:(id)sender
{
    if (self.checkTriggerOnUp.state == 1) {
        [self.checkTriggerOnDown setState:0];
        [self.checkTriggerOnUp setState:1];
    } else {
        [self.checkTriggerOnDown setState:0];
        [self.checkTriggerOnUp setState:0];
    }
}

- (IBAction)checkOnDown:(id)sender {
    if (self.checkTriggerOnDown.state == 1) {
        [self.checkTriggerOnDown setState:1];
        [self.checkTriggerOnUp setState:0];
    } else {
        [self.checkTriggerOnDown setState:0];
        [self.checkTriggerOnUp setState:0];
    }
}

- (IBAction)moveTriggerLevel:(id)sender {
    [self.graph setHorizTiggerLevel:self.sliderTriggerLevel.floatValue];
}

- (IBAction)moveTriggerOffset:(id)sender {
    [self.graph setVerticalTriggerDelay:self.sliderTriggerOffset.floatValue];
}



-(void)drawCallback
{
    HT6022_DataSizeTypeDef length = HT6022_1KB;
    
    NSInteger result = HT6022_ReadData(&_device, self.CH1, self.CH2, length, 0);
    NSString* status = [NSString stringWithFormat:@"HT6022_ReadData retured %ld", (long) result];
    [self.lbStatus setStringValue:status];
    if (result != 0) return;
    
    [self.graph CH1data:self.CH1 length:length];
    [self.graph CH2data:self.CH2 length:length];
    
    // Set the trigger state
    if (self.checkTriggerOnUp.state == 1) {
        [self.graph setTriggerState:YES upwards:YES];
    } else if (self.checkTriggerOnDown.state == 1) {
        [self.graph setTriggerState:YES upwards:NO];
    } else {
        [self.graph setTriggerState:NO upwards:NO];
    }
    
    // Display the data
    [self.graph setNeedsDisplay:YES];
    
    // Schedule to call oneself once more
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self drawCallback];
    });
    
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Allocate the max buffer size
    self.CH1 = (unsigned char*) calloc (sizeof (unsigned char)*HT6022_1MB, sizeof (unsigned char));
    self.CH2 = (unsigned char*) calloc (sizeof (unsigned char)*HT6022_1MB, sizeof (unsigned char));
    
    // Set the initial trigger state
    [self.checkTriggerOnDown setState:0];
    [self.checkTriggerOnUp setState:1];
    [self.sliderTriggerLevel setDoubleValue:0.7];
    [self.sliderTriggerLevel setDoubleValue:0.7];
    
    // Init the device
    NSInteger result = HT6022_Init();
    NSString* status = [NSString stringWithFormat:@"HT6022_Init retured %ld", (long) result];
    [self.lbStatus setStringValue:status];
    
    if (result != HT6022_SUCCESS) return;
    
    // Upload the firmware
    result = HT6022_FirmwareUpload();
    status = [NSString stringWithFormat:@"HT6022_FirmwareUpload returned %ld", (long) result];
    [self.lbStatus setStringValue:status];
    
    if (result != HT6022_SUCCESS && result != -4) return;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        //
        [self initStep2];
    });
}

-(void)applicationWillTerminate:(NSNotification *)notification
{
    if (self.CH1) {
        free (self.CH1);
        self.CH1 = nil;
    }
    
    if (self.CH2) {
        free (self.CH2);
        self.CH2 = nil;
    }
    
    
    HT6022_Exit();
}

@end
