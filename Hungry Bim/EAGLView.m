#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGLDrawable.h>


#import "EAGLView.h"


@interface EAGLView (EAGLViewPrivate)

- (BOOL)createFramebuffer;
- (void)destroyFramebuffer;

@end

@interface EAGLView (EAGLViewSprite)

- (void)setupView;

@end

@implementation EAGLView

@synthesize animating;
@dynamic animationFrameInterval;

// You must implement this
+ (Class) layerClass
{
	return [CAEAGLLayer class];
}

//The GL view is stored in the nib file. When it's unarchived it's sent -initWithCoder:
- (id)initWithCoder:(NSCoder*)coder
{
    if((self = [super initWithCoder:coder])) 
    {
        int w = 320, h = 480;
        float ver = [[[UIDevice currentDevice] systemVersion] floatValue];
        // You can't detect screen resolutions in pre 3.2 devices, but they are all 320x480
        if (ver >= 3.2f)
        {
            UIScreen* mainscr = [UIScreen mainScreen];
            w = mainscr.currentMode.size.width;
            h = mainscr.currentMode.size.height;
        }
        if (w == 640 && h == 960)
        {
           // self.contentScaleFactor = 2.0;
           // CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.layer;
          //  eaglLayer.contentsScale = 2;
            //menuPlistFileName = @"ui@2x";
        }
        
        //Создаем очередь сообщений
        controlMessageStack = [[CControlMessageStack alloc] init];
        
        // Get the layer
        CAEAGLLayer *eaglLayer = (CAEAGLLayer*) self.layer;
        
        eaglLayer.opaque = YES;
        eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                        [NSNumber numberWithBool:FALSE], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
        
        context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];
        
        if(!context || ![EAGLContext setCurrentContext:context] || ![self createFramebuffer]) {
            [self release];
            return nil;
        }
        
        animating = FALSE;
        displayLinkSupported = FALSE;
        animationFrameInterval = 1;
        displayLink = nil;
        animationTimer = nil;
        
        // A system version of 3.1 or greater is required to use CADisplayLink. The NSTimer
        // class is used as fallback when it isn't available.
        NSString *reqSysVer = @"3.1";
        NSString *currSysVer = [[UIDevice currentDevice] systemVersion];
        if ([currSysVer compare:reqSysVer options:NSNumericSearch] != NSOrderedAscending)
            displayLinkSupported = TRUE;
        
        [self setupView];
        [self drawView];
   }
   
   return self;
}


- (void)layoutSubviews
{
    [EAGLContext setCurrentContext:context];
    [self destroyFramebuffer];
    [self createFramebuffer];
    [self drawView];
}


- (BOOL)createFramebuffer
{
    glGenFramebuffersOES(1, &viewFramebuffer);
    glGenRenderbuffersOES(1, &viewRenderbuffer);
    
    glBindFramebufferOES(GL_FRAMEBUFFER_OES, viewFramebuffer);
    glBindRenderbufferOES(GL_RENDERBUFFER_OES, viewRenderbuffer);
    [context renderbufferStorage:GL_RENDERBUFFER_OES fromDrawable:(id<EAGLDrawable>)self.layer];
    glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_RENDERBUFFER_OES, viewRenderbuffer);
    
    glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_WIDTH_OES, &backingWidth);
    glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_HEIGHT_OES, &backingHeight);
    
    if(glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES) != GL_FRAMEBUFFER_COMPLETE_OES) {
        NSLog(@"failed to make complete framebuffer object %x", glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES));
        return NO;
    }
    
    return YES;
}


- (void)destroyFramebuffer
{
    glDeleteFramebuffersOES(1, &viewFramebuffer);
    viewFramebuffer = 0;
    glDeleteRenderbuffersOES(1, &viewRenderbuffer);
    viewRenderbuffer = 0;
    
    if(depthRenderbuffer) {
        glDeleteRenderbuffersOES(1, &depthRenderbuffer);
        depthRenderbuffer = 0;
    }
}


- (NSInteger) animationFrameInterval
{
    return animationFrameInterval;
}

