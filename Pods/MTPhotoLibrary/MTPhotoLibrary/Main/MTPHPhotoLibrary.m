//
//  MTPHPhotoLibrary.m
//  MTPhotoLibrary
//
//  Created by JoyChiang on 15/6/20.
//  Copyright (c) 2015年 Meitu. All rights reserved.
//

#import "MTPHPhotoLibrary.h"
#import "MTPhotoLibrary_Prefix.h"

@interface MTPHPhotoLibrary () <PHPhotoLibraryChangeObserver>
{
    BOOL _inRangeiOS8And8_1;
    BOOL _isUpdateAlbum;
}

@property (nonatomic, strong) NSMutableArray *collectionsFetchResults;
@property (nonatomic, strong) NSMutableArray *assetCollections;

@property (nonatomic, strong) NSMutableArray *allFetchResults;


#pragma mark - API 1.0.1
@property (nonatomic, strong) NSMutableArray *photoAlbums;
@property (nonatomic, assign) MTPhotoAlbumsFetchOption fetchOption;
@property (nonatomic, strong) NSHashTable *changeObservers;


@property (nonatomic, strong) dispatch_queue_t concurrentQuene;
@end

@implementation MTPHPhotoLibrary

static MTPHPhotoLibrary *sharedPhotoManager = nil;
+ (id<MTPhotoManager>)sharedPhotoManager
{
    if (sharedPhotoManager == nil) {
        sharedPhotoManager = [[MTPHPhotoLibrary alloc] init];
    }
    return sharedPhotoManager;
}

+ (void)clearData
{
    sharedPhotoManager = nil;
}

+ (MTAuthorizationStatus)authorizationStatusFromPHAuthorizationStatus:(PHAuthorizationStatus)authorizationStatus
{
    MTAuthorizationStatus authStatus = MTAuthorizationStatusNotDetermined;
    switch (authorizationStatus) {
        case PHAuthorizationStatusRestricted:
            authStatus = MTAuthorizationStatusRestricted;
            break;
        case PHAuthorizationStatusDenied:
            authStatus = MTAuthorizationStatusDenied;
            break;
        case PHAuthorizationStatusAuthorized:
            authStatus = MTAuthorizationStatusAuthorized;
            break;
        case PHAuthorizationStatusNotDetermined:
        default:
            authStatus = MTAuthorizationStatusNotDetermined;
            break;
    }
    return authStatus;
}

+ (MTAuthorizationStatus)authorizationStatus
{
    return [[self class] authorizationStatusFromPHAuthorizationStatus:[PHPhotoLibrary authorizationStatus]];
}

+ (void)requestAuthorization:(void(^)(MTAuthorizationStatus status))handler
{
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (handler) {
                handler([[self class] authorizationStatusFromPHAuthorizationStatus:status]);
            }
        });
    }];
}

- (void)dealloc
{
    [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];
    [_changeObservers removeAllObjects];
    _changeObservers = nil;
}

- (instancetype)init
{
    if (self = [super init]) {
        if ([[[UIDevice currentDevice] systemVersion] floatValue] < 8.1) {
            _inRangeiOS8And8_1 = YES;
        }
        
        [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
        
        PHFetchResult *smartAlbumResult = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum
                                                                               subtype:PHAssetCollectionSubtypeAny
                                                                               options:nil];

        PHFetchResult *albumResult = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum
                                                                             subtype:PHAssetCollectionSubtypeAny
                                                                             options:nil];
        
        
        self.allFetchResults = [NSMutableArray array];
        self.photoAlbums = [NSMutableArray array];
        [self.allFetchResults addObject:smartAlbumResult];
        [self.allFetchResults addObject:albumResult];
        
        [self updateCollectionsFetchResultAndAssetCollections];
        [self updatePhotoAlbumsWith:nil];
        
        _changeObservers = [NSHashTable hashTableWithOptions:NSPointerFunctionsWeakMemory];
        
        self.concurrentQuene = dispatch_queue_create("com.mt.PHPhotoLibraryCurrent", DISPATCH_QUEUE_CONCURRENT);
    }
    return self;
}


