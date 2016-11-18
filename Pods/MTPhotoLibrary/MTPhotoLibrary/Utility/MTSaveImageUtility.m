//
//  MTSaveImageUtility.m
//  MTImagePickerControllerDemo
//
//  Created by meitu on 16/6/20.
//  Copyright © 2016年 Meitu. All rights reserved.
//

#import "MTSaveImageUtility.h"
#import "MTPhotoLibrary.h"

@implementation MTSaveImageUtility

+ (void)writeImageToSavedPhotosAlbum:(UIImage *)image
                         resultBlock:(MTPhotoManagerWriteImageResultBlock)resultBlock {

    [[MTPhotoLibrary sharedPhotoLibrary] writeImageToSavedPhotosAlbum:image resultBlock:resultBlock];
}

+ (void)writeImageDataToSavedPhotosAlbum:(NSData *)imageData
                                metadata:(NSDictionary *)metadata
                             resultBlock:(MTPhotoManagerWriteImageResultBlock)resultBlock {
    
    [[MTPhotoLibrary sharedPhotoLibrary] writeImageDataToSavedPhotosAlbum:imageData metadata:metadata resultBlock:resultBlock];
}

// 写入指定的相册
+ (void)writeImage:(UIImage *)image
           toAlbum:(MTPhotoAlbum *)photoAlbum
       resultBlock:(MTPhotoManagerWriteImageResultBlock)resultBlock {
    
    [[MTPhotoLibrary sharedPhotoLibrary] writeImage:image toAlbum:photoAlbum resultBlock:resultBlock];
}

+ (void)writeImageData:(NSData *)imageData
              metadata:(NSDictionary *)metadata
               toAlbum:(MTPhotoAlbum *)photoAlbum
           resultBlock:(MTPhotoManagerWriteImageResultBlock)resultBlock {
    
    [[MTPhotoLibrary sharedPhotoLibrary] writeImageData:imageData metadata:metadata toAlbum:photoAlbum resultBlock:resultBlock];
}
@end