- (void) setAnimationFrameInterval:(NSInteger)frameInterval
{
    // Frame interval defines how many display frames must pass between each time the
    // display link fires. The display link will only fire 30 times a second when the
    // frame internal is two on a display that refreshes 60 times a second. The default
    // frame interval setting of one will fire 60 times a second when the display refreshes
    // at 60 times a second. A frame interval setting of less than one results in undefined
    // behavior.
    if (frameInterval >= 1)
    {
        animationFrameInterval = frameInterval;
        
        if (animating)
        {
            [self stopAnimation];
            [self startAnimation];
        }
    }
}

- (void) startAnimation
{
    lastTime = 0.0;
    deltaTime = 0.0;

    if (!animating)
    {
        if (displayLinkSupported)
        {
            // CADisplayLink is API new to iPhone SDK 3.1. Compiling against earlier versions will result in a warning, but can be dismissed
            // if the system version runtime check for CADisplayLink exists in -initWithCoder:. The runtime check ensures this code will
            // not be called in system versions earlier than 3.1.
            
            displayLink = [NSClassFromString(@"CADisplayLink") displayLinkWithTarget:self selector:@selector(drawView)];
            [displayLink setFrameInterval:animationFrameInterval];
            [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        }
        else
            animationTimer = [NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval)((1.0 / 60.0) * animationFrameInterval) target:self selector:@selector(drawView) userInfo:nil repeats:TRUE];
        
        animating = TRUE;
    }
}

- (void)stopAnimation
{
    if (animating)
    {
        if (displayLinkSupported)
        {
            [displayLink invalidate];
            displayLink = nil;
        }
        else
        {
            [animationTimer invalidate];
            animationTimer = nil;
        }
        
        animating = FALSE;
    }
}

