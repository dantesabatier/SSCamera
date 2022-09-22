//
//  SSCameraButton.h
//  SSCamera
//
//  Created by Dante Sabatier on 01/09/16.
//  Copyright © 2016 Dante Sabatier. All rights reserved.
//

#import <TargetConditionals.h>
#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#else
#import <Cocoa/Cocoa.h>
#endif

NS_ASSUME_NONNULL_BEGIN

#if TARGET_OS_IPHONE
@interface SSCameraButton : UIButton
#else
@interface SSCameraButton : NSButton
#endif

@end

NS_ASSUME_NONNULL_END