// 过滤相册Asset的options
- (PHFetchOptions *)filterFetchOptions
{
    NSPredicate *predicate;
    switch (self.fetchOption) {
        case MTPhotoAlbumsFetchOptionAll:
            predicate = [NSPredicate predicateWithFormat:@"mediaType = %d || mediaType = %d", PHAssetMediaTypeImage, PHAssetMediaTypeVideo];
            break;
        case MTPhotoAlbumsFetchOptionVideos:
            predicate = [NSPredicate predicateWithFormat:@"mediaType = %d", PHAssetMediaTypeVideo];
            break;
        case MTPhotoAlbumsFetchOptionPhotos:
        default:
            predicate = [NSPredicate predicateWithFormat:@"mediaType = %d", PHAssetMediaTypeImage];
            break;
    }
    
    PHFetchOptions *filterFetchOptions = [[PHFetchOptions alloc] init];
//    filterFetchOptions.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
    filterFetchOptions.predicate = predicate;
    return filterFetchOptions;
}

// 更新数据
- (void)updateCollectionsFetchResultAndAssetCollections
{
    NSMutableArray *collectionsFetchResults = [NSMutableArray array];
    NSMutableArray *assetCollections = [NSMutableArray array];
    [self.allFetchResults enumerateObjectsUsingBlock:^(PHFetchResult *fecthResut, NSUInteger idx, BOOL * stop) {
        for (NSInteger i =0; i < fecthResut.count; i++) {
            @autoreleasepool {
                PHAssetCollection *assetCollection = fecthResut[i];
                PHFetchResult *assetsFetchResult = [PHAsset fetchAssetsInAssetCollection:assetCollection options:[self filterFetchOptions]];
                [collectionsFetchResults addObject:assetsFetchResult];
                [assetCollections addObject:assetCollection];
            }
        }
    }];
    
    self.collectionsFetchResults = collectionsFetchResults;
    self.assetCollections = assetCollections;
}

- (void)registerChangeObserver:(id<MTPhotoLibraryChangeObserver>)observer
{
    dispatch_barrier_sync(self.concurrentQuene, ^{
        [self.changeObservers addObject:observer];
    });
}

- (void)unregisterChangeObserver:(id<MTPhotoLibraryChangeObserver>)observer
{
    if (!self.changeObservers || self.changeObservers.count == 0) {
        return;
    }
    dispatch_barrier_sync(self.concurrentQuene, ^{
        [self.changeObservers removeObject:observer];
    });
}

- (void)createAlbum:(NSString *)title resultBlock:(MTPhotoManagerResultBlock)resultBlock
{
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        [PHAssetCollectionChangeRequest creationRequestForAssetCollectionWithTitle:title];
    } completionHandler:^(BOOL success, NSError *error) {
        if (resultBlock) {
            resultBlock(success, error);
        }
    }];
}

- (void)checkAlbum:(NSString *)title resultBlock:(MTPhotoManagerCheckBlock)resultBlock
{
    __block MTPhotoAlbum *foundAlbum = nil;
    [self enumerateAlbums:^(MTPhotoAlbum *album, BOOL *stop) {
        if ([album.title isEqualToString:title]) {
            foundAlbum = album;
            *stop = YES;
        }
    } resultBlock:^(BOOL success, NSError *error) {
        if (resultBlock) {
            resultBlock(foundAlbum, error);
        }
    }];
}

- (void)enumerateAlbums:(MTPhotoManagerAlbumEnumerationBlock)enumerationBlock resultBlock:(MTPhotoManagerResultBlock)resultBlock
{
    void (^notifyResult)(BOOL success, NSError *error) = ^(BOOL success, NSError *error) {
        if (resultBlock) {
            resultBlock(success, error);
        }
    };
    
    [self.assetCollections enumerateObjectsUsingBlock:^(PHAssetCollection *assetCollection, NSUInteger idx, BOOL * stop) {
        
        PHFetchResult *fetchResult = [self.collectionsFetchResults objectAtIndex:idx];
        
        
        MTPhotoAlbum *photoAlbum = [[MTPhotoAlbum alloc] initWithPHAssetCollection:assetCollection assetFecthResult:fetchResult];
        
        if (enumerationBlock) {
            enumerationBlock(photoAlbum, stop);
        }
        
    }];
    notifyResult(YES, nil);
}