- (void)setupView
{
    isTouchMoved = false;
    isFinish = false;
    // Sets up matrices and transforms for OpenGL ES
        
    //Создаем спрайт "Заставка"
   /* screenSpriteStorage = [[CSpriteStorage alloc] initWithSpriteCount:1 WithTexture:@"Default.png" WithFillType:ftTexture WithAlpha:1];
    
    CSprite *screen = [[CFon alloc] initWithWGP:self WithTextureAtlasWidth:screenSpriteStorage.textureAtlasWidth WithTextureAtlasHeight: screenSpriteStorage.textureAtlasHeight];
    
    [screenSpriteStorage addSprite:screen];*/
    
    //Создаем спрайт "Фон"
    /*fonSpriteStorage = [[CSpriteStorage alloc] initWithSpriteCount:1 WithTexture:@"bg.png" WithFillType:ftTexture WithAlpha:1];
    
    CFon *fon = [[CFon alloc] initWithWGP:self WithTextureAtlasWidth:fonSpriteStorage.textureAtlasWidth WithTextureAtlasHeight:fonSpriteStorage.textureAtlasHeight];

    [fonSpriteStorage addSprite:fon];*/
    
    //Создаем спрайт "Переход"
    transferSpriteStorage = [[CSpriteStorage alloc] initWithSpriteCount:1 WithTexture:@"" WithFillType:ftColor WithAlpha:1];
    CTransfer *transfer = [[CTransfer alloc] initWithWGP:self];
    [transfer hideWithSpeed:300 WidthRed:0 WithGreen:0 WithBlue:0];
    [transferSpriteStorage addSprite:transfer];
    
    //Загружаем сопроводительный файл к атласу текстур игровых объектов
    blocksDict = [[[NSDictionary alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"GameElements" ofType:@"plist"]] objectForKey:@"blocks"];
    dogDict = [[[NSDictionary alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"GameElements" ofType:@"plist"]] objectForKey:@"dog"];
    gameObjectSpriteStorage = [[CSpriteStorage alloc] initWithSpriteCount:500 WithTexture:@"GameElements.png" WithFillType:ftTexture WithAlpha:1];
    
    mapName = @"map1";
    [self initGameObjectSpriteStorage];
    
    //Создаем хранилище спрайтов для букв FPS
    arialDict = [[NSDictionary alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"arial" ofType:@"plist"]];
    fpsSpriteStorage = [[CSpriteStorage alloc] initWithSpriteCount:100 WithTexture:@"arial.png" WithFillType:ftTexture WithAlpha:1];
     
    glViewport(0, 0, backingWidth, backingHeight);
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    glOrthof(-160, 160, -240, 240, -1, 1);
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
    
    //Смещаемся в левый нижний угол экрана
    glTranslatef(-160, -240, 0.0f);
    
    //Цвет очистки экрана - черный
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    
    glEnable(GL_TEXTURE_2D);
        
    //Задаем уравнение смешивания    
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        
    //Включаем смешивание
    glEnable(GL_BLEND);
    
    //Устанавливаем состояние игры в 1
    gameState = 1;
    
    //Настраиваем звук 
    /*   contextAudio = NULL;
    deviceAudio = alcOpenDevice(NULL);
    if (deviceAudio)
    {
        contextAudio = alcCreateContext(deviceAudio, NULL);
        alcMakeContextCurrent(contextAudio);
    }
    
    AudioFileID audioFileCollis;
    NSURL *url = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"collis" ofType:@"caf"]];
    AudioFileOpenURL((CFURLRef)url, kAudioFileReadPermission, 0, &audioFileCollis);
    
    UInt32 fileSize = 0;
    UInt32 propSize = sizeof(UInt64);
    AudioFileGetProperty(audioFileCollis, kAudioFilePropertyAudioDataByteCount, &propSize, &fileSize);
    
    unsigned char *buffer = malloc(fileSize);
    AudioFileReadBytes(audioFileCollis, false, 0, &fileSize, buffer);
    AudioFileClose(audioFileCollis);

    alGenBuffers(1, &audioBufferCollisId);
    alBufferData(audioBufferCollisId, AL_FORMAT_STEREO16, buffer, fileSize, 44100);
    free(buffer);
    
    alGenSources(1, &audioSourceCollisId);
    alSourcei(audioSourceCollisId, AL_BUFFER, audioBufferCollisId);
    alSourcef(audioSourceCollisId, AL_PITCH, 1.0f);
    alSourcef(audioSourceCollisId, AL_GAIN, 1.0f);	
    alSourcei(audioSourceCollisId, AL_LOOPING, AL_FALSE);*/
}

- (void)drawView
{
    if (lastTime != 0)
        deltaTime = (GLfloat)(CFAbsoluteTimeGetCurrent() - lastTime);
    lastTime = CFAbsoluteTimeGetCurrent();
    fps = [self calcFPS];
    
    [EAGLContext setCurrentContext:context];
    
    glBindFramebufferOES(GL_FRAMEBUFFER_OES, viewFramebuffer);
    
    glClearColor(0.0f, 0.0f, 0.0f, 1);
    glClear(GL_COLOR_BUFFER_BIT);
    
    //Показываем fps в левом верхнем углу
    [fpsSpriteStorage clear];
    NSString *fpsString = [NSString stringWithFormat:@"fps:%d", fps + 1];
    [self drawText:fpsString InPos:CGPointMake(13, 476) InSpriteStorage:fpsSpriteStorage FromDict:arialDict];
    
    //Показываем номер версии в правом верхнем
    fpsString = [NSString stringWithFormat:@VER_NUM];
    [self drawText:fpsString InPos:CGPointMake(180, 476) InSpriteStorage:fpsSpriteStorage FromDict:arialDict];

    //Принимаем данные касаний и данные акселерометра
    STouchMessage touchMessage;
    SAccelerometerMessage accelerometerMessage;
    [controlMessageStack popTouchMessage:&touchMessage]; //Получаем сообщение от касаний
    [controlMessageStack popAccelerometerMessage:&accelerometerMessage]; //Получаем сообщение от акселерометра

    if (gameState == 1) //Первое состояние игры
    {
        if (dogSprite.rect.a.x == meatSprite.rect.a.x && dogSprite.rect.a.y == meatSprite.rect.a.y)
        {
            if (mapName == @"map1")
                mapName = @"map2";
            else if (mapName == @"map2")
                mapName = @"map3";
            else if (mapName == @"map3")
                mapName = @"map1";
            
            [self initGameObjectSpriteStorage];
        }
        
        if (touchMessage.type == 1)
        {
            //isTouch = true;
            CBlock *block = [self getBlockByPoint:touchMessage.newLocation];
            if (block) //Если коснулись блока, то сообщаем ему об этом
            {
                block.isTouch = true;
                if(borderSprite.color.alpha == 255) //Если до этого щенок был выделен, то даем ему команду двигаться к данному блоку
                    [dogSprite goToBlock:block.rect];
            }
            
            if ([self isRect:dogSprite.rect ContainsPoint:touchMessage.newLocation]) //Если коcнулись щенка
            {
                SColor color = borderSprite.color;
                color.alpha = 255;
                borderSprite.color = color;
                borderSprite.rect = dogSprite.rect;
            }
            else 
            {
                SColor color = borderSprite.color;
                color.alpha = 0;
                borderSprite.color = color;
            }
        }
        
        [gameObjectSpriteStorage move:deltaTime :touchMessage :accelerometerMessage];
        [gameObjectSpriteStorage render];
        
        [fpsSpriteStorage move:deltaTime :touchMessage :accelerometerMessage];
        [fpsSpriteStorage render];
    }
       
    glBindRenderbufferOES(GL_RENDERBUFFER_OES, viewRenderbuffer);
    [context presentRenderbuffer:GL_RENDERBUFFER_OES];
}

