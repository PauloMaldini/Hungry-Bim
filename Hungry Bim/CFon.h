//
//  CFon.h
//  Smart Intuition
//
//  Created by Konstantin Tsymbalist on 09.02.12.
//  Copyright (c) 2012 Home. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CSprite.h"

@interface CFon : CSprite
{
    
}

- (id) initWithWGP:(id<CWorldGameProtocol>)_wgp WithTextureAtlasWidth:(GLfloat)_width WithTextureAtlasHeight:(GLfloat)height;
- (void) move:(GLfloat)deltaTime :(STouchMessage) touchMessage :(SAccelerometerMessage)accelerometerMessage; 

    
@end
