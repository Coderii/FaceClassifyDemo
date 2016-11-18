//
//  MTImageManager.m
//  MTPhotoLibrary
//
//  Created by JoyChiang on 15/6/23.
//  Copyright (c) 2015年 Meitu. All rights reserved.
//

#import "MTImageManager.h"
#import "MTPhotoLibrary_Prefix.h"

@interface MTImageManager ()

@property (nonatomic, assign) CGSize cachingImageTargetSize;
@property (nonatomic, strong) PHCachingImageManager *imageManager;
@property (nonatomic, strong) PHImageRequestOptions *requestOptions;

@property (nonatomic, strong) NSMutableDictionary *cachedImages;

@end

@implementation MTImageManager

- (void)dealloc {
    _imageManager = nil;
    _requestOptions = nil;
    _cachedImages = nil;
}

- (id)init
{
    if (self = [super init]) {
        if ([MTImageManager isPHPhotoLibraryAuthorized]) {
            _imageManager = [[PHCachingImageManager alloc] init];
            
            _cachingImageTargetSize = [UIScreen mainScreen].bounds.size;
            _cachingImageTargetSize.width *= [UIScreen mainScreen].scale;
            _cachingImageTargetSize.height *= [UIScreen mainScreen].scale;
            
            _cachedImages = [NSMutableDictionary dictionary];
            self.requestOptions = [[PHImageRequestOptions alloc] init];
            self.requestOptions.deliveryMode = PHImageRequestOptionsDeliveryModeOpportunistic;
            self.requestOptions.resizeMode = PHImageRequestOptionsResizeModeFast;
        }
    }
    return self;
}

- (MTImageRequestID)requestThumbnailImageForAsset:(MTPhotoAsset *)asset
                                       targetSize:(CGSize)targetSize
                                      contentMode:(MTImageContentMode)contentMode
                                    resultHandler:(void (^)(UIImage *result, NSDictionary *info))resultHandler
{
    if ([[self class] isPHPhotoLibraryAuthorized]) {
        return [self.imageManager requestImageForAsset:asset.asPHAsset
                                            targetSize:targetSize
                                           contentMode:(PHImageContentMode)contentMode
                                               options:self.requestOptions
                                         resultHandler:^(UIImage *result, NSDictionary *info) {
                                             resultHandler(result, info);
                                         }];
    }
    else {
        UIImage *thumbnailImage = [UIImage imageWithCGImage:[asset asALAsset].thumbnail];
        resultHandler(thumbnailImage, nil);
        
        return MTInvalidImageRequestID;
    }
}

- (MTImageRequestID)requestImageForAsset:(MTPhotoAsset *)asset
                              targetSize:(CGSize)targetSize
                             contentMode:(MTImageContentMode)contentMode
                           resultHandler:(void (^)(UIImage *result, NSDictionary *info))resultHandler
{
    if ([[self class] isPHPhotoLibraryAuthorized]) {
        return [self.imageManager requestImageForAsset:asset.asPHAsset
                                            targetSize:targetSize
                                           contentMode:(PHImageContentMode)contentMode
                                               options:self.requestOptions
                                         resultHandler:^(UIImage *result, NSDictionary *info) {
                                             BOOL degraded = [info[PHImageResultIsDegradedKey] boolValue];
                                             if (!degraded) {
                                                 resultHandler(result, info);
                                             }
                                         }];
    }
    else {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            ALAssetRepresentation *defaultAssetRep = [asset asALAsset].defaultRepresentation;
            UIImage *image = [UIImage imageWithCGImage:defaultAssetRep.fullScreenImage];
            dispatch_async(dispatch_get_main_queue(), ^{
                resultHandler(image, nil);
            });
        });
        return MTInvalidImageRequestID;
    }
}

- (void)cancelImageRequest:(MTImageRequestID)requestID
{
    if ([[self class] isPHPhotoLibraryAuthorized]) {
        [self.imageManager cancelImageRequest:requestID];
    }
}

- (void)startCachingImagesForAssets:(NSArray *)assets
                         targetSize:(CGSize)targetSize
                        contentMode:(MTImageContentMode)contentMode
{
    if ([[self class] isPHPhotoLibraryAuthorized]) {
        NSMutableArray *phAssets = [NSMutableArray arrayWithCapacity:assets.count];
        [assets enumerateObjectsUsingBlock:^(MTPhotoAsset *obj, NSUInteger idx, BOOL *stop) {
            if ([obj isKindOfClass:[MTPhotoAsset class]]) {
                [phAssets addObject:obj.asPHAsset];
            }
            else
            {
                [phAssets addObject:obj];
            }
        }];
        
        [self.imageManager startCachingImagesForAssets:phAssets
                                            targetSize:targetSize
                                           contentMode:(PHImageContentMode)contentMode
                                               options:self.requestOptions];
    }
}

- (void)stopCachingImagesForAssets:(NSArray *)assets
                        targetSize:(CGSize)targetSize
                       contentMode:(MTImageContentMode)contentMode
{
    if ([[self class] isPHPhotoLibraryAuthorized]) {
        NSMutableArray *phAssets = [NSMutableArray arrayWithCapacity:assets.count];
        [assets enumerateObjectsUsingBlock:^(MTPhotoAsset *obj, NSUInteger idx, BOOL *stop) {
            if ([obj isKindOfClass:[MTPhotoAsset class]]) {
                [phAssets addObject:obj.asPHAsset];
            }
            else
            {
                [phAssets addObject:obj];
            }
        }];
        
        [self.imageManager stopCachingImagesForAssets:phAssets
                                           targetSize:targetSize
                                          contentMode:(PHImageContentMode)contentMode
                                              options:self.requestOptions];
    }
}

- (void)stopCachingImagesForAllAssets
{
    [_cachedImages removeAllObjects];
    
    if ([[self class] isPHPhotoLibraryAuthorized]) {
        [self.imageManager stopCachingImagesForAllAssets];
    }
}

+ (BOOL) isPHPhotoLibraryAuthorized {
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO_8_0) {
        if ([PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusAuthorized) {
            return YES;
        }
        return NO;
    }
    return NO;
}

@end
