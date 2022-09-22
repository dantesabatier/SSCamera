//
//  SSCameraConstants.h
//  SSCamera
//
//  Created by Dante Sabatier on 22/01/13.
//  Copyright (c) 2013 Dante Sabatier. All rights reserved.
//

#import <TargetConditionals.h>
#import <Foundation/Foundation.h>
#if TARGET_OS_IPHONE
#import <UIKit/UIGeometry.h>
#endif

extern NSString *const SSCameraViewControllerShouldRememberSelectedDevicePreferencesKey;
extern NSString *const SSCameraViewControllerSelectedDeviceUniqueIDPreferencesKey;
extern const CGRect SSCameraViewControllerDefaultContentRect;
extern const CGFloat SSCameraViewTorchButtonSize;
extern const CGFloat SSCameraViewTorchButtonInset;
