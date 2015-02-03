//
//  GameObject.m
//  GLSprite
//
//  Created by User on 07.01.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CSprite.h"


@implementation CSprite

@synthesize rect;
@synthesize speed;
@synthesize color;
@synthesize image;
@synthesize name;
@synthesize isAccelerometer;

- (CSprite *) initWithWGP:(id<CWorldGameProtocol>)_wgp
                 WithRect:(SRect)_rect
       WithImageSequences:(SImageSequence *)_imageSequences
   WithImageSequenceCount:(Byte)_imageSequenceCount
                WithColor:(SColor)_color 
                WithSpeed:(SSpeed)_speed
{
    [super init];
       
    wgp = _wgp;
    rect = _rect;
    color = _color;
    speed = _speed;
    absoluteTime = 0;
    
    imageSequences = _imageSequences;
    imageSequenceCount = _imageSequenceCount;
    imageSequenceIndex = 0;
    imageIndex = 0;
    
    name = nil;
    
    isAccelerometer = false;
    
    backingSize = [wgp getBackingSize];
    screenRect = [wgp getScreenRect];
    
    commandArray.commands = nil;
    commandArray.size = 0;
    commandArray.count = 0;
    commandArray.index = 0;
    
    return (self);
}

- (void) move:(GLfloat)deltaTime :(STouchMessage)touchMessage :(SAccelerometerMessage)accelerometerMessage
{
    if (isAccelerometer && accelerometerMessage.isRight)
    {
        GLfloat s = 100;
        GLfloat a = 0.1;
        if (accelerometerMessage.x > a)
            speed.x = s;
        else if (accelerometerMessage.x < -a)
            speed.x = -s;
        else
            speed.x = 0;
        
        if (accelerometerMessage.y > a)
            speed.y = s;
        else if (accelerometerMessage.y < -a)
            speed.y = -s;
        else
            speed.y = 0;
        
        
        //speed.x += (100*accelerometerMessage.x)*deltaTime;
        //speed.y += (100*accelerometerMessage.y)*deltaTime;
    }
        
    //Двигаем спрайт
    rect.a.x += speed.x*deltaTime;
    rect.a.y += speed.y*deltaTime;
    rect.b.x += speed.x*deltaTime;
    rect.b.y += speed.y*deltaTime;    
    rect.c.x += speed.x*deltaTime;
    rect.c.y += speed.y*deltaTime;
    rect.d.x += speed.x*deltaTime;
    rect.d.y += speed.y*deltaTime;    
}

-(void) dealloc
{
    
}

-(NSString *) getName
{
    return(name);
}

- (bool) isOwneredByPoint:(CGPoint)point
{
    if (point.x > rect.a.x && point.x < rect.b.x && point.y > rect.c.y && point.y < rect.a.y)
        return (true);
    
    return (false);
}

- (CGRect) getImage
{
    return (imageSequences[imageSequenceIndex].images[imageIndex]);
}

- (NSString *) getType
{
    return (@"CSprite");
}

- (void) addCommand: (SCommand)command
{
    if (commandArray.size > commandArray.count)
        commandArray.commands[commandArray.count++] = command;
    else 
    {
        SCommand *buf = malloc(sizeof(SCommand)*(commandArray.count));
        memcpy(buf, commandArray.commands, commandArray.count*sizeof(SCommand));
        commandArray.commands = malloc(sizeof(SCommand)*(commandArray.count + 1));
        commandArray.size++;
        memcpy(commandArray.commands, buf, commandArray.count*sizeof(SCommand));
        commandArray.commands[++commandArray.count - 1] = command;
    }
}



@end
