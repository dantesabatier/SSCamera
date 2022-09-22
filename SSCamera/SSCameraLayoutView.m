//
//  SSCameraLayoutView.m
//  SSCamera
//
//  Created by Dante Sabatier on 01/09/16.
//  Copyright © 2016 Dante Sabatier. All rights reserved.
//

#import "SSCameraLayoutView.h"

@implementation SSCameraLayoutView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.autoresizesSubviews = YES;
#if __DISABLE_AUTOLAYOUT_
        self.autoresizesSubviews = NO;
#endif
#if TARGET_OS_IPHONE
#if !TARGET_OS_TV
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidChangeStatusBarOrientation:) name:UIApplicationDidChangeStatusBarOrientationNotification object:[UIApplication sharedApplication]];
#endif
#else
#if __DISABLE_AUTOLAYOUT_ && defined(__MAC_10_7)
        if (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_6) {
            self.translatesAutoresizingMaskIntoConstraints = NO;
        }
#endif
        self.postsBoundsChangedNotifications = YES;
        self.postsFrameChangedNotifications = YES;
#endif
    }
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        self.autoresizesSubviews = YES;
#if __DISABLE_AUTOLAYOUT_
        self.autoresizesSubviews = NO;
#endif
#if TARGET_OS_IPHONE
#if !TARGET_OS_TV
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidChangeStatusBarOrientation:) name:UIApplicationDidChangeStatusBarOrientationNotification object:[UIApplication sharedApplication]];
#endif
#else
#if __DISABLE_AUTOLAYOUT_ && defined(__MAC_10_7)
        if (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_6) {
            self.translatesAutoresizingMaskIntoConstraints = NO;
        }
#endif
        self.postsBoundsChangedNotifications = YES;
        self.postsFrameChangedNotifications = YES;
#endif
    }
    return self;
}

- (void)dealloc {
    [self.class cancelPreviousPerformRequestsWithTarget:self selector:@selector(layout) object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [super ss_dealloc];
}

#pragma mark layout

- (void)setNeedsLayout {
#if TARGET_OS_IPHONE
    [super setNeedsLayout];
#endif
    self.needsLayout = YES;
}

- (void)layoutIfNeeded {
    if (!self.needsLayout) {
        return;
    }
    [self layout];
    self.needsLayout = NO;
}

- (void)layout {
#if ((TARGET_OS_MAC && !(TARGET_OS_EMBEDDED || TARGET_OS_IPHONE)) && defined(__MAC_10_7))
    if (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_6) {
#if defined(__MAC_10_12)
        if (floor(NSAppKitVersionNumber) < NSAppKitVersionNumber10_12) {
            [super layout];
        }
#else
        [super layout];
#endif
    }
#endif
}

- (BOOL)needsLayout {
#if 0
    BOOL needsLayout = NO;
#if ((TARGET_OS_MAC && !(TARGET_OS_EMBEDDED || TARGET_OS_IPHONE)) && defined(__MAC_10_7))
    if (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_6) {
#if defined(__MAC_10_12)
        if (floor(NSAppKitVersionNumber) < NSAppKitVersionNumber10_12) {
            needsLayout = super.needsLayout;
        }
#endif
    }
#endif
    return needsLayout || _needsLayout;
#else
    return _needsLayout;
#endif
}

- (void)setNeedsLayout:(BOOL)needsLayout {
#if TARGET_OS_IPHONE
    if (needsLayout) {
        [super setNeedsLayout];
    }
#else
#if defined(__MAC_10_7)
    if (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_6) {
        super.needsLayout = needsLayout;
    }
#endif
#endif
    _needsLayout = needsLayout;
}

- (CGSize)sizeThatFits:(CGSize)size {
    return size;
}

- (void)sizeToFit {
#if TARGET_OS_IPHONE
    [super sizeToFit];
#else
    CGSize contentSize = [self sizeThatFits:self.bounds.size];
    if (CGSizeEqualToSize(self.frame.size, contentSize)) {
        [self.class cancelPreviousPerformRequestsWithTarget:self selector:@selector(layout) object:nil];
        [self performSelector:@selector(layout) withObject:nil afterDelay:0.5 inModes:@[NSDefaultRunLoopMode, NSModalPanelRunLoopMode]];
    } else {
        self.frame = SSRectMakeWithSize(contentSize);
    }
#endif
}

#if TARGET_OS_IPHONE
- (void)addSubview:(UIView *)aView
#else
- (void)addSubview:(NSView *)aView
#endif
{
#if __DISABLE_AUTOLAYOUT_
    aView.autoresizesSubviews = NO;
#if ((TARGET_OS_MAC && !(TARGET_OS_EMBEDDED || TARGET_OS_IPHONE)) && defined(__MAC_10_7))
    if (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_6) {
        aView.translatesAutoresizingMaskIntoConstraints = NO;
    }
#endif
#endif
    [super addSubview:aView];
}

#if TARGET_OS_IPHONE

#pragma mark UIView

- (void)didMoveToWindow {
    [super didMoveToWindow];
    
    if (self.window) {
        [self.class cancelPreviousPerformRequestsWithTarget:self selector:@selector(layout) object:nil];
        [self performSelector:@selector(layout) withObject:nil afterDelay:0.1];
    }
}

- (void)didMoveToSuperview {
    [super didMoveToSuperview];
    
#if !TARGET_OS_IPHONE
    self.superview.postsBoundsChangedNotifications = YES;
    self.superview.postsFrameChangedNotifications = YES;
#endif
    if (self.superview) {
        [self.class cancelPreviousPerformRequestsWithTarget:self selector:@selector(layout) object:nil];
        [self performSelector:@selector(layout) withObject:nil afterDelay:0.1];
    }
}

- (void)setFrame:(CGRect)frame {
    super.frame = frame;
    
    [self setNeedsLayout];
}

#pragma mark UIApplication notifications

- (void)applicationDidChangeStatusBarOrientation:(NSNotification *)notification {
    SSDebugLog(@"%@ %@", self.class, NSStringFromSelector(_cmd));
    [self.class cancelPreviousPerformRequestsWithTarget:self selector:@selector(layout) object:nil];
    [self performSelector:@selector(layout) withObject:nil afterDelay:0.15];
}

#else

#pragma mark NSView

- (void)viewDidMoveToWindow {
    if (self.window) {
        [self.class cancelPreviousPerformRequestsWithTarget:self selector:@selector(layout) object:nil];
        [self performSelector:@selector(layout) withObject:nil afterDelay:0.1];
    }
}

- (void)viewDidMoveToSuperview {
    if (self.superview) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setNeedsLayout) name:NSViewFrameDidChangeNotification object:self.superview];
    }
    
    [self.class cancelPreviousPerformRequestsWithTarget:self selector:@selector(layout) object:nil];
    [self performSelector:@selector(layout) withObject:nil afterDelay:0.1];
}

- (void)viewWillMoveToSuperview:(NSView *)superview {
    [super viewWillMoveToSuperview:superview];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSViewFrameDidChangeNotification object:nil];
}

- (void)viewDidUnhide {
    [super viewDidUnhide];
    [self layout];
}

- (void)viewWillDraw {
    [super viewWillDraw];
    [self layoutIfNeeded];
}

#endif

@end
