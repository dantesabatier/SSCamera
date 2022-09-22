//
//  SSCameraIrisView.m
//  SSCamera
//
//  Created by Dante Sabatier on 01/09/16.
//  Copyright © 2016 Dante Sabatier. All rights reserved.
//

#import "SSCameraIrisView.h"

#define SSCameraViewIrisLayerPortraitScaleFactor ((CGFloat)1.65)
#define SSCameraViewIrisLayerLandscapeScaleFactor ((CGFloat)1.65)

@implementation SSCameraIrisView

- (instancetype)initWithFrame:(CGRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
#if TARGET_OS_IPHONE
        self.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleBottomMargin;
        self.userInteractionEnabled = NO;
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
        self.userInteractionEnabled = NO;
#else
        self.autoresizingMask = NSViewMinXMargin|NSViewWidthSizable|NSViewMaxXMargin|NSViewMinYMargin|NSViewHeightSizable|NSViewMaxYMargin;
#endif
    }
    return self;
}

- (void)layout {
    [super layout];
    
    [CATransaction begin];
    [CATransaction setValue:@YES forKey:kCATransactionDisableActions];
    CGFloat angleSize = 2*M_PI/self.layer.sublayers.count;
    CGFloat bladeSize = FLOOR(MIN(CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds))*SSCameraViewIrisLayerPortraitScaleFactor);
    CGRect bounds = CGRectIntegral(SSRectMakeSquare(bladeSize));
    [self.layer.sublayers enumerateObjectsUsingBlock:^(__kindof CALayer * _Nonnull sublayer, NSUInteger idx, BOOL * _Nonnull stop) {
        CGPoint anchorPoint = _cameraIrisHollowOpen ? CGPointMake(1.0, 1.0) : CGPointMake(1.0, 0.5);
        CGPoint position = _cameraIrisHollowOpen ? CGPointMake(FLOOR(CGRectGetMidX(self.bounds) - COS(angleSize*idx)*CGRectGetWidth(sublayer.bounds)), FLOOR(CGRectGetMidY(self.bounds) - SIN(angleSize*idx)*CGRectGetHeight(sublayer.bounds))) : SSRectGetCenterPoint(self.bounds);
        sublayer.anchorPoint = anchorPoint;
        sublayer.bounds = bounds;
        sublayer.position = position;
        sublayer.affineTransform = CGAffineTransformMakeRotation(angleSize*idx);
    }];
    [CATransaction commit];
}

#if TARGET_OS_IPHONE

#pragma mark UIView

- (void)didMoveToSuperview {
    [super didMoveToSuperview];
    
    CALayer *backingLayer = self.makeBackingLayer;
    self.layer.opaque = backingLayer.isOpaque;
    self.layer.backgroundColor = backingLayer.backgroundColor;
    self.layer.actions = backingLayer.actions;
    self.layer.sublayers = [[backingLayer.sublayers copy] autorelease];
    self.layer.masksToBounds = YES;
}

#else

#pragma mark NSView

