//
//  SSCameraPanel.m
//  SSCamera
//
//  Created by Dante Sabatier on 03/11/12.
//  Copyright (c) 2012 Dante Sabatier. All rights reserved.
//

#import "SSCameraPanel.h"
#import "SSCameraConstants.h"
#import <SSBase/SSDefines.h>

#define __HUD 1

@implementation SSCameraPanel

- (instancetype)init {
    NSScreen *screen = NSApplication.sharedApplication.mainWindow.screen;
    if (!screen) {
        screen = NSScreen.mainScreen;
    }
    
    CGSize contentSize = SSCameraViewControllerDefaultContentRect.size;
    NSUInteger styleMask = NSTitledWindowMask|NSClosableWindowMask|NSUtilityWindowMask;
#if __HUD
    styleMask |= NSHUDWindowMask;
#endif
    self = [self initWithContentRect:NSMakeRect(20.0, FLOOR(CGRectGetMaxY(screen.frame) - (contentSize.height + 60.0)), contentSize.width, contentSize.height) styleMask:styleMask backing:NSBackingStoreBuffered defer:YES];
    if (self) {
        self.releasedWhenClosed = NO;
        self.oneShot = NO;
#if defined(__MAC_10_7)
        if (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_6) {
            self.animationBehavior = NSWindowAnimationBehaviorNone;
            self.collectionBehavior = NSWindowCollectionBehaviorFullScreenAuxiliary;
#if defined(__MAC_10_10)
            if (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_9) {
                self.titleVisibility = NSWindowTitleHidden;
                self.titlebarAppearsTransparent = YES;
                self.styleMask |= NSFullSizeContentViewWindowMask;
            }
#endif
        }
#endif
    }
    return self;
}

#if __HUD

- (BOOL)canBecomeKeyWindow {
    return NO;
}

#endif

@end
