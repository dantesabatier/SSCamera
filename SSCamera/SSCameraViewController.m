//
//  SSCameraViewController.m
//  SSCamera
//
//  Created by Dante Sabatier on 18/05/13.
//  Copyright (c) 2013 Dante Sabatier. All rights reserved.
//

#import "SSCameraViewController.h"
#import "SSCameraConstants.h"
#if TARGET_OS_IPHONE
#import <graphics/SSContext.h>
#import <graphics/SSColor.h>
#import <graphics/SSImage.h>
#import <graphics/SSPath.h>
#else
#import <SSGraphics/SSContext.h>
#import <SSGraphics/SSColor.h>
#import <SSGraphics/SSImage.h>
#import <SSGraphics/SSPath.h>
#import "SSCameraDeviceChooser.h"
#endif
#import <CoreVideo/CVHostTime.h>

@interface SSCameraViewController () <AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic, readwrite, strong) AVCaptureSession *session;
@property (nonatomic, readwrite, strong) AVCaptureDevice *device;
@property (nonatomic, readwrite, strong) AVCaptureConnection *connection;

- (void)processImageBuffer:(CVImageBufferRef)imageBuffer;

@end

@implementation SSCameraViewController

- (instancetype)init {
    self = [super init];
    if (self) {
        _showsCameraIrisAnimation = YES;
		_clockFrequency = CVGetHostClockFrequency();
        _minimumCaptureInterval = 0.0;
#if TARGET_OS_IPHONE
        self.view = [[[SSCameraPreviewView alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
#else
        self.view = [[[SSCameraPreviewView alloc] initWithFrame:SSCameraViewControllerDefaultContentRect] autorelease];
#endif
    }
    return self;
}

- (void)dealloc {
    _imageProvider = nil;
	
	[self stopRunning];
	
    [super ss_dealloc];
}

- (BOOL)startRunning:(__autoreleasing NSError *__nullable * __nullable)error {
#if TARGET_OS_SIMULATOR
    [(SSCameraPreviewView *)self.view setCameraIrisHollowOpen:YES animated:_showsCameraIrisAnimation completion:^{
        if (self.cameraIrisAnimationBlock) {
            self.cameraIrisAnimationBlock(self);
        }
    }];
    return YES;
#else
    AVCaptureSession *session = self.session;
    if (session.isRunning) {
        return YES;
    }
    
    [self stopRunning];
    
    AVCaptureDevice *device = [AVCaptureDevice deviceWithUniqueID:[[NSUserDefaults standardUserDefaults] stringForKey:SSCameraViewControllerSelectedDeviceUniqueIDPreferencesKey]];
    if (!device) {
        NSMutableArray *devices = [NSMutableArray array];
#if TARGET_OS_IPHONE
        [devices addObjectsFromArray:[AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]];
        [devices addObjectsFromArray:[AVCaptureDevice devicesWithMediaType:AVMediaTypeMuxed]];
#else
        [devices addObjectsFromArray:SSCameraDeviceChooser.sharedCameraDeviceChooser.devices];
#endif
        if (devices.count) {
#if TARGET_OS_IPHONE
            device = devices[0];
            [[NSUserDefaults standardUserDefaults] setObject:device.uniqueID forKey:SSCameraViewControllerSelectedDeviceUniqueIDPreferencesKey];
#else
            if (devices.count > 1) {
                if (!(device = SSCameraDeviceChooser.sharedCameraDeviceChooser.selectedDevice) && (SSCameraDeviceChooser.sharedCameraDeviceChooser.runModal == NSOKButton)) {
                    device = SSCameraDeviceChooser.sharedCameraDeviceChooser.selectedDevice;
                }
            } else {
                device = devices[0];
                [[NSUserDefaults standardUserDefaults] setObject:device.uniqueID forKey:SSCameraViewControllerSelectedDeviceUniqueIDPreferencesKey];
            }
#endif
        }
    }
    
    if (!device) {
        if (error) {
#if TARGET_OS_IPHONE
            *error = [NSError errorWithDomain:SSCameraErrorDomain code:SSCameraErrorCodeCaptureDeviceNotFound userInfo:@{NSLocalizedDescriptionKey:SSLocalizedString(@"No capture device found", @"error description")}];
#else
            *error = [NSError errorWithDomain:SSCameraErrorDomain code:SSCameraErrorCodeCaptureDeviceNotFound userInfo:@{NSLocalizedDescriptionKey:SSLocalizedString(@"No capture device found", @"error description"), NSLocalizedRecoverySuggestionErrorKey : SSLocalizedString(@"Make sure your firewire camera is plugged in and not in use by another application.", @"error recovery suggestion"), NSLocalizedFailureReasonErrorKey : SSLocalizedString(@"Make sure your firewire camera is plugged in and not in use by another application.", @"error recovery suggestion")}];
#endif
        }
        return NO;
    }
    
    AVCaptureDeviceInput *captureDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:error];
    if (!captureDeviceInput) {
        return NO;
    }
    
#if !TARGET_OS_IPHONE
    if (_focusMethod != SSCameraViewControllerFocusMethodAutomatic) {
        if ([device.localizedName rangeOfString:@"FaceTime HD" options:NSCaseInsensitiveSearch].location != NSNotFound) {
            _focusMethod = SSCameraViewControllerFocusMethodTopLeft;
        } else {
            _focusMethod = SSCameraViewControllerFocusMethodTopCenter;
        }
    }
#endif
    
    self.imageProviderBlock = ^(__kindof SSCameraViewController *cameraViewController, CVImageBufferRef __nullable imageBuffer, void (^__nullable original)(CGImageRef __nullable image), void (^__nullable modified)(CGImageRef __nullable image)) {
        if (imageBuffer) {
            CGContextRef providingImageCtx  = NULL;
            if (CVPixelBufferLockBaseAddress(imageBuffer, 0) == kCVReturnSuccess) {
                providingImageCtx = CGBitmapContextCreate(CVPixelBufferGetBaseAddress(imageBuffer), CVPixelBufferGetWidth(imageBuffer), CVPixelBufferGetHeight(imageBuffer), 8, CVPixelBufferGetBytesPerRow(imageBuffer), SSAutorelease(CGColorSpaceCreateDeviceRGB()), kCGBitmapByteOrder32Host|kCGImageAlphaPremultipliedFirst);
                CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
            }
            
            if (providingImageCtx != NULL) {
                CGImageRef image = CGBitmapContextCreateImage(providingImageCtx);
                if (original) {
                    original(image);
                }
                
                if (modified) {
                    modified(image);
                }
                CGImageRelease(image);
                CGContextRelease(providingImageCtx);
            }
        }
    };
    
    AVCaptureVideoDataOutput *captureDeviceOutput = [[[AVCaptureVideoDataOutput alloc] init] autorelease];
    captureDeviceOutput.videoSettings = @{(__bridge NSString *)kCVPixelBufferPixelFormatTypeKey:@(kCVPixelFormatType_32BGRA)};
    captureDeviceOutput.alwaysDiscardsLateVideoFrames = YES;
    
    dispatch_queue_t queue = dispatch_queue_create("com.sabatiersoftware.barcodescanner", NULL);
    [captureDeviceOutput setSampleBufferDelegate:self queue:queue];
    dispatch_release(queue);
    
    session = [[[AVCaptureSession alloc] init] autorelease];
    [session beginConfiguration];
    
    [session addInput:captureDeviceInput];
    [session addOutput:captureDeviceOutput];
    
#if TARGET_OS_IPHONE
    session.sessionPreset = AVCaptureSessionPresetMedium;
#else
    session.sessionPreset = AVCaptureSessionPresetHigh;
#endif
    
    if ([device lockForConfiguration:NULL]) {
        switch (self.focusMethod) {
            case SSCameraViewControllerFocusMethodAutomatic: {
#if TARGET_OS_IPHONE && defined(__IPHONE_7_0)
                if ([device respondsToSelector:@selector(isSmoothAutoFocusSupported)] && device.isSmoothAutoFocusSupported) {
                    device.smoothAutoFocusEnabled = YES;
                }
                if ([device respondsToSelector:@selector(isAutoFocusRangeRestrictionSupported)] && device.isAutoFocusRangeRestrictionSupported) {
                    device.autoFocusRangeRestriction = AVCaptureAutoFocusRangeRestrictionNear;
                }
#endif
                if ([device isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
                    device.focusMode = AVCaptureFocusModeAutoFocus;
                }
            }
                break;
            case SSCameraViewControllerFocusMethodTopLeft: {
                if (device.isFocusPointOfInterestSupported && [device isFocusModeSupported:AVCaptureFocusModeLocked]) {
                    device.focusPointOfInterest = SSPointTopLeft;
                    device.focusMode = AVCaptureFocusModeLocked;
                }
            }
                break;
            case SSCameraViewControllerFocusMethodTopCenter: {
                if (device.isFocusPointOfInterestSupported && [device isFocusModeSupported:AVCaptureFocusModeLocked]) {
                    device.focusPointOfInterest = SSPointTopCenter;
                    device.focusMode = AVCaptureFocusModeLocked;
                }
            }
                break;
            case SSCameraViewControllerFocusMethodTopRight: {
                if (device.isFocusPointOfInterestSupported && [device isFocusModeSupported:AVCaptureFocusModeLocked]) {
                    device.focusPointOfInterest = SSPointTopRight;
                    device.focusMode = AVCaptureFocusModeLocked;
                }
            }
                break;
            case SSCameraViewControllerFocusMethodBottomLeft: {
                if (device.isFocusPointOfInterestSupported && [device isFocusModeSupported:AVCaptureFocusModeLocked]) {
                    device.focusPointOfInterest = SSPointBottomLeft;
                    device.focusMode = AVCaptureFocusModeLocked;
                }
            }
                break;
            case SSCameraViewControllerFocusMethodBottomCenter: {
                if (device.isFocusPointOfInterestSupported && [device isFocusModeSupported:AVCaptureFocusModeLocked]) {
                    device.focusPointOfInterest = SSPointBottomCenter;
                    device.focusMode = AVCaptureFocusModeLocked;
                }
            }
                break;
            case SSCameraViewControllerFocusMethodBottomRight: {
                if (device.isFocusPointOfInterestSupported && [device isFocusModeSupported:AVCaptureFocusModeLocked]) {
                    device.focusPointOfInterest = SSPointBottomRight;
                    device.focusMode = AVCaptureFocusModeLocked;
                }
            }
                break;
            case SSCameraViewControllerFocusMethodLeftCenter: {
                if (device.isFocusPointOfInterestSupported && [device isFocusModeSupported:AVCaptureFocusModeLocked]) {
                    device.focusPointOfInterest = SSPointLeft;
                    device.focusMode = AVCaptureFocusModeLocked;
                }
            }
                break;
            case SSCameraViewControllerFocusMethodRightCenter: {
                if (device.isFocusPointOfInterestSupported && [device isFocusModeSupported:AVCaptureFocusModeLocked]) {
                    device.focusPointOfInterest = SSPointRight;
                    device.focusMode = AVCaptureFocusModeLocked;
                }
            }
                break;
            case SSCameraViewControllerFocusMethodCenter: {
                if (device.isFocusPointOfInterestSupported && [device isFocusModeSupported:AVCaptureFocusModeLocked]) {
                    device.focusPointOfInterest = SSPointCenter;
                    device.focusMode = AVCaptureFocusModeLocked;
                }
            }
                break;
        }
        
        [device unlockForConfiguration];
    }
    
    if (captureDeviceOutput.connections.count) {
        NSUInteger idx = [captureDeviceOutput.connections indexOfObjectPassingTest:^BOOL(AVCaptureConnection *connection, NSUInteger idx, BOOL *stop) {
            return [connection.inputPorts indexOfObjectPassingTest:^BOOL(AVCaptureInputPort *port, NSUInteger idx, BOOL *stop) {
                return [port.mediaType isEqualToString:AVMediaTypeVideo];
            }] != NSNotFound;
        }];
        if (idx != NSNotFound) {
            AVCaptureConnection *connection = captureDeviceOutput.connections[idx];
#if TARGET_OS_IPHONE
            if (connection.isVideoStabilizationSupported) {
#if defined(__IPHONE_8_0)
                if ([connection respondsToSelector:@selector(setPreferredVideoStabilizationMode:)]) {
                    connection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
                }
#else
                connection.enablesVideoStabilizationWhenAvailable = YES;
#endif
            }
#if 0
            if (connection.isVideoOrientationSupported) {
                switch ([[UIDevice currentDevice] orientation]) {
                    case UIDeviceOrientationLandscapeLeft:
                        connection.videoOrientation = AVCaptureVideoOrientationLandscapeRight;
                        break;
                    case UIDeviceOrientationLandscapeRight:
                        connection.videoOrientation = AVCaptureVideoOrientationLandscapeLeft;
                        break;
                    case UIDeviceOrientationPortrait:
                        connection.videoOrientation = AVCaptureVideoOrientationPortrait;
                        break;
                    case UIDeviceOrientationPortraitUpsideDown:
                        connection.videoOrientation = AVCaptureVideoOrientationPortraitUpsideDown;
                        break;
                    default:
                        connection.videoOrientation = AVCaptureVideoOrientationPortrait;
                        break;
                }
            }
#endif
#endif
            self.connection = connection;
        }
    }
    
    [session commitConfiguration];
    
    self.session = session;
    self.device = device;
    
    SSCameraPreviewView *scannerView = (SSCameraPreviewView *)self.view;
    __block __unsafe_unretained id sessionDidStartRunningObserver = [[NSNotificationCenter defaultCenter] addObserverForName:AVCaptureSessionDidStartRunningNotification object:session queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        scannerView.session = session;
        [scannerView setCameraIrisHollowOpen:YES animated:_showsCameraIrisAnimation completion:^{
            if (self.cameraIrisAnimationBlock) {
                self.cameraIrisAnimationBlock(self);
            }
        }];
        [[NSNotificationCenter defaultCenter] removeObserver:sessionDidStartRunningObserver];
    }];
    
    __block __unsafe_unretained id sessionDidStopRunningObserver = [[NSNotificationCenter defaultCenter] addObserverForName:AVCaptureSessionDidStopRunningNotification object:session queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        scannerView.session = nil;
        [scannerView setCameraIrisHollowOpen:NO animated:_showsCameraIrisAnimation completion:^{
            if (self.cameraIrisAnimationBlock) {
                self.cameraIrisAnimationBlock(self);
            }
        }];
        [[NSNotificationCenter defaultCenter] removeObserver:sessionDidStopRunningObserver];
    }];
    
    [session startRunning];
    
    _timestamp = CFAbsoluteTimeGetCurrent();
    
    return YES;
#endif
}

- (void)stopRunning {
#if TARGET_OS_SIMULATOR
    [(SSCameraPreviewView *)self.view setCameraIrisHollowOpen:NO animated:_showsCameraIrisAnimation completion:^{
        if (self.cameraIrisAnimationBlock) {
            self.cameraIrisAnimationBlock(self);
        }
    }];
#else
    AVCaptureSession *session = self.session;
    if (session) {
#if ((!TARGET_OS_IPHONE && defined(__MAC_10_7)) || (TARGET_OS_IPHONE && defined(__IPHONE_5_0)))
        [session.outputs.lastObject setSampleBufferDelegate:nil queue:NULL];
        
        if (session.running) {
            [session stopRunning];
        }
#endif
        self.session = nil;
        self.device = nil;
        self.connection = nil;
    }
#endif
}

#pragma mark AVCaptureVideoDataOutputSampleBufferDelegate delegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
#if 0
    uint64_t ht = CVGetCurrentHostTime(), iht = CMSampleBufferGetDecodeTimeStamp(sampleBuffer).value;
	double hts = (double)ht/_clockFrequency, ihts = (double)iht/_clockFrequency;
    if (hts > (ihts + 0.1)) {
        return;
    }
#endif
    if (CMSampleBufferIsValid(sampleBuffer)) {
        [self processImageBuffer:CMSampleBufferGetImageBuffer(sampleBuffer)];
    }
}