- (void)viewDidMoveToSuperview {
    [super viewDidMoveToSuperview];
    
    if (!self.wantsLayer) {
        self.wantsLayer = YES;
    }
    
    self.layer.masksToBounds = YES;
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
    CGFloat bladeSize = FLOOR(MIN(CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds))*SSCameraViewIrisLayerPortraitScaleFactor);
    CGRect bladeBounds = CGRectIntegral(SSRectMakeSquare(bladeSize));
    CGImageRef bladeContents = SSAutorelease(SSImageCreate(SSSizeScale(SSSizeMakeSquare(MAX(CGRectGetWidth(bladeBounds), CGRectGetHeight(bladeBounds))), scale), ^(CGContextRef  _Nullable ctx) {
        CGRect boundingBox = CGContextGetClipBoundingBox(ctx);
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGMutablePathRef path = CGPathCreateMutable();
        CGPathMoveToPoint(path, NULL, CGRectGetMidX(boundingBox), CGRectGetMinY(boundingBox));
        CGPathAddQuadCurveToPoint(path, NULL, CGRectGetMidX(boundingBox), CGRectGetMidY(boundingBox), CGRectGetMaxX(boundingBox), CGRectGetMaxY(boundingBox) - CGRectGetHeight(boundingBox)*(CGFloat)0.25);
        CGPathAddQuadCurveToPoint(path, NULL, CGRectGetMinX(boundingBox), CGRectGetMidY(boundingBox), CGRectGetMinX(boundingBox), CGRectGetMinY(boundingBox));
        CGPathCloseSubpath(path);
        
        CGContextSaveGState(ctx);
        {
            CGContextSaveGState(ctx);
            {
                CGContextAddPath(ctx, path);
                CGColorRef strokeColor = CGColorCreate(colorSpace, (const CGFloat[]){0.0, 0.0, 0.0, 0.33});
                CGContextSetStrokeColorWithColor(ctx, strokeColor);
                CGContextSetLineWidth(ctx, 2.0);
                CGContextStrokePath(ctx);
                CGColorRelease(strokeColor);
            }
            CGContextRestoreGState(ctx);
            
            CGContextAddPath(ctx, path);
            CGContextClip(ctx);
            CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)@[(__bridge id)SSAutorelease(CGColorCreate(colorSpace, (const CGFloat[]){0.0, 0.0, 0.0, 1.0})), (__bridge id)SSAutorelease(CGColorCreate(colorSpace, (const CGFloat[]){0.350, 0.350, 0.350, 1.0}))], (const CGFloat[]){0.0, 1.0});
            CGContextDrawLinearGradient(ctx, gradient, CGPointMake(0, CGRectGetMaxY(CGPathGetBoundingBox(path))), CGPointZero, 0);
            CGGradientRelease(gradient);
            
            CGContextSaveGState(ctx);
            {
                CGContextAddPath(ctx, path);
                CGColorRef glowColor = CGColorCreate(colorSpace, (const CGFloat[]){0.9, 0.9, 0.9, 0.6});
                CGContextSetBlendMode(ctx, kCGBlendModeOverlay);
                CGContextSetStrokeColorWithColor(ctx, glowColor);
                CGContextSetLineWidth(ctx, 2.0);
                CGContextStrokePath(ctx);
                CGColorRelease(glowColor);
            }
            CGContextRestoreGState(ctx);
            
            CGContextSaveGState(ctx);
            {
                CGContextAddPath(ctx, path);
                CGColorRef innerShadowColor = CGColorCreate(colorSpace, (const CGFloat[]){0.9, 0.9, 0.9, 0.9});
                CGContextSetBlendMode(ctx, kCGBlendModeOverlay);
                SSContextDrawInnerShadowWithColor(ctx, path, innerShadowColor, CGSizeMake(0.0, -1.0), 0.0);
                CGColorRelease(innerShadowColor);
            }
            CGContextRestoreGState(ctx);
        }
        CGContextRestoreGState(ctx);
        CGColorSpaceRelease(colorSpace);
        CGPathRelease(path);
    }));
    
    CALayer *layer = super.makeBackingLayer;
    NSInteger idx = 0;
    NSInteger numberOfSections = 12;
    CGFloat angleSize = 2.0*M_PI/numberOfSections;
    while (idx < numberOfSections) {
        @autoreleasepool {
            CALayer *bladeLayer = [CALayer layer];
            bladeLayer.anchorPoint = CGPointMake(1.0, 0.5);
            bladeLayer.bounds = bladeBounds;
            bladeLayer.position = SSRectGetCenterPoint(self.bounds);
            bladeLayer.affineTransform = CGAffineTransformMakeRotation(angleSize*idx);
            bladeLayer.shadowOffset = CGSizeMake(0, 3.0);
            bladeLayer.shadowOpacity = 1.0;
            bladeLayer.shadowRadius = 3.0;
            bladeLayer.masksToBounds = NO;
#if ((!TARGET_OS_IPHONE && defined(__MAC_10_7)) || (TARGET_OS_IPHONE && defined(__IPHONE_5_0)))
            if ([bladeLayer respondsToSelector:@selector(setShouldRasterize:)]) {
                bladeLayer.shouldRasterize = YES;
            }
            
            if ([bladeLayer respondsToSelector:@selector(setRasterizationScale:)]) {
                bladeLayer.rasterizationScale = scale;
            }
#endif
            bladeLayer.zPosition = (CGFloat)idx;
            bladeLayer.contents = (__bridge id)bladeContents;
            
            [layer addSublayer:bladeLayer];
            
            idx++;
        }
    }
    return layer;
}

