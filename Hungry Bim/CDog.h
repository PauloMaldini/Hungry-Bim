//
//  CDog.h
//  Hungry Bim
//
//  Created by Konstantin Tsymbalist on 25.04.12.
//  Copyright (c) 2012 Home. All rights reserved.
//

#import "CSprite.h"

#define DOG_SIZE 40

@interface CDog : CSprite
{
    Byte state; //Состояние объекта
    double animationFreq; //Частота анимации
    double frameTime; //Стартовое время кадра
    CGPoint destPoint; //Точка, в которую нужно двигаться
}

//Инициализация объекта
- (CDog *) initWithWGP:(id<CWorldGameProtocol>)_wgp //Протокол для общения с миром игры
                 WithRect:(SRect)_rect //Геометрия
       WithImageSequences:(SImageSequence *)_imageSequences //Набор последовательностей изображений
   WithImageSequenceCount:(Byte)_imageSequenceCount //Кол-во последовательностей изображений в наборе
                WithColor:(SColor)_color //Цвет
                WithSpeed:(SSpeed)_speed; //Скорость


//Дает команду двигаться к блоку, описываемому прямоугольником _rect. Использует волновой алгоритм дл поиска пути
- (void) goToBlock:(SRect)_rect;

//Механика объекта
- (void) move:(GLfloat)deltaTime :(STouchMessage)touchMessage :(SAccelerometerMessage)accelerometerMessage; 


@end