- (BOOL)processImage:(__nullable CGImageRef)image {
    if (!image || ((CFAbsoluteTimeGetCurrent() - _timestamp) < self.minimumCaptureInterval)) {
        return NO;
    }
    
    [self.view performSelectorOnMainThread:@selector(setImage:) withObject:(__bridge id)image waitUntilDone:YES];
    
    _timestamp = CFAbsoluteTimeGetCurrent();
    
    return YES;
}

#pragma mark private methods

- (void)processImageBuffer:(CVImageBufferRef)imageBuffer {
    if (!imageBuffer) {
        return;
    }
    
    CGImageRef image = [self.imageProvider cameraViewController:self imageFromImageBuffer:imageBuffer];
    if (image) {
        [self processImage:image];
        return;
    }
    
    self.imageProviderBlock(self, imageBuffer, nil, ^(CGImageRef __nullable image) {
        [self processImage:image];
    });
}

#pragma mark getters & setters

- (AVCaptureSession *)session {
    return _session;
}

- (void)setSession:(AVCaptureSession *)session {
    SSNonAtomicRetainedSet(_session, session);
}

- (AVCaptureDevice *)device {
    return _device;
}

- (void)setDevice:(AVCaptureDevice *)device {
    SSNonAtomicRetainedSet(_device, device);
}

