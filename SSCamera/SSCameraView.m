//
//  SSCameraView.m
//  SSCamera
//
//  Created by Dante Sabatier on 01/09/16.
//  Copyright © 2016 Dante Sabatier. All rights reserved.
//

#import "SSCameraView.h"

@implementation SSCameraView

- (CALayer *)makeBackingLayer {
    return [CALayer layer];
}

- (BOOL)wantsUpdateLayer {
    return YES;
}

- (BOOL)isFlipped {
    return YES;
}

@end
