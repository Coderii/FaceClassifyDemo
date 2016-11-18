//
//  MTImageManager.h
//  MTPhotoLibrary
//
//  Created by JoyChiang on 15/6/23.
//  Copyright (c) 2015年 Meitu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>
#import "MTPhotoAsset.h"

typedef int32_t MTImageRequestID;
#define MTInvalidImageRequestID ((MTImageRequestID)0)


typedef NS_ENUM(NSInteger, MTImageContentMode) {
    MTImageContentModeAspectFit = 0,
    MTImageContentModeAspectFill = 1,
    MTImageContentModeDefault = MTImageContentModeAspectFit
};


/**
 *  图片管理类,包含图片的相关操作
 */
@interface MTImageManager : NSObject

/**
 *  获取图像的缩略图
 *
 *  @param asset         相册里的图片
 *  @param targetSize    目标大小
 *  @param contentMode   内容类型
 *  @param resultHandler 处理后的结果
 *
 *  @return
 */
- (MTImageRequestID)requestThumbnailImageForAsset:(MTPhotoAsset *)asset
                                       targetSize:(CGSize)targetSize
                                      contentMode:(MTImageContentMode)contentMode
                                    resultHandler:(void (^)(UIImage *result, NSDictionary *info))resultHandler;


/**
 *  获取图像的原图
 *
 *  @param asset         相册图片
 *  @param targetSize    目标大小
 *  @param contentMode   内容类型
 *  @param resultHandler 处理后的结果
 *
 *  @return
 */
- (MTImageRequestID)requestImageForAsset:(MTPhotoAsset *)asset
                              targetSize:(CGSize)targetSize
                             contentMode:(MTImageContentMode)contentMode
                           resultHandler:(void (^)(UIImage *result, NSDictionary *info))resultHandler;

/**
 *  取消图片的请求(iOS8之后才能使用)
 *
 *  @param requestID 每次获取图像的时候都返回的MTImageRequestID
 */
- (void)cancelImageRequest:(MTImageRequestID)requestID;


/**
 *
 *  开启图片缓存,如果Asset在之前已经被查找过,
 *  会直接从缓存里面返回图片。
 *
 *  @param assets      图片
 *  @param targetSize  目标大小
 *  @param contentMode 内容类型
 */
- (void)startCachingImagesForAssets:(NSArray *)assets
                         targetSize:(CGSize)targetSize
                        contentMode:(MTImageContentMode)contentMode;

/**
 *  取消图片的缓存,图片的获取每次都重新请求
 *
 *  @param assets      图片
 *  @param targetSize  目标大小
 *  @param contentMode 内容类型
 */
- (void)stopCachingImagesForAssets:(NSArray *)assets
                        targetSize:(CGSize)targetSize
                       contentMode:(MTImageContentMode)contentMode;

/**
 *  取消所有图片的缓存
 */
- (void)stopCachingImagesForAllAssets;

@end
