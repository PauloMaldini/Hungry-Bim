//
//  CSpriteStorage.h
//  Smart Intuition
//
//  Created by Konstantin Tsymbalist on 10.02.12.
//  Copyright (c) 2012 Home. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>

#import "CSprite.h"
#import "Texture2D.h"

typedef struct _SSpriteArrayElement
{
    CSprite *sprite;
    //GLubyte *posInVertexArray;
    ushort *posInIndexArray;
} SSpriteArrayElement;

typedef struct _SVertexTextureColorArrayElem
{
    GLfloat position[2];
    GLfloat texture[2];
    GLubyte color[4];
} SVertexTextureColorArrayElem;

typedef struct _SVertexColorArrayElem
{
    GLfloat position[2];
    GLubyte color[4];
} SVertexColorArrayElem;

enum EFillType {ftColor, ftTexture};

@interface CSpriteStorage: NSObject
{
    ushort *indexArray; //Массив индексов
    SVertexTextureColorArrayElem *vertexTextureColorArray; //Массив вершинных, текстурных и цветовых координат
    SVertexColorArrayElem *vertexColorArray; //Массив вершинных и цветовых координат
    GLuint textureAtlas; //Атлас текстур
    GLfloat textureAtlasWidth; //Ширина текстурного атласа в пикселях
    GLfloat textureAtlasHeight; //Высота текстурного атласа в пикселях
    
    uint count; //Кол-во спрайтов
    SSpriteArrayElement *elements; //Массив спрайтов
    
    enum EFillType fillType; //Полигоны текстурируются или закрашиваются цветом
    
    GLfloat alpha; //Прозрачность текстур
}

@property (nonatomic, readonly) enum EFillType fillType;
@property (nonatomic, readonly) uint count;
@property (nonatomic, readonly) GLfloat textureAtlasWidth;
@property (nonatomic, readonly) GLfloat textureAtlasHeight;
@property (nonatomic, assign) GLfloat alpha;

//Инициализация
- (id) initWithSpriteCount:(ushort)_maxSpriteCount //Кол-во спрайтов в хранилище
               WithTexture:(NSString *)_fileName //Имя файла, содержащего текстурный атлас
              WithFillType:(enum EFillType)_fillType //Текстурированные или закрашенные спрайты хранятся
                 WithAlpha:(GLfloat)_alpha; //Прозрачность текстур

//Добавляет ранее созданный спрайт
- (void) addSprite:(CSprite *)_sprite;

//Возвращает спрайт по индексу 
- (CSprite *) getSpriteByIndex:(uint)_index;

//Удаляет спрайт
- (void) deleteSprite;

//Вызывает функцию Move всех спрайтов
- (void) move:(GLfloat)deltaTime :(STouchMessage) touchMessage :(SAccelerometerMessage)accelerometerMessage; 

//Рендеринг спрайтов
- (void) render;

//Очищает хранилище
- (void) clear;

//Деструктор
- (void) dealloc;



@end
