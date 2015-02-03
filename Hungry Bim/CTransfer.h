//
//  CTransfer.h
//  Smart Intuition
//
//  Created by Konstantin Tsymbalist on 11.02.12.
//  Copyright (c) 2012 Home. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CSprite.h"

@interface CTransfer : CSprite
{
    Byte state; //Состояние (>0 - выполняется, 0 - выполнение окончено)
    Byte type; //Тип (1 - show, 2 - hide, 3 - flash)
    CGFloat alphaFlash; //Верхняя граница альфа для вспышки 
}

@property (nonatomic, readonly) Byte state;

//Инициализация
- (id) initWithWGP:(id<CWorldGameProtocol>)_wgp;
//Устанавливает alpha = 1 с заданной скоростью
- (void) showWithSpeed:(GLfloat)speed WidthRed:(GLfloat)red WithGreen:(GLfloat)green WithBlue:(GLfloat)blue; 
//Устанавливает alpha = 0 с заданной скоростью
- (void) hideWithSpeed:(GLfloat)speed WidthRed:(GLfloat)red WithGreen:(GLfloat)green WithBlue:(GLfloat)blue;
//Вспышка с заданной скоростью
- (void) flashWithSpeed:(SSpeed)speed WithAlpha:(CGFloat)alpha WidthRed:(GLfloat)red WithGreen:(GLfloat)green WithBlue:(GLfloat)blue;
//Механика 
- (void) move:(GLfloat)deltaTime :(STouchMessage) touchMessage :(SAccelerometerMessage)accelerometerMessage; 

@end
