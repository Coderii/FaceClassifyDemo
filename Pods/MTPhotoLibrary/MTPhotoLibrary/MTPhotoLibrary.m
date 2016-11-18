//
//  MTPhotoLibrary.m
//  MTPhotoLibrary
//
//  Created by JoyChiang on 15/6/20.
//  Copyright (c) 2015年 Meitu. All rights reserved.
//

#import "MTPhotoLibrary.h"
#import "MTPhotoLibrary_Prefix.h"
#import "MTALAssetsLibrary.h"
#import "MTPHPhotoLibrary.h"

@interface MTPhotoLibrary ()
{
    id<MTPhotoManager> _photoManager;
}

@end

@implementation MTPhotoLibrary

static MTPhotoLibrary *sharedPhotoLibrary = nil;
+ (instancetype)sharedPhotoLibrary
{    
    if (sharedPhotoLibrary == nil) {
        sharedPhotoLibrary = [[MTPhotoLibrary alloc] init];
    }
    return sharedPhotoLibrary;
}

+ (void)clearData
{
    sharedPhotoLibrary = nil;
    // 显示释放MTPHPhotoLibrary类型的_photoManager
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO_8_0) {
        [MTPHPhotoLibrary clearData];
    }
}

+ (MTAuthorizationStatus)authorizationStatus
{
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO_8_0) {
        return [MTPHPhotoLibrary authorizationStatus];
    }
    else {
        return [MTALAssetsLibrary authorizationStatus];
    }
}

+ (void)requestAuthorization:(void(^)(MTAuthorizationStatus status))handler
{
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO_8_0) {
        [MTPHPhotoLibrary requestAuthorization:handler];
    }
    else {
        [MTALAssetsLibrary requestAuthorization:handler];
    }
}

- (instancetype)init
{
    if (self = [super init]) {
        if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO_8_0) {
            _photoManager = [MTPHPhotoLibrary sharedPhotoManager];
//            _photoManager = [MTALAssetsLibrary sharedPhotoManager];
        }
        else {
            _photoManager = [MTALAssetsLibrary sharedPhotoManager];
        }
    }
    return self;
}

- (void)registerChangeObserver:(id<MTPhotoLibraryChangeObserver>)observer
{
    [_photoManager registerChangeObserver:observer];
}

- (void)unregisterChangeObserver:(id<MTPhotoLibraryChangeObserver>)observer
{
    [_photoManager unregisterChangeObserver:observer];
}

- (void)createAlbum:(NSString *)title resultBlock:(MTPhotoManagerResultBlock)resultBlock
{
    [_photoManager createAlbum:title resultBlock:resultBlock];
}

- (void)checkAlbum:(NSString *)title resultBlock:(MTPhotoManagerCheckBlock)resultBlock
{
    [_photoManager checkAlbum:title resultBlock:resultBlock];
}

- (void)enumerateAlbums:(MTPhotoManagerAlbumEnumerationBlock)enumerationBlock resultBlock:(MTPhotoManagerResultBlock)resultBlock
{
    [_photoManager enumerateAlbums:enumerationBlock resultBlock:resultBlock];
}

- (void)addAsset:(MTPhotoAsset *)asset toAlbum:(MTPhotoAlbum *)photoAlbum resultBlock:(MTPhotoManagerResultBlock)resultBlock
{
    [_photoManager addAsset:asset toAlbum:photoAlbum resultBlock:resultBlock];
}

- (void)deleteAssets:(NSArray *)assets resultBlock:(MTPhotoManagerResultBlock)resultBlock
{
    [_photoManager deleteAssets:assets resultBlock:resultBlock];
}

- (void)deleteAlbums:(NSArray *)albums resultBlock:(MTPhotoManagerResultBlock)resultBlock
{
    [_photoManager deleteAlbums:albums resultBlock:resultBlock];
}

- (void)writeImageToSavedPhotosAlbum:(UIImage *)image resultBlock:(MTPhotoManagerWriteImageResultBlock)resultBlock
{
    [_photoManager writeImageToSavedPhotosAlbum:image resultBlock:resultBlock];
}

- (void)writeImage:(UIImage *)image toAlbum:(MTPhotoAlbum *)photoAlbum resultBlock:(MTPhotoManagerWriteImageResultBlock)resultBlock
{
    [_photoManager writeImage:image toAlbum:photoAlbum resultBlock:resultBlock];
}

- (void)writeImageDataToSavedPhotosAlbum:(NSData *)imageData metadata:(NSDictionary *)metadata resultBlock:(MTPhotoManagerWriteImageResultBlock)resultBlock
{
    [_photoManager writeImageDataToSavedPhotosAlbum:imageData metadata:metadata resultBlock:resultBlock];
}

- (void)writeImageData:(NSData *)imageData metadata:(NSDictionary *)metadata toAlbum:(MTPhotoAlbum *)photoAlbum resultBlock:(MTPhotoManagerWriteImageResultBlock)resultBlock
{
    [_photoManager writeImageData:imageData metadata:metadata toAlbum:photoAlbum resultBlock:resultBlock];
}

- (void)writeImageAtURLToSavedPhotosAlbum:(NSURL *)fileURL completeBlock:(MTPhotoManagerAssetsChangedBlock)completeBlock {
    
    [_photoManager writeImageAtURLToSavedPhotosAlbum:fileURL completeBlock:completeBlock];
}
- (void)writeMediaFileAtURLToSavedPhotosAlbum:(NSURL *)fileURL mediaType:(MTPhotoAssetMediaType)mediaType completeBlock:(MTPhotoManagerAssetsChangedBlock)completeBlock {
    
    [_photoManager writeMediaFileAtURLToSavedPhotosAlbum:fileURL mediaType:mediaType completeBlock:completeBlock];
}

- (void)writeVideoAtPathToSavedPhotosAlbum:(NSString *)filePath resultBlock:(MTPhotoManagerResultBlock)resultBlock
{
    [_photoManager writeVideoAtPathToSavedPhotosAlbum:filePath resultBlock:resultBlock];
}

-(void)writeVideoAtURLToSavedPhotosAlbum:(NSURL *)fileURL completeBlock:(MTPhotoManagerAssetsChangedBlock)completeBlock {
    
    [_photoManager writeVideoAtURLToSavedPhotosAlbum:fileURL completeBlock:completeBlock];
}

- (void)clearCached
{
    [_photoManager clearCached];
}

#pragma mark - API 1.0.1
- (NSMutableArray *)photoAlbums
{
    return [_photoManager photoAlbums];
}

- (NSMutableArray *)photoAlbumsWithFetchOption:(MTPhotoAlbumsFetchOption)fetchOption {
    return [_photoManager photoAlbumsWithFetchOption:fetchOption];
}

#pragma mark - PhotoAlbum API -bugfix 1.0.2
- (void)fetchPhotoAlbumsWith:(void(^)(NSMutableArray *photoAlbums))completionBlock
{
    [_photoManager fetchPhotoAlbumsWith:completionBlock];
}

- (void)fetchPhotoAlbumsWith:(MTPhotoAlbumsFetchOption)fetchOption completionBlock:(void(^)(NSMutableArray *photoAlbums))completionBlock {
    
    [_photoManager fetchPhotoAlbumsWith:fetchOption completionBlock:completionBlock];
}

- (void)fetchRecentPhotoAsset:(void (^)(MTPhotoAsset *))completionBlock {
    
    [_photoManager fetchRecentPhotoAsset:completionBlock];
}
@end
