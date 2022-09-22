//
//  SSCameraView.h
//  SSCamera
//
//  Created by Dante Sabatier on 01/09/16.
//  Copyright © 2016 Dante Sabatier. All rights reserved.
//

#import <TargetConditionals.h>
#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#import <graphics/SSGraphics.h>
#else
#import <Cocoa/Cocoa.h>
#import <SSGraphics/SSGraphics.h>
#endif
#import <QuartzCore/QuartzCore.h>

NS_ASSUME_NONNULL_BEGIN

#if TARGET_OS_IPHONE
@interface SSCameraView : UIView <CALayerDelegate>
#else
@interface SSCameraView : NSView <CALayerDelegate>
#endif

#if TARGET_OS_IPHONE
@property (nonatomic, readonly, ss_strong) CALayer *makeBackingLayer;
#endif

@end

NS_ASSUME_NONNULL_END