- (AVCaptureConnection *)connection {
    return _connection;
}

- (void)setConnection:(AVCaptureConnection *)connection {
    SSNonAtomicRetainedSet(_connection, connection);
}

- (id<SSCameraViewControllerImageProvider>)imageProvider {
    return _imageProvider;
}

- (void)setImageProvider:(id<SSCameraViewControllerImageProvider>)imageProvider {
    if (![imageProvider conformsToProtocol:@protocol(SSCameraViewControllerImageProvider)]) {
        [NSException raise:NSInvalidArgumentException format:@"%@ %@%@, invalid imageProvider", self.class, NSStringFromSelector(_cmd), imageProvider];
    }
    _imageProvider = imageProvider;
}

- (SSCameraViewControllerImageProviderBlock)imageProviderBlock {
    return SSAtomicAutoreleasedGet(_imageProviderBlock);
}

- (void)setImageProviderBlock:(SSCameraViewControllerImageProviderBlock)imageProviderBlock {
    SSAtomicCopiedSet(_imageProviderBlock, imageProviderBlock);
}

- (SSCameraViewControllerCameraIrisAnimationBlock)cameraIrisAnimationBlock {
    return _cameraIrisAnimationBlock;
}

- (void)setCameraIrisAnimationBlock:(SSCameraViewControllerCameraIrisAnimationBlock)cameraIrisAnimationBlock {
    SSAtomicCopiedSet(_cameraIrisAnimationBlock, cameraIrisAnimationBlock);
}