- (void)dealloc
{
    //Освобождаем аудио-ресурсы
    alSourceStop(audioSourceCollisId);
    alSourcei(audioSourceCollisId, AL_BUFFER, 0);
    alDeleteBuffers(1, &audioBufferCollisId);
    alDeleteSources(1,&audioSourceCollisId);
    alcDestroyContext(contextAudio);
    alcCloseDevice(deviceAudio);
    
    //Удаляем память, выделенную под спрайты
    [transferSpriteStorage release];
    [fonSpriteStorage release];
    [menuSpriteStorage release];
    [gameObjectSpriteStorage release];
    
    //Освобождаем OpenGL-контекст
    if([EAGLContext currentContext] == context) {
        [EAGLContext setCurrentContext:nil];
    }
    
    [context release];
    context = nil;
    
    [super dealloc];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInView: self];
    startLocation = location;
    startLocation.y = backingHeight - startLocation.y;
    
    STouchMessage touchMessage;
    touchMessage.isRight = true;
    touchMessage.newLocation = startLocation;
    touchMessage.type = 1;
    [controlMessageStack pushTouchMessage:touchMessage];
    
    [super touchesBegan:touches withEvent:event];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch      = [touches anyObject];
    CGPoint oldLocation = [touch previousLocationInView:self];
    CGPoint location    = [touch locationInView:self];
    
    oldLocation.y = backingHeight - oldLocation.y;
    location.y = backingHeight - location.y;
    
    STouchMessage touchMessage;
    touchMessage.isRight = true;
    touchMessage.newLocation = location;
    touchMessage.oldLocation = oldLocation;
    touchMessage.type = 3;
    [controlMessageStack pushTouchMessage:touchMessage];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInView: self];
    NSUInteger tapCount = [touch tapCount];
    finishLocation = location;
    finishLocation.y = backingHeight - finishLocation.y;
    
    STouchMessage touchMessage;
    touchMessage.isRight = true;
    touchMessage.newLocation = finishLocation;
    touchMessage.type = 2;
    touchMessage.tapCount = tapCount;
    [controlMessageStack pushTouchMessage:touchMessage];
}

- (void)clearMemory: (void*)p WithByteCount: (int)count
{
    for (int i = 0; i < count; i++)
        *(Byte *)(p + i) = 0;
}

