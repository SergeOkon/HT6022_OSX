//
//  Graph.m
//  ht6022
//
//  Created by Serge on 2014-07-05.
//  Copyright (c) 2014 SergeOkon. All rights reserved.
//

#import "Graph.h"

@interface Graph()

@property (nonatomic) unsigned char* ch1data;
@property (nonatomic) size_t         ch1length;

@property (nonatomic) unsigned char* ch2data;
@property (nonatomic) size_t         ch2length;

@property (nonatomic) NSUInteger horizGridDivs;

@property (nonatomic) BOOL  triggerOn;
@property (nonatomic) BOOL  triggerIsUp;
@property (nonatomic) float triggerLevel;
@property (nonatomic) float triggerDelay;

@end

@implementation Graph


-(void) awakeFromNib
{
    
}

-(void)setTriggerState:(BOOL)isOn
               upwards:(BOOL)isUp
{
    self.triggerOn = isOn;
    self.triggerIsUp = isUp;
}

-(void)setHorizTiggerLevel:(float)level
{
    self.triggerLevel = level / 100;
}

-(void)setVerticalTriggerDelay:(float)delay
{
    self.triggerDelay = delay / 100;
}

-(void)setHorizontalGridDivisions:(NSUInteger)divisions
{
    self.horizGridDivs = divisions;
}

-(size_t)findTrigger
{
    if (!self.ch1data) return 0;
    if (self.ch1length < 9) return 0;
    if (!self.triggerOn) return 0;
    
    // Calulate the trigger level
    unsigned char level = (unsigned char)(self.triggerLevel * 255.0f);
    
    size_t pos = 8;
    
    // Ignore trigger right now - we need to get untriggered first
    while (((self.ch1data[pos] >= level) & self.triggerIsUp) ||
           ((self.ch1data[pos] <= level) & !self.triggerIsUp)) {
        pos ++;
        if (pos == self.ch1length) return 0;
    }
    
    // Now - wait for a trigger state to come back to trigger level
    while (((self.ch1data[pos] < level) & self.triggerIsUp) ||
           ((self.ch1data[pos] > level) & !self.triggerIsUp)) {
        pos ++;
        if (pos == self.ch1length) return 0;
    }
    
    return pos;
}


-(void)drawGraph:(unsigned char*) data
          length:(size_t)length
           color:(NSColor*)color
{
    if (!data) return;
    if (length < 2) return;

    CGFloat deltaY = self.frame.size.height / 255.0f;
    
    NSBezierPath* path = [NSBezierPath bezierPath];
    
    size_t start = [self findTrigger];
    CGFloat offset = (start > 0) ? self.frame.size.width * self.triggerDelay : 0;
    BOOL drawnAPoint = NO;
    for (CGFloat i = 0; i < self.frame.size.width; i++)
    {
        NSInteger index = (NSInteger) (i + start - offset);
        
        if ((index >= 0) && (index < length))
        {
            CGFloat level = deltaY*data[index];
            
            if (!drawnAPoint) {
                [path moveToPoint:CGPointMake(i, level)];
            } else {
                [path lineToPoint:CGPointMake(i, level)];
            }
            
            drawnAPoint = YES;
        }
        
    }
    
    [color set];
    [path stroke];
}

-(void) drawGrid
{
    CGFloat horizon = self.frame.size.height / 2;
    
    // Draw the zero line
    NSBezierPath* path = [NSBezierPath bezierPath];
    [path moveToPoint:CGPointMake(0, horizon)];
    [path lineToPoint:CGPointMake(self.frame.size.width, horizon)];
    [[NSColor lightGrayColor] set];
    [path stroke];
    
    // Draw the grid
    path = [NSBezierPath bezierPath];
    double dashStyle[2];
    dashStyle[0] = 1;
    dashStyle[1] = 3;
    
    for (size_t i = 1; i < self.horizGridDivs; i++)
    {
        CGFloat height = i * (horizon / (self.horizGridDivs));
        [path moveToPoint:CGPointMake(0, height)];
        [path lineToPoint:CGPointMake(self.frame.size.width, height)];
        height = height + horizon;
        [path moveToPoint:CGPointMake(0, height)];
        [path lineToPoint:CGPointMake(self.frame.size.width, height)];
    }
    
    [[NSColor lightGrayColor] set];
    [path setLineDash:dashStyle count:2 phase:0.0];
    [path stroke];
}


-(void) drawRect:(NSRect)dirtyRect
{
    // Draw the background
    [[NSColor darkGrayColor] set];
    [NSBezierPath fillRect:dirtyRect];
    
    // Draw the grid
    [self drawGrid];
    
    // Draw graphs
    [self drawGraph:self.ch1data length:self.ch1length color:[NSColor yellowColor]];
    [self drawGraph:self.ch2data length:self.ch2length color:[NSColor cyanColor]];
}


-(void)CH1data:(unsigned char *)data length:(size_t)length
{
    self.ch1data = data;
    self.ch1length = length;
}


-(void)CH2data:(unsigned char *)data length:(size_t)length
{
    self.ch2data = data;
    self.ch2length = length;
}

@end
