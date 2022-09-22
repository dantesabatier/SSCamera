//
//  SSCameraDeviceChooser.m
//  SSCamera
//
//  Created by Dante Sabatier on 10/10/12.
//  Copyright (c) 2012 Dante Sabatier. All rights reserved.
//

#import "SSCameraDeviceChooser.h"
#import "SSCameraWindowController.h"
#import "SSCameraConstants.h"
#import <AVFoundation/AVFoundation.h>

static BOOL __kSharedCaptureDeviceChooserCanBeDestroyed = NO;

@implementation SSCameraDeviceChooser

static SSCameraDeviceChooser *sharedCameraDeviceChooser = nil;

+ (instancetype)sharedCameraDeviceChooser {
#if defined(__MAC_10_6)
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedCameraDeviceChooser = [[self alloc] init];
        __block __unsafe_unretained id observer = [[NSNotificationCenter defaultCenter] addObserverForName:NSApplicationWillTerminateNotification object:NSApp queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
            [[NSNotificationCenter defaultCenter] removeObserver:observer];
            
            __kSharedCaptureDeviceChooserCanBeDestroyed = YES;
            
            [sharedCameraDeviceChooser release];
        }];
    });
#endif
	return sharedCameraDeviceChooser;
}

- (instancetype)init {
	self = [super initWithWindowNibName:NSStringFromClass(self.class) owner:self];
	if (self) {
#if defined(__MAC_10_7)
        if (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_6) {
            self.window.animationBehavior = NSWindowAnimationBehaviorAlertPanel;
        }
#endif
	}
	return self;
}

- (void)dealloc {
    if (self == sharedCameraDeviceChooser && !__kSharedCaptureDeviceChooserCanBeDestroyed) {
        return;
    }
    
    [super ss_dealloc];
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    NSMutableArray *devices = [NSMutableArray array];
    [devices addObjectsFromArray:[AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]];
    [devices addObjectsFromArray:[AVCaptureDevice devicesWithMediaType:AVMediaTypeMuxed]];
    
    devicesArrayController.content = devices;
}

#pragma mark actions

- (IBAction)ok:(id)sender {
	[NSApp stopModalWithCode:NSOKButton];
    AVCaptureDevice *device = self.selectedDevice;
    if (device) {
        if ([[NSUserDefaults standardUserDefaults] boolForKey:SSCameraViewControllerShouldRememberSelectedDevicePreferencesKey]) {
            [[NSUserDefaults standardUserDefaults] setObject:device.uniqueID forKey:SSCameraViewControllerSelectedDeviceUniqueIDPreferencesKey];
        } else {
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:SSCameraViewControllerSelectedDeviceUniqueIDPreferencesKey];
        }  
    }
}

- (IBAction)cancel:(id)sender {
	[NSApp stopModalWithCode:NSCancelButton];
}

- (IBAction)showHelp:(id)sender {
    NSString *helpAnchor = self.helpAnchor;
    if (helpAnchor.length) {
        [[NSHelpManager sharedHelpManager] openHelpAnchor:helpAnchor inBook:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleHelpBookName"]];
    }
}

#pragma mark getters & setters

- (NSArray <AVCaptureDevice *>*)devices {
    return devicesArrayController.arrangedObjects;
}

- (void)setDevices:(NSArray <AVCaptureDevice *>*)devices {
    devicesArrayController.content = devices;
}

- (AVCaptureDevice *)selectedDevice {
    if (devicesArrayController.selectionIndex != NSNotFound) {
        return devicesArrayController.arrangedObjects[devicesArrayController.selectionIndex];
    }
    return nil;
}

- (NSString *)helpAnchor {
    return _helpAnchor;
}

- (void)setHelpAnchor:(NSString *)helpAnchor {
    SSNonAtomicCopiedSet(_helpAnchor, helpAnchor);
}

- (BOOL)showsHelp {
    return _showsHelp;
}

- (void)setShowsHelp:(BOOL)showsHelp {
    _showsHelp = showsHelp;
}

#if defined(__MAC_10_9)
- (NSModalResponse)runModal
#else
- (NSInteger)runModal
#endif
{
	[self.window center];
#if defined(__MAC_10_9)
    if (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_8) {
        self.window.appearance = [NSApplication sharedApplication].mainWindow.appearance;
    }
#endif
	[self.window makeKeyAndOrderFront:self];
#if defined(__MAC_10_9)
    NSModalResponse response;
#else
    NSInteger response;
#endif
    response = [NSApp runModalForWindow:self.window];
	[self.window orderOut:nil];
	return response;
}

@end

