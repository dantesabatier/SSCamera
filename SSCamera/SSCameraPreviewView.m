//
//  SSCameraPreviewView.m
//  SSCamera
//
//  Created by Dante Sabatier on 19/04/12.
//  Copyright (c) 2012 Dante Sabatier. All rights reserved.
//

#import "SSCameraPreviewView.h"
#import "SSCameraConstants.h"
#import "SSCameraIrisView.h"
#import "SSCameraButton.h"

#define SSCameraViewTorchButtonBounds CGRectMake(CGRectGetMinX(self.bounds) + SSCameraViewTorchButtonInset, CGRectGetMinY(self.bounds) + (SSCameraViewTorchButtonInset*2.0), SSCameraViewTorchButtonSize, SSCameraViewTorchButtonSize)

@interface SSCameraPreviewView ()

@property (nullable, nonatomic, readwrite, ss_strong) AVCaptureVideoPreviewLayer *previewLayer;
@property (nullable, nonatomic, ss_strong) CATextLayer *deviceLayer;
@property (nullable, nonatomic, strong) CALayer *imageLayer;

@end

@implementation SSCameraPreviewView

- (instancetype)initWithFrame:(CGRect)frameRect {
	self = [super initWithFrame:frameRect];
	if (self) {
#if TARGET_OS_IPHONE
        self.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleBottomMargin;
        self.userInteractionEnabled = YES;
#if TARGET_OS_SIMULATOR
        _hasTorch = YES;
#endif
#else
        self.autoresizingMask = NSViewMinXMargin|NSViewWidthSizable|NSViewMaxXMargin|NSViewMinYMargin|NSViewHeightSizable|NSViewMaxYMargin;
#endif
	}
	return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
#if TARGET_OS_IPHONE
        self.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleBottomMargin;
        self.userInteractionEnabled = YES;
#if TARGET_OS_SIMULATOR
        _hasTorch = YES;
#endif
#else
        self.autoresizingMask = NSViewMinXMargin|NSViewWidthSizable|NSViewMaxXMargin|NSViewMinYMargin|NSViewHeightSizable|NSViewMaxYMargin;
#endif
    }
    return self;
}

- (void)dealloc {
    [_contentView release];
    [_cameraIrisView release];
    [_previewLayer release];
    [_imageLayer release];
    [_deviceLayer release];
    
    [super ss_dealloc];
}

- (void)layout {
    [super layout];
    
    _contentView.frame = self.bounds;
    for (__kindof SSCameraView * _Nonnull subview in _contentView.subviews) {
        subview.frame = _contentView.bounds;
    }
    _cameraIrisView.frame = self.bounds;
    _previewLayer.frame = self.layer.bounds;
    _imageLayer.frame = self.layer.bounds;
}

#pragma mark actions

- (IBAction)torch:(id)sender {
    self.torched = !self.isTorched;
}

#if TARGET_OS_IPHONE

#pragma mark UIView

- (void)didMoveToSuperview {
    [super didMoveToSuperview];
    
    CALayer *backingLayer = self.makeBackingLayer;
    CALayer *layer = self.layer;
    layer.opaque = backingLayer.isOpaque;
    layer.backgroundColor = backingLayer.backgroundColor;
    layer.actions = backingLayer.actions;
    layer.sublayers = [[backingLayer.sublayers copy] autorelease];
    
    if (!_contentView) {
        _contentView = [[SSCameraView alloc] initWithFrame:self.bounds];
        _contentView.autoresizingMask = self.autoresizingMask;
        [self addSubview:_contentView];
    }
    
    if (!_cameraIrisView) {
        _cameraIrisView = [[SSCameraIrisView alloc] initWithFrame:self.bounds];
        [self addSubview:_cameraIrisView];
    }
}

#else

#pragma mark NSView

- (void)viewDidMoveToSuperview {
    [super viewDidMoveToSuperview];
    
    if (!self.wantsLayer) {
        self.wantsLayer = YES;
    }
    
    if (!_contentView) {
        _contentView = [[SSCameraView alloc] initWithFrame:self.bounds];
        _contentView.autoresizingMask = self.autoresizingMask;
        [self addSubview:_contentView];
    }
    
    if (!_cameraIrisView) {
        _cameraIrisView = [[SSCameraIrisView alloc] initWithFrame:self.bounds];
        _cameraIrisView.autoresizingMask = self.autoresizingMask;
        [self addSubview:_cameraIrisView];
    }
}

#endif

#pragma mark getters & setters

