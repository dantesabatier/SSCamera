//
//  SSCameraErrors.h
//  SSCamera
//
//  Created by Dante Sabatier on 07/01/19.
//  Copyright © 2019 Dante Sabatier. All rights reserved.
//

#import <Foundation/NSObject.h>
#import <Foundation/NSError.h>

/*!
 @const SSCameraErrorDomain
 @discussion NSError domain for the framework.
 */

extern NSErrorDomain SSCameraErrorDomain;

/*!
 @typedef SSCameraErrorCode
 @brief NSError codes in <code>SSCameraErrorDomain</code>.
 @constant SSCameraErrorCodeNoCaptureDeviceFound No capture device found.
 */

typedef NS_ERROR_ENUM(SSCameraErrorDomain, SSCameraErrorCode) {
    SSCameraErrorCodeCaptureDeviceNotFound = 5638
};