- (BOOL)isCameraIrisHollowOpen {
    return _cameraIrisHollowOpen;
}

- (void)setCameraIrisHollowOpen:(BOOL)cameraIrisHollowOpen animated:(BOOL)animated completion:(void(^__nullable)(void))completion {
    if (_cameraIrisHollowOpen == cameraIrisHollowOpen) {
        return;
    }
    
    _cameraIrisHollowOpen = cameraIrisHollowOpen;
    
    NSArray *sublayers = self.layer.sublayers;
    CGFloat angleSize = 2*M_PI/sublayers.count;
    [CATransaction begin];
    [CATransaction setValue:@(!animated) forKey:kCATransactionDisableActions];
    [CATransaction setCompletionBlock:^{
        [sublayers makeObjectsPerformSelector:@selector(removeAllAnimations)];
        if (completion) {
            completion();
        }
    }];
    
    [sublayers enumerateObjectsUsingBlock:^(CALayer * _Nonnull sublayer, NSUInteger idx, BOOL * _Nonnull stop) {
        CGPoint anchorPoint = _cameraIrisHollowOpen ? CGPointMake(1.0, 1.0) : CGPointMake(1.0, 0.5);
        CGPoint position = _cameraIrisHollowOpen ? CGPointMake(FLOOR(CGRectGetMidX(self.bounds) - COS(angleSize*idx)*CGRectGetWidth(sublayer.bounds)), FLOOR(CGRectGetMidY(self.bounds) - SIN(angleSize*idx)*CGRectGetHeight(sublayer.bounds))) : SSRectGetCenterPoint(self.bounds);
        if (animated) {
            CABasicAnimation *anchorPointAnimation = [CABasicAnimation animationWithKeyPath:@"anchorPoint"];
#if TARGET_OS_IPHONE
            anchorPointAnimation.fromValue = [NSValue valueWithCGPoint:sublayer.anchorPoint];
            anchorPointAnimation.toValue = [NSValue valueWithCGPoint:anchorPoint];
#else
            anchorPointAnimation.fromValue = [NSValue valueWithPoint:sublayer.anchorPoint];
            anchorPointAnimation.toValue = [NSValue valueWithPoint:anchorPoint];
#endif
            sublayer.anchorPoint = anchorPoint;
            
            CABasicAnimation *positionAnimation = [CABasicAnimation animationWithKeyPath:@"position"];
#if TARGET_OS_IPHONE
            positionAnimation.fromValue = [NSValue valueWithCGPoint:sublayer.position];
            positionAnimation.toValue = [NSValue valueWithCGPoint:position];
#else
            positionAnimation.fromValue = [NSValue valueWithPoint:sublayer.position];
            positionAnimation.toValue = [NSValue valueWithPoint:position];
#endif
            sublayer.position = position;
            
            CAAnimationGroup *animationGroup = [CAAnimationGroup animation];
            animationGroup.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
            animationGroup.animations = @[anchorPointAnimation, positionAnimation];
            animationGroup.duration = 1.0;
            animationGroup.fillMode = kCAFillModeForwards;
            animationGroup.removedOnCompletion = NO;
            
            [sublayer addAnimation:animationGroup forKey:nil];
        } else {
            sublayer.anchorPoint = anchorPoint;
            sublayer.position = position;
        }
    }];
    
    [CATransaction commit];
}

- (void)setCameraIrisHollowOpen:(BOOL)cameraIrisHollowOpen animated:(BOOL)animated {
    [self setCameraIrisHollowOpen:cameraIrisHollowOpen animated:animated completion:nil];
}

- (void)setCameraIrisHollowOpen:(BOOL)cameraIrisHollowOpen {
    [self setCameraIrisHollowOpen:cameraIrisHollowOpen animated:YES completion:nil];
}

- (BOOL)isOpaque {
    return NO;
}

@end
