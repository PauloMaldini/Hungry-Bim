//
//  CDog.m
//  Hungry Bim
//
//  Created by Konstantin Tsymbalist on 25.04.12.
//  Copyright (c) 2012 Home. All rights reserved.
//

#import "CDog.h"

@implementation CDog

- (CDog *) initWithWGP:(id<CWorldGameProtocol>)_wgp //Протокол для общения с миром игры
                 WithRect:(SRect)_rect //Геометрия
       WithImageSequences:(SImageSequence *)_imageSequences //Набор последовательностей изображений
   WithImageSequenceCount:(Byte)_imageSequenceCount //Кол-во последовательностей изображений в наборе
                WithColor:(SColor)_color //Цвет
                WithSpeed:(SSpeed)_speed //Скорость
{
    self = [super initWithWGP:_wgp WithRect:_rect WithImageSequences:_imageSequences  WithImageSequenceCount:_imageSequenceCount WithColor:_color WithSpeed:_speed];
    
    state = 0;
    frameTime = 0;
    animationFreq = 0.25;
    name = @"Dog";
    
    return (self);
}


- (void) goToBlock:(SRect)_rect
{
    //Создаем двумерный массив для поиска пути
    Byte map[12][8];
    for (Byte i = 0; i < 12; i++)
        for (Byte j = 0; j < 8; j++)
            map[i][j] = 255; //Непроходная ячейка
 
    //Устанавливаем проходимость ячеек
    for (short i = 0; i < [wgp getBlockCount]; i++)
        map[(Byte)[wgp getBlockArrayIndexByIndex:i].y][(Byte)[wgp getBlockArrayIndexByIndex:i].x] = 254; //Проходная ячейка
    
    //Устанавливаем в массиве точки входа и выхода    
    map[(Byte)(rect.c.y/40.0)][(Byte)(rect.a.x/40.0)] = 253; //Вход
    map[(Byte)(_rect.c.y/40.0)][(Byte)(_rect.a.x/40.0)] = 0; //Выход
    
    //Распространяем волну
    short maxIter = 60;
    Byte N = 0;
    bool isSolved = false; //Возможно ли добраться до указанного блока
    while (N < maxIter)
    {
        for (int i = 0; i < 12; i++)
        {
            for (int j = 0; j < 8; j++)
            {
                if (map[i][j] == N)
                {
                    //Присваиваем соседним элементам элемента map[i][j] значение N + 1 
                    if (i - 1 >= 0 && map[i - 1][j] == 254)
                        map[i - 1][j] = N + 1;
                    if (i + 1 < 12 && map[i + 1][j] == 254)
                        map[i + 1][j] = N + 1;
                    if (j - 1 >= 0 && map[i][j - 1] == 254)
                        map[i][j - 1] = N + 1;
                    if (j + 1 < 8 && map[i][j + 1] == 254)
                        map[i][j + 1] = N + 1;
                    
                    //Если один из соседних элементов элемента map[i][j] есть вход, то выходим из цикла, т.к. путь найден
                    if ((i - 1 >= 0 && map[i - 1][j] == 253) || (i + 1 < 12 && map[i + 1][j] == 253) || (j - 1 >= 0 && map[i][j - 1] == 253) || (j + 1 < 8 && map[i][j + 1] == 253))
                    {
                        isSolved = true;
                        N = maxIter;
                        j = 8;
                        i = 12;
                    }
                }
            }
        }
        N++;
    } 
    
    //Если путь найден, то составляем набор команд для прохода объекта по блокам пути и переводим объект в состояние "Двигаться"
    if (isSolved)
    {
        int i = (Byte)(rect.c.y/40.0);
        int j = (Byte)(rect.a.x/40.0);
        short v;
        Byte newI, newJ;
        SCommand command;
        
        commandArray.count = 0;
 
        while (map[i][j]) //Цикл до достижения точки выхода
        {
            if (i - 1 >= 0)
            {
                v = map[i - 1][j];
                newI = i - 1;
                newJ = j;
                command.code = 1; //Вниз
                command.op1 = newJ*40.0;
                command.op2 = newI*40.0 + 40.0;
            }
            else
                v = 300;
            
            if (i + 1 < 12 && map[i + 1][j] < v)
            {
                v = map[i + 1][j];
                newI = i + 1;
                newJ = j;
                command.code = 2; //Вверх
                command.op1 = newJ*40.0;
                command.op2 = newI*40.0 + 40.0;
            }
           
            if (j - 1 >= 0 && map[i][j - 1] < v)
            {
                v = map[i][j - 1];
                newI = i;
                newJ = j - 1;
                command.code = 3; //Влево
                command.op1 = newJ*40.0;
                command.op2 = newI*40.0 + 40.0;
            }
            
            if (j + 1 < 8 && map[i][j + 1] < v)
            {
                v = map[i][j + 1];
                newI = i;
                newJ = j + 1;
                command.code = 4; //Вправо
                command.op1 = newJ*40.0;
                command.op2 = newI*40.0 + 40.0;
            }
            
            i = newI;
            j = newJ;
            
            [self addCommand:command]; // Добавляем команду в массив
        }
        
        state = 1; //Переводим объект в состояние "Выполнять команды"
        commandArray.index = 0;
    }
}

