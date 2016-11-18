//
//  MTSaveImageUtility.h
//  MTImagePickerControllerDemo
//
//  Created by meitu on 16/6/20.
//  Copyright © 2016年 Meitu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MTPhotoAlbum.h"


@interface MTSaveImageUtility : NSObject

+ (void)writeImageToSavedPhotosAlbum:(UIImage *)image
                         resultBlock:(MTPhotoManagerWriteImageResultBlock)resultBlock;

// 写入指定的相册
+ (void)writeImage:(UIImage *)image
           toAlbum:(MTPhotoAlbum *)photoAlbum
       resultBlock:(MTPhotoManagerWriteImageResultBlock)resultBlock;
@end