- (void)addAsset:(PHAsset *)asset toAlbum:(MTPhotoAlbum *)photoAlbum resultBlock:(MTPhotoManagerResultBlock)resultBlock
{
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        PHAssetCollectionChangeRequest *collectionRequest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:[photoAlbum assetCollection]];
        [collectionRequest addAssets:@[asset]];
    } completionHandler:^(BOOL success, NSError *error) {
        if (resultBlock) {
            resultBlock(success, error);
        }
    }];
}

- (void)deleteAssets:(NSArray *)assets resultBlock:(MTPhotoManagerResultBlock)resultBlock
{
    NSMutableArray *deleteAssets = [NSMutableArray array];
    for (PHAsset *asset in assets) {
        @autoreleasepool {
            [deleteAssets addObject:asset];
        }
        
    }
    if (0 == deleteAssets.count) {
        if (resultBlock) {
            resultBlock(YES, nil);
        }
        return;
    }
    
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        [PHAssetChangeRequest deleteAssets:deleteAssets];
    } completionHandler:^(BOOL success, NSError *error) {
        if (resultBlock) {
            resultBlock(success, error);
        }
    }];
}

- (void)deleteAlbums:(NSArray *)albums resultBlock:(MTPhotoManagerResultBlock)resultBlock
{
    NSMutableArray *deleteAlbums = [NSMutableArray array];
    for (MTPhotoAlbum *album in albums) {
        @autoreleasepool {
            [deleteAlbums addObject:[album assetCollection]];
        }
    }
    if (0 == deleteAlbums.count) {
        if (resultBlock) {
            resultBlock(YES, nil);
        }
        return;
    }
    
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        [PHAssetCollectionChangeRequest deleteAssetCollections:deleteAlbums];
    } completionHandler:^(BOOL success, NSError *error) {
        if (resultBlock) {
            resultBlock(success, error);
        }
    }];
}

- (void)writeImageToSavedPhotosAlbum:(UIImage *)image resultBlock:(MTPhotoManagerWriteImageResultBlock)resultBlock
{
    NSData *imageData = UIImageJPEGRepresentation(image, 1.0);
    [self writeImageDataToSavedPhotosAlbum:imageData metadata:nil resultBlock:resultBlock];
//    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
//        [PHAssetChangeRequest creationRequestForAssetFromImage:image];
//    } completionHandler:^(BOOL success, NSError *error) {
//       
//        if (resultBlock) {
//            MTPhotoAlbum *album = self.photoAlbums[0];
//            [album reloadALAssets];
//            MTPhotoAsset *asset = [album assetAtIndex:album.numberOfAssets - 1];
//            resultBlock(success, error, asset);
//        }
//    }];
}

- (void)writeImage:(UIImage *)image toAlbum:(MTPhotoAlbum *)photoAlbum resultBlock:(MTPhotoManagerWriteImageResultBlock)resultBlock
{
    NSData *imageData = UIImageJPEGRepresentation(image, 1.0);
    [self writeImageData:imageData metadata:nil toAlbum:photoAlbum resultBlock:resultBlock];
}

- (UIImage *)imageWithData:(NSData *)imageData metadata:(NSDictionary *)metadata
{
    CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)imageData, NULL);
    NSMutableDictionary *source_metadata = [(NSMutableDictionary *)CFBridgingRelease(CGImageSourceCopyProperties(source, NULL)) mutableCopy];
    [source_metadata addEntriesFromDictionary:metadata];
    
    NSMutableData *dest_data = [NSMutableData data];
    CFStringRef UTI = CGImageSourceGetType(source);
    CGImageDestinationRef destination = CGImageDestinationCreateWithData((__bridge CFMutableDataRef)dest_data, UTI, 1,NULL);
    CGImageDestinationAddImageFromSource(destination, source, 0, (__bridge CFDictionaryRef)source_metadata);
    CGImageDestinationFinalize(destination);
    CFRelease(source);
    CFRelease(destination);
    return [UIImage imageWithData:dest_data];
}