- (SSCameraViewControllerFocusMethod)focusMethod {
    return _focusMethod;
}

- (void)setFocusMethod:(SSCameraViewControllerFocusMethod)focusMethod {
    _focusMethod = MIN(MAX(focusMethod, SSCameraViewControllerFocusMethodTopLeft), SSCameraViewControllerFocusMethodCenter);
}

- (NSTimeInterval)minimumCaptureInterval {
    return _minimumCaptureInterval;
}

- (void)setMinimumCaptureInterval:(NSTimeInterval)minimumCaptureInterval {
    _minimumCaptureInterval = minimumCaptureInterval;
}

- (BOOL)isRunning {
#if TARGET_OS_SIMULATOR
    return ((SSCameraPreviewView *)self.view).isCameraIrisHollowOpen;
#else
    return _session.running;
#endif
}

- (BOOL)showsDeviceName {
    return ((SSCameraPreviewView *)self.view).showsDeviceName;
}

- (void)setShowsDeviceName:(BOOL)showsDeviceName {
    ((SSCameraPreviewView *)self.view).showsDeviceName = showsDeviceName;
}

- (BOOL)showsCameraIrisAnimation {
    return _showsCameraIrisAnimation;
}

- (void)setShowsCameraIrisAnimation:(BOOL)showsCameraIrisAnimation {
    _showsCameraIrisAnimation = showsCameraIrisAnimation;
}

- (BOOL)hasTorch {
    return ((SSCameraPreviewView *)self.view).hasTorch;
}

- (BOOL)isTorched {
    return ((SSCameraPreviewView *)self.view).isTorched;
}

- (void)setTorched:(BOOL)torched {
    ((SSCameraPreviewView *)self.view).torched = torched;
}

- (BOOL)isCameraIrisHollowOpen {
    return ((SSCameraPreviewView *)self.view).isCameraIrisHollowOpen;
}

@end
