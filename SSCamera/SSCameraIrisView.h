//
//  SSCameraIrisView.h
//  SSCamera
//
//  Created by Dante Sabatier on 01/09/16.
//  Copyright © 2016 Dante Sabatier. All rights reserved.
//

#import "SSCameraLayoutView.h"

NS_ASSUME_NONNULL_BEGIN

@interface SSCameraIrisView : SSCameraLayoutView {
@private;
    BOOL _cameraIrisHollowOpen;
}

- (void)setCameraIrisHollowOpen:(BOOL)cameraIrisHollowOpen animated:(BOOL)animated completion:(void(^__nullable)(void))completion;
- (void)setCameraIrisHollowOpen:(BOOL)cameraIrisHollowOpen animated:(BOOL)animated;
@property (nonatomic, getter=isCameraIrisHollowOpen, assign) BOOL cameraIrisHollowOpen;

@end

NS_ASSUME_NONNULL_END
