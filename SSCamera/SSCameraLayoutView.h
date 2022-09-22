//
//  SSCameraLayoutView.h
//  SSCamera
//
//  Created by Dante Sabatier on 01/09/16.
//  Copyright © 2016 Dante Sabatier. All rights reserved.
//

#import "SSCameraView.h"

NS_ASSUME_NONNULL_BEGIN

@interface SSCameraLayoutView : SSCameraView {
@private
    BOOL _needsLayout;
}

#if (!TARGET_OS_IPHONE && !defined(__MAC_10_7)) || TARGET_OS_IPHONE
@property (nonatomic, assign) BOOL needsLayout;
- (void)layout;
#endif
#if !TARGET_OS_IPHONE
- (void)setNeedsLayout;
- (CGSize)sizeThatFits:(CGSize)size;
- (void)sizeToFit;
#endif
- (void)layoutIfNeeded;

@end

NS_ASSUME_NONNULL_END
