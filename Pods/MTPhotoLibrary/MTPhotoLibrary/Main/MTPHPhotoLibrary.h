//
//  MTPHPhotoLibrary.h
//  MTPhotoLibrary
//
//  Created by JoyChiang on 15/6/20.
//  Copyright (c) 2015年 Meitu. All rights reserved.
//

#import "MTPhotoManager.h"

/**
 *  iOS8 照片库
 */
@interface MTPHPhotoLibrary : NSObject <MTPhotoManager>

+ (id<MTPhotoManager>)sharedPhotoManager;
+ (void)clearData;

@end
