//
//  CBlock.h
//  Hungry Bim
//
//  Created by Konstantin Tsymbalist on 15.04.12.
//  Copyright (c) 2012 Home. All rights reserved.
//

#import "CSprite.h"

#define BLOCK_SPEED 200
#define BLOCK_SIZE 40

@interface CBlock : CSprite
{
    bool isTouch; //Если true, значит пользователь коснулся блока
    bool isMoved; //Пользователь перетаскивает блок
        
    Byte type; //Тип блока (1 - все направления, 2 - вверх/вниз, 3 - влево/вправо, 4 - вверх, 5 - вниз, 6 - влево, 7 - вправо, 8 - неподвиж)
    
    Byte state; //Состояние блока (0 - в покое, 1 - перемещается)
    
    CGPoint touchLocation; //Точка касания по блоку
    
    SRect gameFieldRect; //Прямоугольник, описывающий игровое поле
    
    Byte row; //Индекс строки в двумерном массиве блоков
    Byte col; //Индекс столбца в двумерном массиве блоков
    
    bool isDog;
}

@property (nonatomic, assign) bool isTouch;
@property (nonatomic, readonly) Byte row;
@property (nonatomic, readonly) Byte col;

//Инициализация объекта
- (CBlock *) initWithWGP:(id<CWorldGameProtocol>)_wgp //Протокол для общения с миром игры
                 WithRect:(SRect)_rect //Геометрия
       WithImageSequences:(SImageSequence *)_imageSequences //Набор последовательностей изображений
   WithImageSequenceCount:(Byte)_imageSequenceCount //Кол-во последовательностей изображений в наборе
                WithColor:(SColor)_color //Цвет
                WithSpeed:(SSpeed)_speed //Скорость
                 WithType:(Byte)_type; //Тип блока
                    

//Механика объекта
- (void) move:(GLfloat)deltaTime :(STouchMessage)touchMessage :(SAccelerometerMessage)accelerometerMessage; 

//Вычисляет индекс блока в двумерном массиве
- (void) setIndex; 


@end
