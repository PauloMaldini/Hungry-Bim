//
//  AppDelegate.h
//  Hungry Bim
//
//  Created by Konstantin Tsymbalist on 25.02.12.
//  Copyright (c) 2012 Home. All rights reserved.
//

#import <UIKit/UIKit.h>

@class EAGLView;

@interface AppDelegate : UIResponder <UIApplicationDelegate>
{
    UIWindow *window;
    EAGLView *glView;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet EAGLView *glView;

@end
