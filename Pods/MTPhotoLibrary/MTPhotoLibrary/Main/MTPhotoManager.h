//
//  MTPhotoManager.h
//  MTPhotoLibrary
//
//  Created by JoyChiang on 15/6/20.
//  Copyright (c) 2015年 Meitu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MTPhotoAsset.h"
#import "MTPhotoAlbum.h"

typedef NS_ENUM(NSUInteger, MTAuthorizationStatus) {
    MTAuthorizationStatusNotDetermined = 0,
    MTAuthorizationStatusRestricted,
    MTAuthorizationStatusDenied,
    MTAuthorizationStatusAuthorized
};

typedef NS_ENUM(NSUInteger, MTPhotoAlbumsFetchOption) {
    MTPhotoAlbumsFetchOptionPhotos = 1,
    MTPhotoAlbumsFetchOptionVideos,
    MTPhotoAlbumsFetchOptionAll
};

#pragma mark - MTPhotoLibraryChangeObserver
@protocol MTPhotoLibraryChangeObserver <NSObject>

@optional
- (void)photoLibraryDidChange:(PHChange *)changeInstance;

- (void)assetsLibraryDidChange:(NSNotification *)note;

@end

#pragma mark - MTPhotoManager
@protocol MTPhotoManager <NSObject>

@required

// 相册权限
+ (MTAuthorizationStatus)authorizationStatus;
+ (void)requestAuthorization:(void(^)(MTAuthorizationStatus status))handler;

// 相册状态监听
- (void)registerChangeObserver:(id<MTPhotoLibraryChangeObserver>)observer;
- (void)unregisterChangeObserver:(id<MTPhotoLibraryChangeObserver>)observer;

// 遍历相册
- (void)enumerateAlbums:(MTPhotoManagerAlbumEnumerationBlock)enumerationBlock
            resultBlock:(MTPhotoManagerResultBlock)resultBlock;

// 创建相册
- (void)createAlbum:(NSString *)title resultBlock:(MTPhotoManagerResultBlock)resultBlock;
- (void)checkAlbum:(NSString *)title resultBlock:(MTPhotoManagerCheckBlock)resultBlock;

// 添加删除相册
- (void)addAsset:(MTPhotoAsset *)asset toAlbum:(MTPhotoAlbum *)photoAlbum resultBlock:(MTPhotoManagerResultBlock)resultBlock;
- (void)deleteAssets:(NSArray *)assets resultBlock:(MTPhotoManagerResultBlock)resultBlock;
- (void)deleteAlbums:(NSArray *)albums resultBlock:(MTPhotoManagerResultBlock)resultBlock;

// 写入默认相册
- (void)writeImageToSavedPhotosAlbum:(UIImage *)image
                         resultBlock:(MTPhotoManagerWriteImageResultBlock)resultBlock;
- (void)writeImageDataToSavedPhotosAlbum:(NSData *)imageData
                                metadata:(NSDictionary *)metadata
                             resultBlock:(MTPhotoManagerWriteImageResultBlock)resultBlock;

// 写入指定的相册
- (void)writeImage:(UIImage *)image
           toAlbum:(MTPhotoAlbum *)photoAlbum
       resultBlock:(MTPhotoManagerWriteImageResultBlock)resultBlock;
- (void)writeImageData:(NSData *)imageData
              metadata:(NSDictionary *)metadata
               toAlbum:(MTPhotoAlbum *)photoAlbum
           resultBlock:(MTPhotoManagerWriteImageResultBlock)resultBlock;

// 写入视频
- (void)writeVideoAtPathToSavedPhotosAlbum:(NSString *)filePath
                               resultBlock:(MTPhotoManagerResultBlock)resultBlock;

// 写入视频
- (void)writeVideoAtURLToSavedPhotosAlbum:(NSURL *)fileURL
                            completeBlock:(MTPhotoManagerAssetsChangedBlock)completeBlock;

// 将App沙盒目录下的Image保存到相册
- (void)writeImageAtURLToSavedPhotosAlbum:(NSURL *)fileURL
                            completeBlock:(MTPhotoManagerAssetsChangedBlock)completeBlock;

// 将App沙盒目录下的Image保存到相册
- (void)writeMediaFileAtURLToSavedPhotosAlbum:(NSURL *)fileURL
                                    mediaType:(MTPhotoAssetMediaType)mediaType
                                 completeBlock:(MTPhotoManagerAssetsChangedBlock)completeBlock;

- (void)clearCached;


#pragma mark - PhotoAlbum API 1.0.1
@property (nonatomic, strong, readonly) NSMutableArray *photoAlbums;

// 可选返回图片、视频、图片加视频，默认获取图片
- (NSMutableArray *)photoAlbumsWithFetchOption:(MTPhotoAlbumsFetchOption)fetchOption;


#pragma mark - PhotoAlbum API -bugfix 1.0.2
/**
 *  获取相册列表接口 （说明:IOS7 内部相册列表获取需要枚举遍历，耗时会比较久）
 *
 *  @param completionBlock 结束回调块
 */
- (void)fetchPhotoAlbumsWith:(void(^)(NSMutableArray *photoAlbums))completionBlock;

/**
 *  获取相册列表接口 （说明:IOS7 内部相册列表获取需要枚举遍历，耗时会比较久）
 *
 *  @param fetchOption     过滤相册中media的类型 @see MTPhotoAlbumsFetchOption
 *  @param completionBlock 结束回调块
 */
- (void)fetchPhotoAlbumsWith:(MTPhotoAlbumsFetchOption)fetchOption completionBlock:(void(^)(NSMutableArray *photoAlbums))completionBlock;

/**
 *  获取最近拍摄的一张照片接口
 *
 *  @param completionBlock 结束的回调
 */
- (void)fetchRecentPhotoAsset:(void(^)(MTPhotoAsset *asset))completionBlock;
@end