- (void)writeImageDataToSavedPhotosAlbum:(NSData *)imageData metadata:(NSDictionary *)metadata resultBlock:(MTPhotoManagerWriteImageResultBlock)resultBlock
{
    
    __block NSString *assetID = nil;
    
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"9.0") && [PHAssetCreationRequest supportsAssetResourceTypes:@[@(PHAssetResourceTypePhoto)]]) {
        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
           
            PHAssetCreationRequest *request = [PHAssetCreationRequest creationRequestForAsset];
            [request addResourceWithType:PHAssetResourceTypePhoto
                                    data:imageData
                                options:nil];
            assetID = request.placeholderForCreatedAsset.localIdentifier;
        } completionHandler:^(BOOL success, NSError *error) {
            
            if (success && resultBlock && assetID) {
                MTPhotoAsset *asset = [MTPhotoAsset fetchAssetWithLocalIdentifier:assetID];
                if (resultBlock) {
                    
                    resultBlock(success, error, asset);
                }
        
            } else {
                
                if (resultBlock) {
                    resultBlock(success, error, nil);
                }
            }
        }];
    } else {
        
        NSString *temporaryFileName = [NSProcessInfo processInfo].globallyUniqueString;
        NSString *temporaryFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:[temporaryFileName stringByAppendingPathExtension:@"jpg"]];
        NSURL *temporaryFileURL = [NSURL fileURLWithPath:temporaryFilePath];
        
        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
            NSError *error = nil;
            [imageData writeToURL:temporaryFileURL options:NSDataWritingAtomic error:&error];
            if (error) {
                NSLog(@"Error occured while writing image data to a temporary file: %@", error);
            } else {
                PHAssetChangeRequest *request = [PHAssetChangeRequest creationRequestForAssetFromImageAtFileURL:temporaryFileURL];
                assetID = request.placeholderForCreatedAsset.localIdentifier;
            }
        } completionHandler:^(BOOL success, NSError *error) {
            // Delete the temporary file.
            NSError *removeError = nil;
            [[NSFileManager defaultManager] removeItemAtURL:temporaryFileURL error:&removeError];
            
            if (success && resultBlock && assetID) {
                MTPhotoAsset *asset = [MTPhotoAsset fetchAssetWithLocalIdentifier:assetID];
                if (resultBlock) {
                    
                    resultBlock(success, error, asset);
                }
                
            } else {
                
                if (resultBlock) {
                    resultBlock(success, error, nil);
                }
            }
        }];
    }
    
    /*
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        UIImage *image = [self imageWithData:imageData metadata:metadata];
        [PHAssetChangeRequest creationRequestForAssetFromImage:image];
    } completionHandler:^(BOOL success, NSError *error) {
        if (resultBlock) {
            resultBlock(success, error);
        }
    }];
     */
}

