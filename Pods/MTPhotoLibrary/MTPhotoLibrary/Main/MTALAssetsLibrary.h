//
//  MTALAssetsLibrary.h
//  MTPhotoLibrary
//
//  Created by JoyChiang on 15/6/20.
//  Copyright (c) 2015年 Meitu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MTPhotoManager.h"

/**
 *  iOS7照片库
 */
@interface MTALAssetsLibrary : NSObject <MTPhotoManager>

+ (id<MTPhotoManager>)sharedPhotoManager;

@end
