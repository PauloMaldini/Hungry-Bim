//
//  GameObject.h
//  GLSprite
//
//  Created by User on 07.01.12.
//  Copyright (c) 2012 __Tsymbalist Konstantin__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CWorldGameProtocol.h"
#import "CControlMessageStack.h"

typedef struct _SCommand
{
    Byte code; //Код операции
    CGFloat op1; //Операнд 1
    CGFloat op2; //Операнд 2
} SCommand;

typedef struct _SCommandArray
{
    SCommand *commands;
    ushort size;
    ushort count;
    ushort index;
} SCommandArray;

//Базовый класс для всех спрайтов
@interface CSprite : NSObject
{
    NSString *name; //Имя объекта (для идентификации)

    id<CWorldGameProtocol> wgp; //Указатель на объект, реализующий протокол CWorldGameProtocol
    
    SRect rect; //Геометрия
    
    SSpeed speed; //Скорость движения
    
    CFAbsoluteTime absoluteTime; //Время последнего вызова функции move
    
    SColor color; //Цвет
    
    Byte imageSequenceIndex; //Текущая последовательность
    Byte imageIndex; //Текущее изображение в последовательности
    SImageSequence *imageSequences; //Массив последовательностей изображений
    Byte imageSequenceCount; //Кол-во последовательностей изображений
    
    bool isAccelerometer; //Если true, то спрайт восприимчив к акселерометру. Если false, то не восприимчив
    
    CGSize backingSize; //Размер экранной области
    
    SRect screenRect; //Прямоугольник, описывающий экран
    
    SCommandArray commandArray; //Массив команд спрайту
}

@property (nonatomic, assign) SRect rect;
@property (nonatomic, assign) SSpeed speed;
@property (nonatomic, assign) SColor color;
@property (nonatomic, assign) NSString* name;
@property (nonatomic, readonly, getter = getImage) CGRect image;
@property (nonatomic, assign) bool isAccelerometer;

//Инициализация объекта
- (CSprite *) initWithWGP:(id<CWorldGameProtocol>)_wgp //Протокол для общения с миром игры
                 WithRect:(SRect)_rect //Геометрия
       WithImageSequences:(SImageSequence *)_imageSequences //Набор последовательностей изображений
   WithImageSequenceCount:(Byte)_imageSequenceCount //Кол-во последовательностей изображений в наборе
                WithColor:(SColor)_color //Цвет
                WithSpeed:(SSpeed)_speed; //Скорость

//Механика объекта
- (void) move:(GLfloat)deltaTime :(STouchMessage)touchMessage :(SAccelerometerMessage)accelerometerMessage; 

//Уничтожение объекта
- (void) dealloc; 

//Наименование объекта
- (NSString *) getName; 

//Принадлежит ли точка (x,y) данному спрайту
- (bool) isOwneredByPoint:(CGPoint)point; 

//Геттер для свойства image
- (CGRect) getImage;

//Тип объекта
- (NSString *) getType;

//Добавляет команду в массив команд
- (void) addCommand: (SCommand)command;


@end