- (void) move:(GLfloat)deltaTime :(STouchMessage)touchMessage :(SAccelerometerMessage)accelerometerMessage
{
    if (state == 0) //Объект находится в состоянии покоя
    {
        imageSequenceIndex = 0;
    }
    else if (state == 1) //Объект читает команды
    {
        if (commandArray.index >= commandArray.count)
            state = 0;
        else 
        {
            Byte code = commandArray.commands[commandArray.index].code;
            if (code == 1) //Вниз
            {
                speed.x = 0;
                speed.y = -100;
            }
            else if (code == 2) //Вверх
            {
                speed.x = 0;
                speed.y = 100;
            }
            else if (code == 3) //Влево
            {
                speed.x = -100;
                speed.y = 0;
            }
            else if (code == 4) //Вправо
            {
                speed.x = 100;
                speed.y = 0;
            }
            
            destPoint.x = commandArray.commands[commandArray.index].op1;
            destPoint.y = commandArray.commands[commandArray.index].op2;
            
            state = 2;
        }
    }
    else if (state == 2) //Объект выполняет команды
    {
        rect.a.x += speed.x*deltaTime;
        rect.a.y += speed.y*deltaTime;
        rect.b.x += speed.x*deltaTime;
        rect.b.y += speed.y*deltaTime;    
        rect.c.x += speed.x*deltaTime;
        rect.c.y += speed.y*deltaTime;
        rect.d.x += speed.x*deltaTime;
        rect.d.y += speed.y*deltaTime;
        
        if (speed.x > 0)
            imageSequenceIndex = 2;
        else if (speed.x < 0)
            imageSequenceIndex = 3;
        else if (speed.y > 0)
            imageSequenceIndex = 1;
        else if (speed.y < 0)
            imageSequenceIndex = 0;
        
        
        if ((rect.a.x >= commandArray.commands[commandArray.index].op1 && speed.x > 0) || 
            (rect.a.x <= commandArray.commands[commandArray.index].op1 && speed.x < 0) || 
            (rect.a.y >= commandArray.commands[commandArray.index].op2 && speed.y > 0) || 
            (rect.a.y <= commandArray.commands[commandArray.index].op2 && speed.y < 0))
        {
            rect.a.x = commandArray.commands[commandArray.index].op1;
            rect.a.y = commandArray.commands[commandArray.index].op2;
            rect.b.x = rect.a.x + DOG_SIZE;
            rect.b.y = rect.a.y;
            rect.c.x = rect.a.x;
            rect.c.y = rect.a.y - DOG_SIZE;
            rect.d.x = rect.b.x;
            rect.d.y = rect.c.y;

            commandArray.index++;
            state = 1;
        }
    }
    
    if (!frameTime)
        frameTime = CFAbsoluteTimeGetCurrent();
    
    if (CFAbsoluteTimeGetCurrent() - frameTime > animationFreq)
    {
        imageIndex++;
        if (imageIndex >= 4)
            imageIndex = 0;
        frameTime = CFAbsoluteTimeGetCurrent();
    }

}

@end
