//
//  SSCameraWindowController.m
//  SSCamera
//
//  Created by Dante Sabatier on 19/05/13.
//  Copyright (c) 2013 Dante Sabatier. All rights reserved.
//

#import "SSCameraWindowController.h"
#import "SSCameraPanel.h"
#import <SSBase/SSDefines.h>

static BOOL __kSSSharedCameraWindowControllerCanBeDestroyed = NO;

@interface SSCameraWindowController () 

@end

@implementation SSCameraWindowController

static SSCameraWindowController * sharedCameraWindowController = nil;

+ (SSCameraWindowController*)sharedCameraWindowController {
#if defined(__MAC_10_6)
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedCameraWindowController = [[self alloc] init];
        __block __unsafe_unretained id observer = [[NSNotificationCenter defaultCenter] addObserverForName:NSApplicationWillTerminateNotification object:NSApp queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
            [[NSNotificationCenter defaultCenter] removeObserver:observer];
            
            __kSSSharedCameraWindowControllerCanBeDestroyed = YES;
            
            [sharedCameraWindowController release];
        }];
    });
#endif
	return sharedCameraWindowController;
}

+ (BOOL)sharedCameraWindowControllerExists {
    return sharedCameraWindowController != nil;
}

- (instancetype)init {
    SSCameraPanel *panel = [[[SSCameraPanel alloc] init] autorelease];
    panel.title = SSLocalizedString(@"Camera", @"camera window title");
    self = [super initWithWindow:panel];
    if (self) {
        _cameraViewController = [[SSCameraViewController alloc] init];
        _cameraViewController.cameraIrisAnimationBlock = ^(__kindof SSCameraViewController *cameraViewController) {
            if (!cameraViewController.isCameraIrisHollowOpen) {
                [self close];
            }
        };
        NSView *contentView = self.window.contentView;
        NSView *scannerView = _cameraViewController.view;
        scannerView.frame = contentView.bounds;
        [contentView addSubview:scannerView];
        
        self.window.delegate = self;
    }
    return self;
}

- (void)dealloc {
    if ((self == sharedCameraWindowController) && !__kSSSharedCameraWindowControllerCanBeDestroyed) {
        return;
    }
    
	[self close];
    
    _cameraViewController.cameraIrisAnimationBlock = nil;
    [_cameraViewController release];
	
    [super ss_dealloc];
}

- (void)showWindow:(id)sender {
    NSError *error = nil;
    if ([_cameraViewController startRunning:&error]) {
        if (!self.window.frameAutosaveName.length) {
            [self.window setFrameAutosaveName:NSStringFromClass(self.class)];
        }
        [super showWindow:sender];
        return;
    }
    if (error) {
        [self presentError:error];
    }
}

#pragma mark NSWindowDelegate

- (BOOL)windowShouldClose:(id)window {
    [_cameraViewController stopRunning];
	return NO;
}

#pragma mark getters & setters

- (SSCameraViewController *)cameraViewController {
    return _cameraViewController;
}

@end