- (CALayer *)makeBackingLayer {
    CGFloat scale = 1.0;
#if TARGET_OS_IPHONE
    scale = [UIScreen mainScreen].scale;
#else
#if defined(__MAC_10_7)
    if (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_6) {
        scale = CGRectGetWidth([self convertRectToBacking:self.bounds])/CGRectGetWidth(self.bounds);
    }
#endif
#endif
    CALayer *layer = [CALayer layer];
    layer.backgroundColor = SSColorGetBlackColor();
    layer.opaque = YES;
    
    AVCaptureVideoPreviewLayer *previewLayer = [AVCaptureVideoPreviewLayer layer];
    previewLayer.name = @"previewLayer";
    previewLayer.contentsGravity = kCAGravityResizeAspectFill;
    previewLayer.connection.videoMirrored = YES;
#if TARGET_OS_IPHONE
    previewLayer.frame = self.layer.bounds;
#else
    previewLayer.autoresizingMask = kCALayerWidthSizable|kCALayerHeightSizable;
    previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    previewLayer.connection.automaticallyAdjustsVideoMirroring = NO;
#endif
    previewLayer.hidden = YES;
    
    [layer addSublayer:previewLayer];
    
    CATextLayer *deviceLayer = [CATextLayer layer];
    deviceLayer.name = @"deviceLayer";
    deviceLayer.alignmentMode = kCAAlignmentNatural;
    deviceLayer.truncationMode = kCATruncationEnd;
    if ([deviceLayer respondsToSelector:@selector(setContentsScale:)]) {
        deviceLayer.contentsScale = scale*2.0;
    }
    deviceLayer.fontSize = 11.0;
#if TARGET_OS_IPHONE
    deviceLayer.font = (__bridge CFTypeRef)[UIFont boldSystemFontOfSize:deviceLayer.fontSize];
#else
    deviceLayer.font = (__bridge CFTypeRef)([NSFont boldSystemFontOfSize:deviceLayer.fontSize]);
#endif
    deviceLayer.anchorPoint = CGPointZero;
    deviceLayer.frame = CGRectMake(CGRectGetMinX(self.bounds) + 10.0, CGRectGetMaxY(self.bounds) - 20.0, CGRectGetWidth(self.bounds) - 20.0, 20);
    deviceLayer.foregroundColor = SSColorGetWhiteColor();
#if !TARGET_OS_IPHONE
    [deviceLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMinY relativeTo:@"superlayer" attribute:kCAConstraintMinY offset:10]];
    [deviceLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMinX relativeTo:@"superlayer" attribute:kCAConstraintMinX offset:10]];
#endif
#if TARGET_OS_IPHONE && TARGET_OS_SIMULATOR
    deviceLayer.string = @"Simulator";
#endif
    deviceLayer.opacity = 0.0;
    
    [layer addSublayer:deviceLayer];
    
    CALayer *imageLayer = [CALayer layer];
    imageLayer.name = @"imageLayer";
    imageLayer.backgroundColor = layer.backgroundColor;
    imageLayer.opaque = YES;
    imageLayer.contentsGravity = kCAGravityResizeAspectFill;
#if TARGET_OS_IPHONE
    imageLayer.frame = previewLayer.bounds;
    imageLayer.transform = CATransform3DRotate(CATransform3DIdentity, M_PI/2.0, 0, 0, 1);
#else
    imageLayer.autoresizingMask = kCALayerWidthSizable|kCALayerHeightSizable;
    imageLayer.transform = CATransform3DMakeScale(-1.0, 1.0, 1.0);
#endif
    
    [layer insertSublayer:imageLayer above:previewLayer];
    
    CATextLayer *barcodeLayer = [CATextLayer layer];
    barcodeLayer.name = @"barcodeLayer";
    barcodeLayer.anchorPoint = CGPointZero;
    barcodeLayer.backgroundColor = SSAutorelease(SSColorCreateDeviceGray(0, 0.5));
    barcodeLayer.foregroundColor = SSColorGetWhiteColor();
    barcodeLayer.fontSize = 22.0;
#if TARGET_OS_IPHONE
    barcodeLayer.font = (__bridge CFTypeRef)[UIFont boldSystemFontOfSize:barcodeLayer.fontSize];
#else
    barcodeLayer.font = (__bridge CFTypeRef)([NSFont boldSystemFontOfSize:barcodeLayer.fontSize]);
#endif
    barcodeLayer.alignmentMode = kCAAlignmentCenter;
    barcodeLayer.truncationMode = kCATruncationEnd;
    if ([barcodeLayer respondsToSelector:@selector(setContentsScale:)]) {
        barcodeLayer.contentsScale = scale*2.0;
    }
    barcodeLayer.opacity = 0.0;
    
    [layer addSublayer:barcodeLayer];
    
    self.previewLayer = previewLayer;
    self.imageLayer = imageLayer;
    self.deviceLayer = deviceLayer;
    
    return layer;
}