- (void) getDataFromPlist: (NSDictionary *)dict
                    ByKey: (NSString *)key
      ByTextureAtlasWidth: (GLfloat)textureAtlasWidth
     ByTextureAtlasHeight: (GLfloat)textureAtlasHeight
                    InPos: (SRect *)posRect
                    InTex: (CGRect *)texRect
                  InColor: (SColor *)color
                  InSpeed: (SSpeed *)speed
{
    posRect->a.x = [[(NSArray *)[(NSDictionary *)[dict objectForKey:key] objectForKey:@"scr_pos"] objectAtIndex:0] integerValue];
    posRect->a.y = [[(NSArray *)[(NSDictionary *)[dict objectForKey:key] objectForKey:@"scr_pos"] objectAtIndex:1] integerValue];
    posRect->b.x = [[(NSArray *)[(NSDictionary *)[dict objectForKey:key] objectForKey:@"scr_pos"] objectAtIndex:0] integerValue] + [[(NSArray *)[(NSDictionary *)[dict objectForKey:key] objectForKey:@"png_get"] objectAtIndex:2] integerValue];
    posRect->b.y = [[(NSArray *)[(NSDictionary *)[dict objectForKey:key] objectForKey:@"scr_pos"] objectAtIndex:1] integerValue];
    posRect->c.x = [[(NSArray *)[(NSDictionary *)[dict objectForKey:key] objectForKey:@"scr_pos"] objectAtIndex:0] integerValue];
    posRect->c.y = [[(NSArray *)[(NSDictionary *)[dict objectForKey:key] objectForKey:@"scr_pos"] objectAtIndex:1] integerValue] - [[(NSArray *)[(NSDictionary *)[dict objectForKey:key] objectForKey:@"png_get"] objectAtIndex:3] integerValue];
    posRect->d.x = [[(NSArray *)[(NSDictionary *)[dict objectForKey:key] objectForKey:@"scr_pos"] objectAtIndex:0] integerValue] + [[(NSArray *)[(NSDictionary *)[dict objectForKey:key] objectForKey:@"png_get"] objectAtIndex:2] integerValue];
    posRect->d.y = [[(NSArray *)[(NSDictionary *)[dict objectForKey:key] objectForKey:@"scr_pos"] objectAtIndex:1] integerValue] - [[(NSArray *)[(NSDictionary *)[dict objectForKey:key] objectForKey:@"png_get"] objectAtIndex:3] integerValue];
    
    texRect->origin.x = [[(NSArray *)[(NSDictionary *)[dict objectForKey:key] objectForKey:@"png_get"] objectAtIndex:0] integerValue]/textureAtlasWidth;
    texRect->origin.y = [[(NSArray *)[(NSDictionary *)[dict objectForKey:key] objectForKey:@"png_get"] objectAtIndex:1] integerValue]/textureAtlasHeight;
    texRect->size.width = [[(NSArray *)[(NSDictionary *)[dict objectForKey:key] objectForKey:@"png_get"] objectAtIndex:2] integerValue]/textureAtlasWidth;
    texRect->size.height = [[(NSArray *)[(NSDictionary *)[dict objectForKey:key] objectForKey:@"png_get"] objectAtIndex:3] integerValue]/textureAtlasHeight;
    
    color->red = 255;
    color->green = 255;
    color->blue = 255;
    color->alpha = 255;
    
    speed->x = 0;
    speed->y = 0;
}