- (void)writeImageData:(NSData *)imageData metadata:(NSDictionary *)metadata toAlbum:(MTPhotoAlbum *)photoAlbum resultBlock:(MTPhotoManagerWriteImageResultBlock)resultBlock
{
    __block NSString *assetID = nil;
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"9.0") && [PHAssetCreationRequest supportsAssetResourceTypes:@[@(PHAssetResourceTypePhoto)]]) { //iOS9
        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
            PHAssetCreationRequest *request = [PHAssetCreationRequest creationRequestForAsset];
            [request addResourceWithType:PHAssetResourceTypePhoto
                                    data:imageData
                                 options:nil];
            assetID = request.placeholderForCreatedAsset.localIdentifier;
            PHAssetCollectionChangeRequest *collectionRequest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:[photoAlbum assetCollection]];
            [collectionRequest addAssets:@[request.placeholderForCreatedAsset]];
        } completionHandler:^(BOOL success, NSError *error) {
            
            if (success && resultBlock && assetID) {
                MTPhotoAsset *asset = [MTPhotoAsset fetchAssetWithLocalIdentifier:assetID];
                if (resultBlock) {
                    
                    resultBlock(success, error, asset);
                }
                
            } else {
                
                if (resultBlock) {
                    resultBlock(success, error, nil);
                }
            }

        }];
    } else { //iOS8
        
        NSString *temporaryFileName = [NSProcessInfo processInfo].globallyUniqueString;
        NSString *temporaryFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:[temporaryFileName stringByAppendingPathExtension:@"jpg"]];
        NSURL *temporaryFileURL = [NSURL fileURLWithPath:temporaryFilePath];
        
        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
            NSError *error = nil;
            [imageData writeToURL:temporaryFileURL options:NSDataWritingAtomic error:&error];
            if (error) {
                NSLog(@"Error occured while writing image data to a temporary file: %@", error);
            } else {
                PHAssetChangeRequest *assetRequest = [PHAssetChangeRequest creationRequestForAssetFromImageAtFileURL:temporaryFileURL];
                PHAssetCollectionChangeRequest *collectionRequest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:[photoAlbum assetCollection]];
                [collectionRequest addAssets:@[assetRequest.placeholderForCreatedAsset]];
                assetID = assetRequest.placeholderForCreatedAsset.localIdentifier;
            }
        } completionHandler:^(BOOL success, NSError *error) {
            // Delete the temporary file.
            NSError *removeError = nil;
            [[NSFileManager defaultManager] removeItemAtURL:temporaryFileURL error:&removeError];
            
            if (success && resultBlock && assetID) {
                MTPhotoAsset *asset = [MTPhotoAsset fetchAssetWithLocalIdentifier:assetID];
                if (resultBlock) {
                    
                    resultBlock(success, error, asset);
                }
                
            } else {
                
                if (resultBlock) {
                    resultBlock(success, error, nil);
                }
            }
        }];
    }

    
    /*
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        UIImage *image = [self imageWithData:imageData metadata:metadata];
        PHAssetChangeRequest *assetRequest = [PHAssetChangeRequest creationRequestForAssetFromImage:image];
        PHAssetCollectionChangeRequest *collectionRequest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:[photoAlbum assetCollection]];
        [collectionRequest addAssets:@[assetRequest.placeholderForCreatedAsset]];
    } completionHandler:^(BOOL success, NSError *error) {
        if (resultBlock) {
            resultBlock(success, error);
        }
    }];
    */
}

- (void)writeVideoAtPathToSavedPhotosAlbum:(NSString *)filePath resultBlock:(MTPhotoManagerResultBlock)resultBlock
{
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:[NSURL fileURLWithPath:filePath]];
    } completionHandler:^(BOOL success, NSError *error) {
        if (resultBlock) {
            resultBlock(success, error);
        }
    }];
}

- (void)writeVideoAtURLToSavedPhotosAlbum:(NSURL *)fileURL completeBlock:(MTPhotoManagerAssetsChangedBlock)completeBlock
{
    __block NSString *localIdentifier = nil;
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        PHAssetChangeRequest *request = [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:fileURL];
        localIdentifier = request.placeholderForCreatedAsset.localIdentifier;
    } completionHandler:^(BOOL success, NSError *error) {
        if (completeBlock) {
            NSArray *changedLocalIdentifiers = nil;
            if (localIdentifier) {
                changedLocalIdentifiers = @[localIdentifier];
            }
            completeBlock(success, changedLocalIdentifiers, error);
        }
    }];
}


// 将App沙盒目录下的Image保存到相册
- (void)writeImageAtURLToSavedPhotosAlbum:(NSURL *)fileURL completeBlock:(MTPhotoManagerAssetsChangedBlock)completeBlock
{
    __block NSString *localIdentifier = nil;
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        PHAssetChangeRequest *request = [PHAssetChangeRequest creationRequestForAssetFromImageAtFileURL:fileURL];
        localIdentifier = request.placeholderForCreatedAsset.localIdentifier;
    } completionHandler:^(BOOL success, NSError *error) {
        if (completeBlock) {
            NSArray *changedLocalIdentifiers = nil;
            if (localIdentifier) {
                changedLocalIdentifiers = @[localIdentifier];
            }
            completeBlock(success, changedLocalIdentifiers, error);
        }
    }];
 
}

