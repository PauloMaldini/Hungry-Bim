//
//  СControlMessageStack.m
//  Smart Intuition
//
//  Created by Konstantin Tsymbalist on 21.03.12.
//  Copyright (c) 2012 Home. All rights reserved.
//

#import "CControlMessageStack.h"

@implementation CControlMessageStack

-(id) init
{
    if ((self = [super init]))
    {
        touchMessageCount = 0;
        accelerometerMessageCount = 0;
        indexTouch = 0;
        indexAccelerometer = 0;
        popIndexTouch = 0;
        popIndexAccelerometer = 0;
    }
    
    return (self);
}

-(void) pushTouchMessage: (STouchMessage)_touchMessage
{
    if (touchMessageCount < MAX_MESSAGE_COUNT)
    {
        touchMessageCount++;
        touchMessage[indexTouch++] = _touchMessage;
        
        if (indexTouch == MAX_MESSAGE_COUNT)
            indexTouch = 0;
    }
}

-(void) popTouchMessage: (STouchMessage *)_touchMessage
{
    _touchMessage->isRight = false;
    if (touchMessageCount > 0)
    {
        *_touchMessage = touchMessage[popIndexTouch++];
        _touchMessage->isRight = true;
        
        if (popIndexTouch == MAX_MESSAGE_COUNT)
            popIndexTouch = 0;
        
        touchMessageCount--;
    }
}

-(void) pushAccelerometerMessage: (SAccelerometerMessage)_accelerometerMessage
{
    if (accelerometerMessageCount < MAX_MESSAGE_COUNT)
    {
        accelerometerMessageCount++;
        accelerometerMessage[indexAccelerometer++] = _accelerometerMessage;
        
        if (indexAccelerometer == MAX_MESSAGE_COUNT)
            indexAccelerometer = 0;
    }
}

-(void) popAccelerometerMessage: (SAccelerometerMessage *)_accelerometerMessage
{
    _accelerometerMessage->isRight = false;
    if (accelerometerMessageCount > 0)
    {
        *_accelerometerMessage = accelerometerMessage[popIndexAccelerometer++];
        _accelerometerMessage->isRight = true;
        
        if (popIndexAccelerometer == MAX_MESSAGE_COUNT)
            popIndexAccelerometer = 0;
        
        accelerometerMessageCount--;
    }
}

-(void) clearTouch
{
    touchMessageCount = 0;
    indexTouch = 0;
    popIndexTouch = 0;
}

-(void) clearAccelerometer
{
    accelerometerMessageCount = 0;
    indexAccelerometer = 0;
    popIndexAccelerometer = 0;
}

@end