- (void) initGameObjectSpriteStorage
{
    //Очищаем хранилище спрайтов
    [gameObjectSpriteStorage clear];
    
    //Загружаем карту
    short row = 0, col = 0;
    NSString* mapFileName = [[NSBundle mainBundle] pathForResource:mapName ofType:@"dat"];
    NSData *map = [[NSData alloc] initWithContentsOfFile:mapFileName];
    char *pMap = (char *)map.bytes;
    
    SRect rect;
    SImageSequence *imageSequence;
    SColor color;
    SSpeed speed;
    
    NSString *key;
    Byte type;
    
    for (short i = 0; i < map.length; i++)
    {
        col = i % 9;
        row = i / 9;
        key = @"";
        if (pMap[i] == 's') //Создаем неподвижный блок
        {
            key = @"static"; 
            type = 8;
        }
        else if (pMap[i] == 'a') //Все направления
        {
            key = @"left_right_up_down";
            type = 1;            
        }
        else if (pMap[i] == 'l') //Влево
        {
            key = @"left";
            type = 6;            
        }
        else if (pMap[i] == 'r') //Вправо
        {
            key = @"right";
            type = 7;            
        }
        else if (pMap[i] == 't') //Вверх
        {
            key = @"up";
            type = 4;            
        }
        else if (pMap[i] == 'b') //Вниз
        {
            key = @"down";
            type = 5;            
        }
        else if (pMap[i] == 'e') //Влево-вправо
        {
            key = @"left_right";
            type = 3;            
        }
        else if (pMap[i] == 'v') //Вверх-вниз
        {
            key = @"up_down";
            type = 2;            
        }
        
        if (key != @"")
        {
            imageSequence = malloc(sizeof(SImageSequence));
        
            [self getDataFromPlist:blocksDict ByKey:key ByTextureAtlasWidth:gameObjectSpriteStorage.textureAtlasWidth ByTextureAtlasHeight:gameObjectSpriteStorage.textureAtlasHeight InPos:&rect InTex:&imageSequence[0].images[0] InColor:&color InSpeed:&speed];
        
            rect.a.x = col*40;
            rect.a.y = 480 - (row*40);
            rect.b.x = rect.a.x + 40;
            rect.b.y = rect.a.y;
            rect.c.x = rect.a.x;
            rect.c.y = rect.a.y - 40;
            rect.d.x = rect.b.x;
            rect.d.y = rect.c.y;
        
            CBlock *sprite = [[CBlock alloc] initWithWGP:self WithRect:rect WithImageSequences:imageSequence WithImageSequenceCount:1 WithColor:color WithSpeed:speed WithType:type];
            [gameObjectSpriteStorage addSprite:sprite];
        }
    }
    
    //Загружаем щенка
    SImageSequence *dogImageSequence = malloc(sizeof(SImageSequence)*4);
    NSString *dicts[4] = {@"forward", @"back", @"right", @"left"};
    NSDictionary *moveDict;
    
    for (Byte j = 0; j < 4; j++)
    {
        moveDict = (NSDictionary *)[dogDict objectForKey:dicts[j]];
 
        for (short i = 1; i <= [moveDict count]; i++)
        {
            NSString *s = [NSString stringWithFormat:@"%d", i];
            [self getDataFromPlist:moveDict ByKey:s ByTextureAtlasWidth:gameObjectSpriteStorage.textureAtlasWidth ByTextureAtlasHeight:gameObjectSpriteStorage.textureAtlasHeight InPos:&rect InTex:&dogImageSequence[j].images[i - 1] InColor:&color InSpeed:&speed];
         
            //[s release];
        }
    }
    
    rect.a.x = 0;
    rect.a.y = DOG_SIZE;
    rect.b.x = rect.a.x + DOG_SIZE;
    rect.b.y = rect.a.y;
    rect.c.x = rect.a.x;
    rect.c.y = rect.a.y - DOG_SIZE;
    rect.d.x = rect.b.x;
    rect.d.y = rect.c.y;
    
    dogSprite = [[CDog alloc] initWithWGP:self WithRect:rect WithImageSequences:dogImageSequence WithImageSequenceCount:4 WithColor:color WithSpeed:speed];
    [gameObjectSpriteStorage addSprite:dogSprite];
    
    //Загружаем рамку
    SImageSequence *borderImageSequence = malloc(sizeof(SImageSequence));
    [self getDataFromPlist:blocksDict ByKey:@"border" ByTextureAtlasWidth:gameObjectSpriteStorage.textureAtlasWidth ByTextureAtlasHeight:gameObjectSpriteStorage.textureAtlasHeight InPos:&rect InTex:&borderImageSequence[0].images[0] InColor:&color InSpeed:&speed];
    
    rect.a.x = 0;
    rect.a.y = DOG_SIZE;
    rect.b.x = rect.a.x + DOG_SIZE;
    rect.b.y = rect.a.y;
    rect.c.x = rect.a.x;
    rect.c.y = rect.a.y - DOG_SIZE;
    rect.d.x = rect.b.x;
    rect.d.y = rect.c.y;
    
    color.alpha = 0;

    borderSprite = [[CSprite alloc] initWithWGP:self WithRect:rect WithImageSequences:borderImageSequence WithImageSequenceCount:1 WithColor:color WithSpeed:speed];
    borderSprite.name = @"border";
    [gameObjectSpriteStorage addSprite:borderSprite];
    
    //Загружаем мясо
    SImageSequence *meatImageSequence = malloc(sizeof(SImageSequence));
    [self getDataFromPlist:dogDict ByKey:@"meat" ByTextureAtlasWidth:gameObjectSpriteStorage.textureAtlasWidth ByTextureAtlasHeight:gameObjectSpriteStorage.textureAtlasHeight InPos:&rect InTex:&meatImageSequence[0].images[0] InColor:&color InSpeed:&speed];
    
    rect.a.x = 320 - DOG_SIZE;
    rect.a.y = 480;
    rect.b.x = rect.a.x + DOG_SIZE;
    rect.b.y = rect.a.y;
    rect.c.x = rect.a.x;
    rect.c.y = rect.a.y - DOG_SIZE;
    rect.d.x = rect.b.x;
    rect.d.y = rect.c.y;
    
    color.alpha = 255;
    
    meatSprite = [[CSprite alloc] initWithWGP:self WithRect:rect WithImageSequences:meatImageSequence WithImageSequenceCount:1 WithColor:color WithSpeed:speed];
    meatSprite.name = @"meat";
    [gameObjectSpriteStorage addSprite:meatSprite];

}