- (void)writeMediaFileAtURLToSavedPhotosAlbum:(NSURL *)fileURL
                                    mediaType:(MTPhotoAssetMediaType)mediaType
                                completeBlock:(MTPhotoManagerAssetsChangedBlock)completeBlock
{
    if (mediaType == MTPhotoAssetMediaTypeVideo) {
        [self writeVideoAtURLToSavedPhotosAlbum:fileURL completeBlock:completeBlock];
    }else {
        [self writeImageAtURLToSavedPhotosAlbum:fileURL completeBlock:completeBlock];
    }
}

#pragma mark - PHPhotoLibraryChangeObserver
- (void)photoLibraryDidChange:(PHChange *)changeInstance
{
    
    [self updateALbumsForPhotoLibraryDidChange:changeInstance];

    dispatch_sync(self.concurrentQuene, ^{
        
        for (id<MTPhotoLibraryChangeObserver> changeObserver in self.changeObservers) {
        
            dispatch_async(dispatch_get_main_queue(), ^{
                
                if ([changeObserver conformsToProtocol:@protocol(MTPhotoLibraryChangeObserver)]) {
                    [changeObserver photoLibraryDidChange:changeInstance/*photoChange*/];
                }
                
            });
        }
   });
}

- (void)updateALbumsForPhotoLibraryDidChange:(PHChange *)changeInstance
{
    _isUpdateAlbum = YES;   //需要更新数据
    NSMutableArray *updatedCollectionsFetchResults = [self.allFetchResults mutableCopy];
    for (PHFetchResult *collectionsFetchResult in self.allFetchResults) {
        @autoreleasepool {
            PHFetchResultChangeDetails *changeDetails = [changeInstance changeDetailsForFetchResult:collectionsFetchResult];
            if (changeDetails) {
                [updatedCollectionsFetchResults replaceObjectAtIndex:[self.allFetchResults indexOfObject:collectionsFetchResult]
                                                          withObject:[changeDetails fetchResultAfterChanges]];
            }
        }
    }
    self.allFetchResults = updatedCollectionsFetchResults;
    [self updateCollectionsFetchResultAndAssetCollections];
    [self updatePhotoAlbumsWith:changeInstance];
    
}


- (void)clearCached
{
    dispatch_barrier_sync(self.concurrentQuene, ^{
            [self.changeObservers removeAllObjects];
    });
}


- (MTPhotoAlbum *)photoAlbumWithPHAssetCollection:(PHAssetCollection *)assetCollection assetFecthResult:(PHFetchResult *)fetchResult
{
    __block MTPhotoAlbum *photoAlbum = nil;
    [self.photoAlbums enumerateObjectsUsingBlock:^(MTPhotoAlbum  *album, NSUInteger idx, BOOL *stop) {
        if ([album.assetCollection isEqual:assetCollection]) {
            photoAlbum = album;
            [photoAlbum updatePHAssetCollection:assetCollection assetFecthResult:fetchResult];
            *stop = YES;
        }
    }];
    
    if (!photoAlbum) {
        photoAlbum = [[MTPhotoAlbum alloc] initWithPHAssetCollection:assetCollection assetFecthResult:fetchResult];
    }
    return photoAlbum;
}



#pragma mark - API 1.0.1
- (void)updatePhotoAlbumsWith:(PHChange *)changeInstance
{
    if (changeInstance) {
        [self.photoAlbums enumerateObjectsUsingBlock:^(MTPhotoAlbum *obj, NSUInteger idx, BOOL *stop) {
            if (changeInstance) {
                [obj changeDetailsFromPHChange:changeInstance];
            }
        }];
    }
    
    NSMutableArray *photoAlbums = [NSMutableArray array];
    [self.assetCollections enumerateObjectsUsingBlock:^(PHAssetCollection *assetCollection, NSUInteger idx, BOOL *stop) {
        PHFetchResult *fetchResult = [self.collectionsFetchResults objectAtIndex:idx];
        if (fetchResult) {
            MTPhotoAlbum *photoAlbum = [self photoAlbumWithPHAssetCollection:assetCollection assetFecthResult:fetchResult];
            if (_inRangeiOS8And8_1 && assetCollection.assetCollectionSubtype == PHAssetCollectionSubtypeSmartAlbumRecentlyAdded) {
                [photoAlbums insertObject:photoAlbum atIndex:0];
            }
            else
            {
                // "相机胶卷"放置到首位
                if (assetCollection.assetCollectionType == PHAssetCollectionTypeSmartAlbum &&
                    assetCollection.assetCollectionSubtype == PHAssetCollectionSubtypeSmartAlbumUserLibrary) {
                    [photoAlbums insertObject:photoAlbum atIndex:0];
                } else {
                    [photoAlbums addObject:photoAlbum];
                }
            }
        }
    }];
    
    self.photoAlbums = photoAlbums;
}

