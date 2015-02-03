//
//  CWorldGameProtocol.h
//  GLSprite
//
//  Created by Konstantin Tsymbalist on 28.01.12.
//  Copyright (c) 2012 Home. All rights reserved.
//

#import <Foundation/Foundation.h>

//Геометрия
typedef struct _SRect
{
    CGPoint a;
    CGPoint b;
    CGPoint c;
    CGPoint d;
} SRect;

//Массив изображений
typedef struct _SImageSequence
{
    NSString *name;    //Наименование
    CGRect images[10]; //Массив текстурных координат изображений
    Byte imageCount;   //Кол-во изображений
} SImageSequence;

//Цвет
typedef struct _SColor
{
    short red;
    short green;
    short blue;
    GLfloat alpha;
} SColor;

//Скорость
typedef struct _SSpeed
{
    GLfloat x; //Составляющая скорости по оси x
    GLfloat y; //Составляющая скорости по оси y
} SSpeed;

//Протокол для общения объектов с главной формой
@protocol CWorldGameProtocol <NSObject>

//Обработка событий акселерометра
- (void) accelerometerProcess: (double)x :(double)y :(double)z; 

//Возвращает размеры игровой поверхности
- (CGSize) getBackingSize; 

//Вызывается при нажатии на кнопку "Старт"
- (void) startButtonPressed; 

//Определяет, входит ли точка point в прямоугольник rect
- (bool) isRect: (SRect) rect ContainsPoint: (CGPoint) point;

//Возвращает кол-во блоков 
- (ushort) getBlockCount;

//Возвращает прямоугольник блока по индексу
- (SRect) getBlockRectByIndex:(ushort)index;

//Возвращает индекс блока в двумерном массиве по его индексу в хранилище спрайтов
- (CGPoint) getBlockArrayIndexByIndex:(ushort)index;

//Возвращает прямоугольник экрана
- (SRect) getScreenRect;

//Возвращает прямоугльник игрового поля
- (SRect) getGameFieldRect;

//Возвращает указатель на щенка
- (NSObject *) getDogSprite;

//Скрывает рамку щенка
- (void) hideBorderDogSprite;
    
@end