- (void) drawText:(NSString *)text InPos:(CGPoint)pos InSpriteStorage:(CSpriteStorage *)spriteStorage FromDict:(NSDictionary *)dict
{
    SRect charRect;
    SColor charColor;
    SSpeed charSpeed;
    
    SImageSequence *charImageSequence;
    
    //Проходим в цикле по буквам текста, создавая для каждой буквы свой спрайт
    for (int i = 0; i < text.length; i++)
    {
        charImageSequence = malloc(sizeof(SImageSequence));
        
        [self getDataFromPlist:dict ByKey:[text substringWithRange:NSMakeRange(i, 1)] ByTextureAtlasWidth:spriteStorage.textureAtlasWidth ByTextureAtlasHeight:spriteStorage.textureAtlasHeight InPos:&charRect InTex:&charImageSequence[0].images[0] InColor:&charColor InSpeed:&charSpeed];
        
        CGFloat w = charRect.b.x - charRect.a.x;
        CGFloat h = charRect.a.y - charRect.c.y;
        
        charRect.a.x += pos.x + i*w;
        charRect.a.y = pos.y;
        charRect.b.x = charRect.a.x + w;
        charRect.b.y = pos.y;
        charRect.c.x = charRect.a.x;
        charRect.c.y = charRect.a.y - h;
        charRect.d.x = charRect.a.x + w;
        charRect.d.y = charRect.a.y - h;
        
        CSprite *charSprite = [[CSprite alloc] initWithWGP:self WithRect:charRect WithImageSequences:charImageSequence WithImageSequenceCount:1 WithColor:charColor WithSpeed:charSpeed];
        
        [fpsSpriteStorage addSprite:charSprite];
    }
}

- (bool) isRect: (SRect)rect ContainsPoint: (CGPoint)point
{
    if (point.x > rect.a.x && point.x < rect.b.x && point.y > rect.c.y && point.y < rect.a.y)
        return (true);
    
    return (false);
}

