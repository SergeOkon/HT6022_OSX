//
//  Graph.h
//  ht6022
//
//  Created by Serge on 2014-07-05.
//  Copyright (c) 2014 SergeOkon. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface Graph : NSView

-(void)CH1data:(unsigned char*)data
        length:(size_t)length;

-(void)CH2data:(unsigned char*)data
        length:(size_t)length;

-(void)setHorizontalGridDivisions:(NSUInteger)divisions;

-(void)setHorizTiggerLevel:(float)level;
-(void)setVerticalTriggerDelay:(float)delay;
-(void)setTriggerState:(BOOL)isOn
               upwards:(BOOL)isUp;


@end
