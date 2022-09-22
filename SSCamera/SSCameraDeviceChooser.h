//
//  SSCameraDeviceChooser.h
//  SSCamera
//
//  Created by Dante Sabatier on 10/10/12.
//  Copyright (c) 2012 Dante Sabatier. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/NSArrayController.h>
#import <AppKit/NSTableView.h>
#import <AppKit/NSWindowController.h>
#import <SSBase/SSDefines.h>

@class AVCaptureDevice;

NS_ASSUME_NONNULL_BEGIN

NS_CLASS_AVAILABLE_MAC(10_7)
@interface SSCameraDeviceChooser : NSWindowController {
@private
    IBOutlet NSArrayController *devicesArrayController;
    IBOutlet NSTableView *devicesTableView;
    NSString *_helpAnchor;
    BOOL _showsHelp;
}

@property (class, readonly, strong) SSCameraDeviceChooser *sharedCameraDeviceChooser SS_CONST;
@property (nonatomic, assign) BOOL showsHelp;
@property (nullable, nonatomic, copy) NSString *helpAnchor;
@property (nullable, nonatomic, readonly, strong) NSArray <AVCaptureDevice *>*devices;
@property (nullable, nonatomic, readonly, strong) AVCaptureDevice *selectedDevice;
#if defined(__MAC_10_9)
@property (nonatomic, readonly) NSModalResponse runModal;
#else
@property (nonatomic, readonly) NSInteger runModal;
#endif
- (void)showWindow:(nullable id)sender SS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
