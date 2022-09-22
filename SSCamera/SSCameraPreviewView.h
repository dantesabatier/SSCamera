//
//  SSCameraPreviewView.h
//  SSCamera
//
//  Created by Dante Sabatier on 19/04/12.
//  Copyright (c) 2012 Dante Sabatier. All rights reserved.
//

#import "SSCameraIrisView.h"
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SSCameraPreviewView : SSCameraLayoutView {
@private
    SSCameraView *_contentView;
    SSCameraIrisView *_cameraIrisView;
    AVCaptureVideoPreviewLayer *_previewLayer;
    CALayer *_imageLayer;
    CATextLayer *_deviceLayer;
    BOOL _showsDeviceName;
    BOOL _showsCameraIris;
    BOOL _hasTorch;
}

@property (nullable, nonatomic, readonly, ss_strong) SSCameraView *contentView;
@property (nullable, nonatomic, readonly, ss_strong) SSCameraIrisView *cameraIrisView;
@property (nullable, nonatomic, readonly, ss_strong) AVCaptureVideoPreviewLayer *previewLayer;
@property (nullable, nonatomic, strong) AVCaptureSession *session;
- (void)setCameraIrisHollowOpen:(BOOL)cameraIrisHollowOpen animated:(BOOL)animated completion:(void(^__nullable)(void))completion;
- (void)setCameraIrisHollowOpen:(BOOL)cameraIrisHollowOpen animated:(BOOL)animated;
@property (nonatomic, getter=isCameraIrisHollowOpen, assign) BOOL cameraIrisHollowOpen;
@property (nonatomic, assign) BOOL showsDeviceName;
@property (nonatomic, assign, readonly) BOOL hasTorch;
@property (nonatomic, getter=isTorched, assign) BOOL torched NS_AVAILABLE(10_7, 6_0);
@property (nullable, nonatomic, strong) id image;

@end

NS_ASSUME_NONNULL_END
