//
//  CBlock.m
//  Hungry Bim
//
//  Created by Konstantin Tsymbalist on 15.04.12.
//  Copyright (c) 2012 Home. All rights reserved.
//

#import "CBlock.h"

@implementation CBlock

@synthesize isTouch;
@synthesize row;
@synthesize col;

- (CBlock *) initWithWGP:(id<CWorldGameProtocol>)_wgp //Протокол для общения с миром игры
                 WithRect:(SRect)_rect //Геометрия
       WithImageSequences:(SImageSequence *)_imageSequences //Набор последовательностей изображений
   WithImageSequenceCount:(Byte)_imageSequenceCount //Кол-во последовательностей изображений в наборе
                WithColor:(SColor)_color //Цвет
                WithSpeed:(SSpeed)_speed //Скорость
                 WithType:(Byte)_type //Тип блока
{
    self = [super initWithWGP:_wgp WithRect:_rect WithImageSequences:_imageSequences  WithImageSequenceCount:_imageSequenceCount WithColor:_color WithSpeed:_speed];
    isTouch = false;
    isMoved = false;
    type = _type;
    state = 0; //Состояние - покой
    gameFieldRect = [wgp getGameFieldRect];
    
    [self setIndex];
 
    return (self);
}

- (void) move:(GLfloat)deltaTime :(STouchMessage)touchMessage :(SAccelerometerMessage)accelerometerMessage
{
    if (state == 0) //В покое блок воприимчив к смахиванию
    {
        if (touchMessage.isRight)
        {
            if (touchMessage.type == 1)
                touchLocation = touchMessage.newLocation; //Запоминаем координаты касания по блоку
            
            if (touchMessage.type == 2) //Пользователь убрал палец с экрана
            {
                if (isTouch && isMoved)
                {
                    if (![wgp isRect:rect ContainsPoint:touchMessage.newLocation]) //Было смахивание
                    {
                        if (ABS(touchLocation.x - touchMessage.newLocation.x) > ABS(touchLocation.y - touchMessage.newLocation.y))
                        {//Двигаемся по оси x
                            if ((touchMessage.newLocation.x - touchLocation.x > 0) && (type == 1 || type == 3 || type == 7)) 
                                speed.x = BLOCK_SPEED;
                            else if ((touchMessage.newLocation.x - touchLocation.x < 0) && (type == 1 || type == 3 || type == 6))
                                speed.x = -BLOCK_SPEED;

                            speed.y = 0;
                        }
                        else
                        {
                            if ((touchMessage.newLocation.y - touchLocation.y > 0) && (type == 1 || type == 2 || type == 4)) 
                                speed.y = BLOCK_SPEED;
                            else if ((touchMessage.newLocation.y - touchLocation.y < 0) && (type == 1 || type == 2 || type == 5)) 
                                speed.y = -BLOCK_SPEED;                               
                            
                            speed.x = 0;
                        }
                        
                        state = 1;
                        CSprite *dogSprite = (CSprite *)([wgp getDogSprite]);
                        CGPoint a = dogSprite.rect.a;
                        if (a.x == rect.a.x && a.y == rect.a.y)
                        {
                            isDog = true;
                            [wgp hideBorderDogSprite];
                        }
                        else 
                            isDog = false;
                    }
                    
                    isTouch = false;
                    isMoved = false;
                }
            }
    
            if (isTouch && touchMessage.type == 3) //Идет перетаскивание
                isMoved = true;
        }
    }
    else if (state == 1) //Передвижение блока до тех пор, пока не встретится граница или другой блок
    {
        //Двигаем спрайт
        rect.a.x += speed.x*deltaTime;
        rect.a.y += speed.y*deltaTime;
        rect.b.x += speed.x*deltaTime;
        rect.b.y += speed.y*deltaTime;    
        rect.c.x += speed.x*deltaTime;
        rect.c.y += speed.y*deltaTime;
        rect.d.x += speed.x*deltaTime;
        rect.d.y += speed.y*deltaTime;
        
        //Двигаем щенка, если он есть на блоке
        if (isDog)
        {
            CSprite *dogSprite = (CSprite *)([wgp getDogSprite]);
            SRect dogRect = dogSprite.rect;
            
            dogRect.a.x += speed.x*deltaTime;
            dogRect.a.y += speed.y*deltaTime;
            dogRect.b.x += speed.x*deltaTime;
            dogRect.b.y += speed.y*deltaTime;    
            dogRect.c.x += speed.x*deltaTime;
            dogRect.c.y += speed.y*deltaTime;
            dogRect.d.x += speed.x*deltaTime;
            dogRect.d.y += speed.y*deltaTime;
           
            dogSprite.rect = dogRect;
        }
       
        //Проверяем на столкновения, учитывая направление движения
        CGPoint point;
        if (speed.x > 0)
        {
            point.x = rect.b.x;
            point.y = rect.c.y + (rect.b.y - rect.d.y)/2;
        }
        else if (speed.x < 0)
        {
            point.x = rect.a.x;
            point.y = rect.c.y + (rect.a.y - rect.c.y)/2;
        }
        else if (speed.y > 0)
        {
            point.x = rect.a.x + (rect.b.x - rect.a.x)/2;
            point.y = rect.a.y;
        }
        else if (speed.y < 0)
        {
            point.x = rect.c.x + (rect.d.x - rect.c.x)/2;
            point.y = rect.c.y;
        }
        
        ushort blockCount;
        blockCount = [wgp getBlockCount]; //Получаем кол-во блоков
        
        for (ushort i = 1; i <= blockCount; i++) //Цикл по блокам
        {
            SRect blockRect = [wgp getBlockRectByIndex:i];
            GLfloat w = BLOCK_SIZE;
            GLfloat h = BLOCK_SIZE;
            
            if ([wgp isRect:blockRect ContainsPoint:point]) //Произошло столкновение
            {
                if (speed.x > 0)
                {
                    rect.b.x = blockRect.a.x;
                    rect.d.x = blockRect.c.x;
                    
                    rect.a.x = rect.b.x - w;
                    rect.c.x = rect.d.x - w;
                }
                else if (speed.x < 0)
                {
                    rect.a.x = blockRect.b.x;
                    rect.c.x = blockRect.d.x;
                    
                    rect.b.x = rect.a.x + w;
                    rect.d.x = rect.c.x + w;
                }
                else if (speed.y > 0)
                {
                    rect.a.y = blockRect.c.y;
                    rect.b.y = blockRect.d.y;
                    
                    rect.c.y = rect.a.y - h;
                    rect.d.y = rect.b.y - h;
                }
                else if (speed.y < 0)
                {
                    rect.c.y = blockRect.a.y;
                    rect.d.y = blockRect.b.y;
                    
                    rect.a.y = rect.c.y + h;
                    rect.b.y = rect.d.y + h;
                }
                
                speed.x = 0;
                speed.y = 0;
                state = 0;
                
                if (isDog)
                {
                    CSprite *dogSprite = (CSprite *)([wgp getDogSprite]);
                    dogSprite.rect = rect;
                    isDog = false;
                }
                
                [self setIndex];
            }
            
            if (![wgp isRect:gameFieldRect ContainsPoint:point]) //Произошел выход за границу экрана
            {
                if (speed.x > 0)
                {
                    rect.b.x = gameFieldRect.b.x;
                    rect.d.x = gameFieldRect.d.x;
                    
                    rect.a.x = rect.b.x - w;
                    rect.c.x = rect.d.x - w;
                }
                else if (speed.x < 0)
                {
                    rect.a.x = gameFieldRect.a.x;
                    rect.c.x = gameFieldRect.c.x;
                    
                    rect.b.x = rect.a.x + w;
                    rect.d.x = rect.c.x + w;
                }
                else if (speed.y > 0)
                {
                    rect.a.y = gameFieldRect.a.y;
                    rect.b.y = gameFieldRect.b.y;
                    
                    rect.c.y = rect.a.y - h;
                    rect.d.y = rect.b.y - h;
                }
                else if (speed.y < 0)
                {
                    rect.c.y = gameFieldRect.c.y;
                    rect.d.y = gameFieldRect.d.y;
                    
                    rect.a.y = rect.c.y + h;
                    rect.b.y = rect.d.y + h;
                }
          
                
                speed.x = 0;
                speed.y = 0;
                state = 0;
                
                if (isDog)
                {
                    CSprite *dogSprite = (CSprite *)([wgp getDogSprite]);
                    dogSprite.rect = rect;
                    isDog = false;
                }
                
                [self setIndex];
            }
        }
    }
}

- (void) setIndex
{
    row = (int)(rect.c.y/(CGFloat)BLOCK_SIZE);
    col = (int)(rect.a.x/(CGFloat)BLOCK_SIZE);
}

- (NSString *) getType
{
    return (@"CBlock");
}

@end
