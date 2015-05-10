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

@property (nonatomic) unsigned char zeroLevelCH1;
@property (nonatomic) unsigned char zeroLevelCH2;
@property (nonatomic) float scalerCH1;
@property (nonatomic) float scalerCH2;

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
    [self.radioSampleSpeed selectCellAtRow:7 column:0];
    [self changeSampleRate:self.radioSampleSpeed];
    [self.radioCH1range selectCellAtRow:0 column:0];
    [self changeCH1range:self.radioCH1range];
    [self.radioCH2range selectCellAtRow:0 column:0];
    [self changeCH2range:self.radioCH2range];
    
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
    
    // Channel 1 controls divisions
    NSUInteger hDivs = 4;
    if (self.radioCH1range.selectedRow == 0) hDivs = 5;
    [self.graph setHorizontalGridDivisions:hDivs];
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

- (IBAction)clickCalibrateCH1:(id)sender {
    [self calculateCorrectionForChannel:1];
}

- (IBAction)clickCalibrateCH2:(id)sender {
    [self calculateCorrectionForChannel:2];
}


-(void)applyCorrections:(HT6022_DataSizeTypeDef)length
{
    for (NSUInteger i = 0; i < length; i++) {
        NSInteger value = self.CH1[i];
        if (value == 0 || value == 0) continue;  // Skip max / min values
        value = (unsigned int)((((float)value - self.zeroLevelCH1) * self.scalerCH1) + 128);
        value = (value < 0) ? 0 : ((value > 255) ? 255 : value);
        self.CH1[i] = value;
    }
    for (NSUInteger i = 0; i < length; i++) {
        NSInteger value = self.CH2[i];
        if (value == 0 || value == 0) continue;  // Skip max / min values
        value = (unsigned int)((((float)value - self.zeroLevelCH2) * self.scalerCH2) + 128);
        value = (value < 0) ? 0 : ((value > 255) ? 255 : value);
        self.CH2[i] = value;
    }
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
    
    // Apply Corrections
    [self applyCorrections:length];
    
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
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self drawCallback];
    });
    
}

-(void) calculateCorrectionForChannel:(NSInteger)channel
{
    if (channel != 1 && channel != 2) return;
    
    // Set the horizontal / vertical resolution
    // Set the sampling rate
    [self.radioSampleSpeed selectCellAtRow:7 column:0];
    [self changeSampleRate:self.radioSampleSpeed];

    // Wait a bit, and set the vertical resolution
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^
    {
        if (channel == 1) {
            [self.radioCH1range selectCellAtRow:0 column:0];
            [self changeCH1range:self.radioCH1range];
        }
        
        if (channel == 2) {
            [self.radioCH2range selectCellAtRow:0 column:0];
            [self changeCH2range:self.radioCH2range];
        }
        
        // Wait a bit, and sample
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^
        {
            // Read 1 KB of samples
            HT6022_DataSizeTypeDef length = HT6022_1KB;
            NSInteger result = HT6022_ReadData(&_device, self.CH1, self.CH2, length, 0);
            NSString* status = [NSString stringWithFormat:@"HT6022_ReadData retured %ld", (long) result];
            [self.lbStatus setStringValue:status];
            if (result != 0) return;
            
            unsigned char* data = (channel == 1 ) ? self.CH1 : self.CH2;
            
            NSMutableArray *averages = [NSMutableArray new];
            
            // Constants for the below averaging algorithm
            const NSInteger skipDataInBeginningAndEnd = 64;
            const NSInteger maxDifferenceInConstantLevel = 4;
            const NSInteger samplesToSkip = 2;
            const NSInteger minSamplesToConciderAStableVoltageLevel = 5;
            
            unsigned char lastValue = 0;
            NSUInteger accumulator = 0, nValues = 0, nSamples = 0;
            for (NSUInteger i = 0 + skipDataInBeginningAndEnd;
                 i < 1024-skipDataInBeginningAndEnd;
                 i++)
            {
                if (abs((int)lastValue - (int)data[i]) <= maxDifferenceInConstantLevel)
                {
                    // Skip a few sample to gather stable data
                    if (nValues >= samplesToSkip) {
                        accumulator += data[i];
                        nSamples++;
                    }
                    nValues++;
                } else {
                    // Levels changed - save accumulated data
                    if (nSamples >= minSamplesToConciderAStableVoltageLevel) {
                        NSUInteger voltageLevel = accumulator / nSamples;
                        [averages addObject:@(voltageLevel)];
                    }
                    
                    // Reset average calculator
                    accumulator = nValues = nSamples = 0;
                }
                lastValue = data[i];
            }
            
            // Add in the last point
            if (nSamples >= minSamplesToConciderAStableVoltageLevel) {
                NSUInteger voltageLevel = accumulator / nSamples;
                [averages addObject:@(voltageLevel)];
            }
            
            // Determine average levels
            NSUInteger sum = 0;
            for (NSUInteger i = 0; i < averages.count; i++) sum += [averages[i] unsignedIntegerValue];
            NSUInteger averageOfAverages = sum / averages.count;
            
            NSUInteger highSum = 0, lowSum = 0, nHighSamples = 0, nLowSamples = 0;;
            for (NSUInteger i = 0; i < averages.count; i++) {
                NSUInteger average = [averages[i] unsignedIntegerValue];
                if (average > averageOfAverages) {
                    highSum += average;
                    nHighSamples++;
                } else if (average < averageOfAverages) {
                    lowSum += average;
                    nLowSamples++;
                }
            }
            
            // Calculate Zero V and 2 V levels as unsigned ints
            if (nLowSamples < 1 || nHighSamples < 1) return;
            NSUInteger zeroLevel = lowSum / nLowSamples;
            NSUInteger twoVoltLevel = highSum / nHighSamples;
            
            // Set the calibrarion in the graph.
            if (channel == 1) {
                self.zeroLevelCH1 = zeroLevel;
                self.scalerCH1 =  1.0f / ((float)(twoVoltLevel - zeroLevel)*(10.0f / 256.0f) / 2.0f);
            } else {
                self.zeroLevelCH2 = zeroLevel;
                self.scalerCH2 =  1.0f / ((float)(twoVoltLevel - zeroLevel)*(10.0f / 256.0f) / 2.0f);
            }
        });

    });
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Allocate the max buffer size
    self.CH1 = (unsigned char*) calloc (sizeof (unsigned char)*HT6022_1MB, sizeof (unsigned char));
    self.CH2 = (unsigned char*) calloc (sizeof (unsigned char)*HT6022_1MB, sizeof (unsigned char));
    
    // Reset Calibration
    self.scalerCH1 = self.scalerCH2 = 1.0f;
    self.zeroLevelCH1 = self.zeroLevelCH2 = 128;
    
    // Set the initial trigger state
    [self.checkTriggerOnDown setState:0];
    [self.checkTriggerOnUp setState:1];
    [self.sliderTriggerOffset setDoubleValue:10];
    [self moveTriggerOffset:nil];
    [self.sliderTriggerLevel  setDoubleValue:60];
    [self moveTriggerLevel:nil];
    
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