- (NSMutableArray *)photoAlbumsWithFetchOption:(MTPhotoAlbumsFetchOption)fetchOption {
    
    if (fetchOption != self.fetchOption) {
        self.fetchOption = fetchOption;
        [self updateCollectionsFetchResultAndAssetCollections];
        [self updatePhotoAlbumsWith:nil];
    }
    return self.photoAlbums;
}

#pragma mark - PhotoAlbum API -bugfix 1.0.2
- (void)fetchPhotoAlbumsWith:(void(^)(NSMutableArray *photoAlbums))completionBlock
{
    if (_photoAlbums.count == 0 || _isUpdateAlbum) {
        [self updateCollectionsFetchResultAndAssetCollections];
        [self updatePhotoAlbumsWith:nil];
        _isUpdateAlbum = NO;
        
    }
//    else {
//        
//        
//    }
    
    if (completionBlock) {
        completionBlock(self.photoAlbums);
    }
}

/**
 *  获取相册列表接口 （说明:IOS7 内部相册列表获取需要枚举遍历，耗时会比较久）
 *
 *  @param fetchOption     过滤相册中media的类型 @see MTPhotoAlbumsFetchOption
 *  @param completionBlock 结束回调块
 */
- (void)fetchPhotoAlbumsWith:(MTPhotoAlbumsFetchOption)fetchOption completionBlock:(void(^)(NSMutableArray *photoAlbums))completionBlock
{
    if (fetchOption != self.fetchOption) {
        self.fetchOption = fetchOption;
        [self updateCollectionsFetchResultAndAssetCollections];
        [self updatePhotoAlbumsWith:nil];
    }
    
    if (completionBlock) {
        completionBlock(self.photoAlbums);
    }
}


- (void)fetchRecentPhotoAsset:(void (^)(MTPhotoAsset *))completionBlock {
    
    __weak typeof(self) weakSelf = self;
    __block MTPhotoAlbum *ablum = nil;
    if (self.photoAlbums.count > 0) {
        
        for (MTPhotoAlbum *tempAlbum in self.photoAlbums) {
            
            if (tempAlbum.numberOfAssets > 0) {
                
                ablum = tempAlbum;
                break;
            }
        }
        MTPhotoAsset *photoAsset = [weakSelf fetchRecentPhotoAssetAtFirstAlbum:ablum];
        completionBlock(photoAsset);
        return;
    }
    
    [self fetchPhotoAlbumsWith:^(NSMutableArray *photoAlbums) {
        
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (photoAlbums.count > 0) {
            
            for (MTPhotoAlbum *tempAlbum in self.photoAlbums) {
                
                if (tempAlbum.numberOfAssets > 0) {
                    
                    ablum = tempAlbum;
                    break;
                }
            }
            MTPhotoAsset *photoAsset = [strongSelf fetchRecentPhotoAssetAtFirstAlbum:ablum];
            completionBlock(photoAsset);
            return;
        }
        completionBlock(nil);
    }];
}

- (MTPhotoAsset *)fetchRecentPhotoAssetAtFirstAlbum:(MTPhotoAlbum *)album {
    
    if (album.asPHAssets.count > 0) {
        
        PHAsset *asset = [album.asPHAssets lastObject];
        MTPhotoAsset *photoAsset = [MTPhotoAsset photoAssetWithPHAsset:asset];
        return photoAsset;
    }
    return nil;
}

@end
