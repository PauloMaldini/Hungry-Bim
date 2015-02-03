//
//  Texture2D.h
//  Smart Intuition
//
//  Created by Konstantin Tsymbalist on 11.02.12.
//  Copyright (c) 2012 Home. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>

@interface Texture2D : NSObject

+ (void) loadTextureWithFileName:(NSString *)fileName SavedIn:(GLuint *)textureID SaveWidthIn:(GLfloat *)width SaveHeightIn:(GLfloat *)height;

@end
