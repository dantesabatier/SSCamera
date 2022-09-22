//
//  SSCameraViewController.h
//  SSCamera
//
//  Created by Dante Sabatier on 18/05/13.
//  Copyright (c) 2013 Dante Sabatier. All rights reserved.
//

#import <TargetConditionals.h>
#import "SSCameraErrors.h"
#import "SSCameraPreviewView.h"
#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#import <base/SSGeometry.h>
#else
#import <Cocoa/Cocoa.h>
#import <SSBase/SSGeometry.h>
#endif
#import <CoreVideo/CVImageBuffer.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@class SSCameraViewController;

typedef NS_ENUM(NSInteger, SSCameraViewControllerFocusMethod) {
    SSCameraViewControllerFocusMethodAutomatic = -1,
    SSCameraViewControllerFocusMethodTopLeft = SSRectPositionLeftTop,
    SSCameraViewControllerFocusMethodTopCenter = SSRectPositionBottomRight,
    SSCameraViewControllerFocusMethodTopRight = SSRectPositionRightTop,
    SSCameraViewControllerFocusMethodBottomLeft = SSRectPositionTopRight,
    SSCameraViewControllerFocusMethodBottomCenter = SSRectPositionLeftBottom,
    SSCameraViewControllerFocusMethodBottomRight = SSRectPositionBottomLeft,
    SSCameraViewControllerFocusMethodLeftCenter = SSRectPositionRightBottom,
    SSCameraViewControllerFocusMethodRightCenter = SSRectPositionTopLeft,
    SSCameraViewControllerFocusMethodCenter = SSRectPositionCenter,
} NS_SWIFT_NAME(SSCameraViewController.CameraFocusMethod);

typedef void (^SSCameraViewControllerImageProviderBlock)(__kindof SSCameraViewController *cameraViewController, CVImageBufferRef __nullable imageBuffer, void (^__nullable original)(CGImageRef __nullable original), void (^__nullable modified)(CGImageRef __nullable modified));
typedef void (^SSCameraViewControllerCameraIrisAnimationBlock)(__kindof SSCameraViewController *cameraViewController);

@protocol SSCameraViewControllerImageProvider <NSObject>

- (nullable CGImageRef)cameraViewController:(__kindof SSCameraViewController *)cameraViewController imageFromImageBuffer:(nullable CVImageBufferRef)imageBuffer;

@end

#if TARGET_OS_IPHONE
NS_CLASS_AVAILABLE(NA, 4_0)
@interface SSCameraViewController : UIViewController
#else
NS_CLASS_AVAILABLE(10_7, NA)
@interface SSCameraViewController : NSViewController
#endif
{
@private
    AVCaptureSession *_session;
    AVCaptureDevice *_device;
    AVCaptureConnection *_connection;
    CFAbsoluteTime _timestamp;
    double _clockFrequency;
    SSCameraViewControllerFocusMethod _focusMethod;
    NSTimeInterval _minimumCaptureInterval;
    __ss_weak id <SSCameraViewControllerImageProvider> _imageProvider;
    SSCameraViewControllerImageProviderBlock _imageProviderBlock;
    SSCameraViewControllerCameraIrisAnimationBlock _cameraIrisAnimationBlock;
    BOOL _showsCameraIrisAnimation;
}

@property (nullable, nonatomic, ss_weak) id <SSCameraViewControllerImageProvider> imageProvider;
@property (nullable, copy) SSCameraViewControllerImageProviderBlock imageProviderBlock;
@property (nullable, copy) SSCameraViewControllerCameraIrisAnimationBlock cameraIrisAnimationBlock;
@property (nonatomic, assign) SSCameraViewControllerFocusMethod focusMethod;
@property (nonatomic, assign) NSTimeInterval minimumCaptureInterval;
@property (nonatomic, assign, readonly) BOOL hasTorch;
@property (nonatomic, assign, getter=isTorched) BOOL torched NS_AVAILABLE(10_7, 6_0);
@property (nonatomic, readonly, getter=isRunning) BOOL running;
@property (nonatomic, assign) BOOL showsDeviceName;
@property (nonatomic, assign) BOOL showsCameraIrisAnimation;
@property (nonatomic, readonly, getter=isCameraIrisHollowOpen) BOOL cameraIrisHollowOpen;
- (BOOL)startRunning:(__autoreleasing NSError *__nullable * __nullable)error NS_REQUIRES_SUPER;
- (void)stopRunning NS_REQUIRES_SUPER;
- (BOOL)processImage:(__nullable CGImageRef)image NS_REQUIRES_SUPER;

@end

NS_ASSUME_NONNULL_END
