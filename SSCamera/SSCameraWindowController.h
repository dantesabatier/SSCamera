//
//  SSCameraWindowController.h
//  SSCamera
//
//  Created by Dante Sabatier on 19/05/13.
//  Copyright (c) 2013 Dante Sabatier. All rights reserved.
//

#import "SSCameraViewController.h"

NS_ASSUME_NONNULL_BEGIN

NS_CLASS_AVAILABLE_MAC(10_7)
@interface SSCameraWindowController : NSWindowController <NSWindowDelegate> {
@private
    SSCameraViewController *_cameraViewController;
}

@property (class, readonly, strong) SSCameraWindowController *sharedCameraWindowController SS_CONST;
@property (class, readonly, assign) BOOL sharedCameraWindowControllerExists;
@property (nonatomic, strong, readonly) SSCameraViewController *cameraViewController;

@end

NS_ASSUME_NONNULL_END
