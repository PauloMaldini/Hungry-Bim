//
//  СControlMessageStack.h
//  Smart Intuition
//
//  Created by Konstantin Tsymbalist on 21.03.12.
//  Copyright (c) 2012 Home. All rights reserved.
//

#import <Foundation/Foundation.h>

#define MAX_MESSAGE_COUNT 1000 //Максимальное кол-во сообщений, помещающихся в очередь сообщений

//Сообщение касания, перетаскивания
typedef struct _STouchMessage
{
    CGPoint oldLocation; //Предыдущие координаты касания
    CGPoint newLocation; //Текущие координаты касания
    NSUInteger tapCount; //Кол-во касаний
    Byte type; //Touch (1), End (2), Move (3) 
    
    bool isRight; //Если true, то данные в структуре достоверны (не случайны) и их можно использовать
} STouchMessage;

//Сообщение акселерометра
typedef struct _SAccelerometerMessage
{
    double x; //Ускорение по х
    double y; //Ускорение по y
    double z; //Ускорение по z
    
    bool isRight; //Если true, то данные в структуре достоверны (не случайны) и их можно использовать
} SAccelerometerMessage;

//Класс, реализующий стек FIFO
@interface CControlMessageStack : NSObject
{
    STouchMessage touchMessage[MAX_MESSAGE_COUNT]; //Очередь сообщений касания и перемещения
    SAccelerometerMessage accelerometerMessage[MAX_MESSAGE_COUNT]; //Очередь сообщений акселерометра
    
    ushort touchMessageCount; //Кол-во сообщений касания и перемещения
    ushort accelerometerMessageCount; //Кол-во сообщений акселерометра
    
    ushort indexTouch; //Текущий индекс для записи в очередь (касания)
    ushort indexAccelerometer; //Текущий индекс для записи в очередь (акселерометр)
    
    ushort popIndexTouch; //Текущий индекс для выталкивания события касания из очереди
    ushort popIndexAccelerometer; //Текущий индекс для выталкивания события акселерометра из очереди
}

//Инициализация
-(id) init;

//Проталкивает сообщение касания в очередь
-(void) pushTouchMessage: (STouchMessage)_touchMessage;

//Выталкивает сообщение касания из очереди
-(void) popTouchMessage: (STouchMessage *)_touchMessage;

//Проталкивает сообщение акселерометра в очередь
-(void) pushAccelerometerMessage: (SAccelerometerMessage)_accelerometerMessage;

//Выталкивает сообщение акселерометра из очереди
-(void) popAccelerometerMessage: (SAccelerometerMessage *)_accelerometerMessage;

//Очищает стек касаний
-(void) clearTouch;

//Очищает стек акселерометра
-(void) clearAccelerometer;

@end
