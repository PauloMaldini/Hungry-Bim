//
//  CTransfer.m
//  Smart Intuition
//
//  Created by Konstantin Tsymbalist on 11.02.12.
//  Copyright (c) 2012 Home. All rights reserved.
//

#import "CTransfer.h"

@implementation CTransfer

@synthesize state;

- (id) initWithWGP:(id<CWorldGameProtocol>)_wgp
{
    state = 0;
    
    backingSize = [_wgp getBackingSize];

    rect.a.x = 0;
    rect.a.y = backingSize.height;
    rect.b.x = backingSize.width;
    rect.b.y = backingSize.height;
    rect.c.x = 0;
    rect.c.y = 0;
    rect.d.x = backingSize.width;
    rect.d.y = 0;
    
    color.red = 0;
    color.green = 0;
    color.blue = 0;
    color.alpha = 0;
    
    speed.x = 0;
    speed.y = 0;
    
    self = [super initWithWGP:_wgp WithRect:rect WithImageSequences:nil WithImageSequenceCount:0 WithColor:color WithSpeed:speed];
        
    return (self);
}

- (void) move:(GLfloat)deltaTime :(STouchMessage) touchMessage :(SAccelerometerMessage)accelerometerMessage
{
    if (state)
    {
        if (type == 1) //show
        {
            if (color.alpha < 255)
                color.alpha += speed.x*deltaTime;
   
            if (color.alpha >= 255)
            {
                color.alpha = 255;
                state = 0;
            }
        }
        else if (type == 2) //hide
        {
            if (color.alpha > 0)
                color.alpha += speed.x*deltaTime;
        
            if (color.alpha <= 0)
            {
                color.alpha = 0;
                state = 0;
            }
        }
        else if (type == 3) //flash
        { 
            if (state == 1)
            {
                if (color.alpha < alphaFlash)
                    color.alpha += speed.x*deltaTime;
        
                if (color.alpha >= alphaFlash)
                {
                    color.alpha = alphaFlash;
                    state = 2;
                }
            }
            else if (state == 2)
            {
                if (color.alpha > 0)
                    color.alpha -= speed.y*deltaTime;
            
                if (color.alpha <= 0)
                {
                    color.alpha = 0;
                    state = 0;
                }
            }
        }
    }
}

- (void) showWithSpeed:(GLfloat)_speed WidthRed:(GLfloat)_red WithGreen:(GLfloat)_green WithBlue:(GLfloat)_blue
{
    speed.x = ABS(_speed);
    color.alpha = 0;
    color.red = _red;
    color.green = _green;
    color.blue = _blue;
    type = 1;
    state = 1;
}

- (void) hideWithSpeed:(GLfloat)_speed WidthRed:(GLfloat)_red WithGreen:(GLfloat)_green WithBlue:(GLfloat)_blue
{
    speed.x = -ABS(_speed);
    color.alpha = 255;
    color.red = _red;
    color.green = _green;
    color.blue = _blue;
    type = 2;
    state = 1;
}

- (void) flashWithSpeed:(SSpeed)_speed WithAlpha:(CGFloat)_alpha WidthRed:(GLfloat)_red WithGreen:(GLfloat)_green WithBlue:(GLfloat)_blue
{
    speed.x = ABS(_speed.x);
    speed.y = ABS(_speed.y);
    color.alpha = 0;
    color.red = _red;
    color.green = _green;
    color.blue = _blue;
    type = 3;
    state = 1;
    alphaFlash = _alpha;
}




@end