- (AVCaptureVideoPreviewLayer *)previewLayer {
    return _previewLayer;
}

- (void)setPreviewLayer:(AVCaptureVideoPreviewLayer *)previewLayer {
    SSNonAtomicRetainedSet(_previewLayer, previewLayer);
}

- (CATextLayer *)deviceLayer {
    return _deviceLayer;
}

- (void)setdeviceLayer:(CATextLayer *)deviceLayer {
    SSNonAtomicRetainedSet(_deviceLayer, deviceLayer);
}

- (AVCaptureSession *)session {
    return _previewLayer.session;
}

- (void)setSession:(AVCaptureSession *)session {
    NSString *deviceName = nil;
    if (_showsDeviceName) {
        deviceName = ((AVCaptureDeviceInput *)session.inputs.lastObject).device.localizedName;
#if !TARGET_OS_IPHONE
        if (session && !deviceName) {
            deviceName = SSLocalizedString(@"External Camera", @"default capture device name");
        }
#endif
    }
    
    if (!deviceName) {
        deviceName = @"";
    }
    
    _deviceLayer.string = deviceName;
    _previewLayer.session = session;
    _hasTorch = session ? (((AVCaptureDeviceInput *)session.inputs.lastObject).device.hasTorch ? YES : NO) : NO;
}

- (BOOL)isCameraIrisHollowOpen {
    return _cameraIrisView.isCameraIrisHollowOpen;
}

- (void)setCameraIrisHollowOpen:(BOOL)cameraIrisHollowOpen animated:(BOOL)animated completion:(void(^__nullable)(void))completion {
    if (self.isCameraIrisHollowOpen == cameraIrisHollowOpen) {
        return;
    }
    
    [_cameraIrisView setCameraIrisHollowOpen:cameraIrisHollowOpen animated:animated completion:^{
        if (!cameraIrisHollowOpen) {
            _imageLayer.contents = (__bridge id)SSAutorelease(SSImageCreateWithColor(SSColorGetBlackColor(), SSSizeMakeSquare(1.0)));
        }
        if (completion) {
            completion();
        }
    }];
    
    if (!cameraIrisHollowOpen) {
        _imageLayer.contents = (__bridge id)SSAutorelease(SSImageCreateWithColor(SSColorGetBlackColor(), SSSizeMakeSquare(1.0)));
    }
}

- (void)setCameraIrisHollowOpen:(BOOL)cameraIrisHollowOpen animated:(BOOL)animated {
    [self setCameraIrisHollowOpen:cameraIrisHollowOpen animated:animated completion:nil];
}

- (void)setCameraIrisHollowOpen:(BOOL)cameraIrisHollowOpen {
    [self setCameraIrisHollowOpen:cameraIrisHollowOpen animated:NO];
}

- (BOOL)showsDeviceName {
    return _showsDeviceName;
}

- (void)setShowsDeviceName:(BOOL)showsDeviceName {
    _showsDeviceName = showsDeviceName;
    _deviceLayer.opacity = showsDeviceName ? 1.0 : 0.0;
}

- (BOOL)hasTorch {
    return _hasTorch;
}

- (BOOL)isTorched {
    AVCaptureDevice *device = ((AVCaptureDeviceInput *)_previewLayer.session.inputs.lastObject).device;
#if TARGET_OS_IPHONE
    return device.hasTorch && device.isTorchAvailable && device.isTorchActive;
#else
    return device.hasTorch && (device.torchMode == AVCaptureTorchModeOn);
#endif
}

- (void)setTorched:(BOOL)torched {
    AVCaptureDevice *device = ((AVCaptureDeviceInput *)_previewLayer.session.inputs.lastObject).device;
    if ([device isTorchModeSupported:AVCaptureTorchModeOn] && [device isTorchModeSupported:AVCaptureTorchModeOff]) {
        if ([device lockForConfiguration:NULL]) {
            [device setTorchMode:torched ? AVCaptureTorchModeOn : AVCaptureTorchModeOff];
            [device unlockForConfiguration];
        }
    }
}

- (CALayer *)imageLayer {
    return _imageLayer;
}

- (void)setImageLayer:(CALayer *)imageLayer {
    SSNonAtomicRetainedSet(_imageLayer, imageLayer);
}

- (id)image {
    return _imageLayer.contents;
}

- (void)setImage:(id)image {
    if (_previewLayer.session) {
        _imageLayer.contents = image;
    }
}

- (SSCameraView *)contentView {
    return _contentView;
}

- (SSCameraIrisView *)cameraIrisView {
    return _cameraIrisView;
}

- (BOOL)isOpaque {
    return YES;
}

@end