- (int) calcFPS
{
    static int m_nFps; // current FPS
    static CFTimeInterval lastFrameStartTime; 
    static int m_nAverageFps; // the average FPS over 15 frames
    static int m_nAverageFpsCounter;
    static int m_nAverageFpsSum;
    
    CFTimeInterval thisFrameStartTime = CFAbsoluteTimeGetCurrent();
    float deltaTimeInSeconds = thisFrameStartTime - lastFrameStartTime;
    m_nFps = (deltaTimeInSeconds == 0) ? 0: 1 / (deltaTimeInSeconds);
    
    m_nAverageFpsCounter++;
    m_nAverageFpsSum+=m_nFps;
    if (m_nAverageFpsCounter >= 15) // calculate average FPS over 15 frames
    {
        m_nAverageFps = m_nAverageFpsSum/m_nAverageFpsCounter;
        m_nAverageFpsCounter = 0;
        m_nAverageFpsSum = 0;
    }
   
    lastFrameStartTime = thisFrameStartTime;
    
    return (m_nAverageFps);
}

- (void) drawOptions
{
}


-(void) accelerometerProcess:(double)x :(double)y :(double)z
{
    SAccelerometerMessage accelerometerMessage;
    accelerometerMessage.x = x;
    accelerometerMessage.y = y;
    accelerometerMessage.z = z;
    
    [controlMessageStack pushAccelerometerMessage:accelerometerMessage];   
}

-(CGSize) getBackingSize
{
    CGSize size;
    size.width = backingWidth;
    size.height = backingHeight;
    
    return (size);
}

-(void) startButtonPressed
{
 
}

- (CBlock *) getBlockByPoint:(CGPoint)location
{
    for (short i = 0; i < gameObjectSpriteStorage.count; i++)
    {
        CSprite *sprite = [gameObjectSpriteStorage getSpriteByIndex:i];
        if ([sprite getType] == @"CBlock" && [sprite isOwneredByPoint:location])
            return ((CBlock *)sprite);
    }
    
    return (nil);
}

- (ushort) getBlockCount
{
    ushort blockCount = 0;
    for (ushort i = 0; i < gameObjectSpriteStorage.count; i++)
        if ([[gameObjectSpriteStorage getSpriteByIndex:i] getType] == @"CBlock")
            blockCount++;
        
    return (blockCount);
}

- (SRect) getBlockRectByIndex:(ushort)index
{
    ushort blockIndex = 0;
    for (ushort i = 0; i < gameObjectSpriteStorage.count; i++)
    {
        if ([[gameObjectSpriteStorage getSpriteByIndex:i] getType] == @"CBlock")
        {
            blockIndex++;
            if (blockIndex == index)
                return ([gameObjectSpriteStorage getSpriteByIndex:i].rect);
        }
    }
    
    SRect r;
    memset(&r, 0, sizeof(SRect));
    return (r);
}

- (SRect) getScreenRect
{
    SRect rect;
    rect.a.x = 0;
    rect.a.y = backingHeight;
    rect.b.x = backingWidth;
    rect.b.y = backingHeight;
    rect.c.x = 0;
    rect.c.y = 0;
    rect.d.x = backingWidth;
    rect.d.y = 0;
    
    return (rect);
}

- (SRect) getGameFieldRect
{
    SRect rect;
    rect.a.x = 0;
    rect.a.y = backingHeight;
    rect.b.x = backingWidth;
    rect.b.y = backingHeight;
    rect.c.x = 0;
    rect.c.y = 0;
    rect.d.x = backingWidth;
    rect.d.y = 0;
    
    return (rect);
}

- (CGPoint) getBlockArrayIndexByIndex:(ushort)index
{
    ushort blockIndex = 0;
    for (ushort i = 0; i < gameObjectSpriteStorage.count; i++)
    {
        if ([[gameObjectSpriteStorage getSpriteByIndex:i] getType] == @"CBlock")
        {
            blockIndex++;
            CBlock *blockSprite = (CBlock *)[gameObjectSpriteStorage getSpriteByIndex:i];
            if (blockIndex == index)
                return (CGPointMake(blockSprite.col, blockSprite.row));
        }
    }
    
    CGPoint p;
    p.x = -1;
    p.y = -1;
    return (p);
}

- (NSObject *) getDogSprite
{
    return (dogSprite);
}

- (void) hideBorderDogSprite
{
    SColor color = borderSprite.color;
    color.alpha = 0;
    borderSprite.color = color;
}


@end















