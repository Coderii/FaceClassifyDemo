//
//  MTALAssetsLibrary.m
//  MTPhotoLibrary
//
//  Created by JoyChiang on 15/6/20.
//  Copyright (c) 2015年 Meitu. All rights reserved.
//

#import "MTALAssetsLibrary.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "MTPhotoLibrary_Prefix.h"
#import "NSURL+ALAssetsGroup.h"



@interface MTALAssetsLibrary ()
{
    ALAssetsLibrary *_assetsLibrary;
    
    BOOL _bUpdateAlbums;    // 是否需要更新相册列表
}

@property (copy, nonatomic) NSDictionary *lastNotificationUserInfo;

#pragma mark - API 1.0.1
@property (nonatomic, strong) NSMutableArray *photoAlbums;
@property (nonatomic, strong) NSMutableArray *photoAlbumIDs;
@property (nonatomic, assign) MTPhotoAlbumsFetchOption fetchOption;
@property (nonatomic, strong) ALAssetsFilter *assetFilter;
@property (nonatomic, strong) NSHashTable *changeObservers;

@end

@implementation MTALAssetsLibrary

static MTALAssetsLibrary *sharedPhotoManager = nil;
+ (id<MTPhotoManager>)sharedPhotoManager
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedPhotoManager = [MTALAssetsLibrary new];
    });
    return sharedPhotoManager;
}

+ (MTAuthorizationStatus)authorizationStatusFromALAuthorizationStatus:(ALAuthorizationStatus)authorizationStatus
{
    MTAuthorizationStatus authStatus = MTAuthorizationStatusNotDetermined;
    switch (authorizationStatus) {
        case ALAuthorizationStatusRestricted:
            authStatus = MTAuthorizationStatusRestricted;
            break;
        case ALAuthorizationStatusDenied:
            authStatus = MTAuthorizationStatusDenied;
            break;
        case ALAuthorizationStatusAuthorized:
            authStatus = MTAuthorizationStatusAuthorized;
            break;
        case ALAuthorizationStatusNotDetermined:
        default:
            authStatus = MTAuthorizationStatusNotDetermined;
            break;
    }
    return authStatus;
}

+ (MTAuthorizationStatus)authorizationStatus
{
    return [[self class] authorizationStatusFromALAuthorizationStatus:[ALAssetsLibrary authorizationStatus]];
}

+ (void)requestAuthorization:(void(^)(MTAuthorizationStatus status))handler
{
    @autoreleasepool {
        ALAssetsLibrary *testLibrary = [ALAssetsLibrary new];
        [testLibrary enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
            if (nil == group) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (handler) {
                        handler([[self class] authorizationStatus]);
                    }
                });
                return;
            }
            *stop = YES;
        } failureBlock:^(NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (handler) {
                    handler([[self class] authorizationStatus]);
                }
            });
        }];
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_changeObservers removeAllObjects];
    _changeObservers = nil;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _assetsLibrary = [[ALAssetsLibrary alloc] init];
        _changeObservers = [NSHashTable hashTableWithOptions:NSPointerFunctionsWeakMemory];
        _bUpdateAlbums = YES;
        [self updatePhotoAlbumsWith:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(assetsLibraryDidChange:)
                                                     name:ALAssetsLibraryChangedNotification
                                                   object:nil];
    }
    return self;
}

- (void)updatePhotoAlbumsWith:(NSNotification *)note
{
    if (note != nil) {
        if (note.userInfo.count) {
            // 删除相册
            NSSet *deleteGroupsSet = [note.userInfo objectForKey:ALAssetLibraryDeletedAssetGroupsKey];
            if (deleteGroupsSet.count) {
                [deleteGroupsSet enumerateObjectsUsingBlock:^(NSURL *deleteGroup, BOOL * _Nonnull stop) {
                    NSString *deleteGroupID = [deleteGroup photolibrary_assetsGroupID];
                    NSUInteger index = [self.photoAlbumIDs indexOfObject:deleteGroupID];
                    if (index != NSNotFound) {
                        [self.photoAlbumIDs removeObject:deleteGroupID];
                        MTPhotoAlbum *deleteAlbum = [self.photoAlbums objectAtIndex:index];
                        [self.photoAlbums removeObject:deleteAlbum];
                    }
                }];
            }
            
            // 新增相册
            NSSet *addGroupsSet = [note.userInfo objectForKey:ALAssetLibraryInsertedAssetGroupsKey];
            if (addGroupsSet.count) {
                [addGroupsSet enumerateObjectsUsingBlock:^(NSURL *insertedGroup, BOOL * _Nonnull stop) {
                    NSString *insertedGroupID = [insertedGroup photolibrary_assetsGroupID];
                    NSUInteger index = [self.photoAlbumIDs indexOfObject:insertedGroupID];
                    if (index == NSNotFound) {
                        _bUpdateAlbums = YES;
                    }
                }];
            }
            
            // 相册变更
            NSSet *updateGroupsSet = [note.userInfo objectForKey:ALAssetLibraryUpdatedAssetGroupsKey];
            if (updateGroupsSet.count) {
                _bUpdateAlbums = YES;
                [updateGroupsSet enumerateObjectsUsingBlock:^(NSURL *updateGroupURL, BOOL * _Nonnull stop) {
                    [_assetsLibrary groupForURL:updateGroupURL resultBlock:^(ALAssetsGroup *group) {
                        [group setAssetsFilter:[self assetFilter]];
                        /*
                        if (group.numberOfAssets == 0) {
                            NSString *deleteGroupID = [updateGroupURL photolibrary_assetsGroupID];
                            NSUInteger index = [self.photoAlbumIDs indexOfObject:deleteGroupID];
                            if (index != NSNotFound) {
                                [self.photoAlbumIDs removeObject:deleteGroupID];
                                MTPhotoAlbum *deleteAlbum = [self.photoAlbums objectAtIndex:index];
                                [self.photoAlbums removeObject:deleteAlbum];
                              
                            }
                        }
                        else
                        {
                            NSString *updateGroupID = [updateGroupURL photolibrary_assetsGroupID];
                            NSUInteger index = [self.photoAlbumIDs indexOfObject:updateGroupID];
                            if (index != NSNotFound) {
                                MTPhotoAlbum *updateAlbum = [self.photoAlbums objectAtIndex:index];
                                [_assetsLibrary groupForURL:updateGroupURL resultBlock:^(ALAssetsGroup *group) {
                                    [group setAssetsFilter:[self assetFilter]];
                                    updateAlbum.assetsGroup = group;
                                } failureBlock:^(NSError *error) {
                                    
                                }];
                            }
                        }
                        */

                        NSString *updateGroupID = [updateGroupURL photolibrary_assetsGroupID];
                        NSUInteger index = [self.photoAlbumIDs indexOfObject:updateGroupID];
                        if (index != NSNotFound) {
                            MTPhotoAlbum *updateAlbum = [self.photoAlbums objectAtIndex:index];
                            [_assetsLibrary groupForURL:updateGroupURL resultBlock:^(ALAssetsGroup *group) {
                                [group setAssetsFilter:[self assetFilter]];
                                updateAlbum.assetsGroup = group;
                            } failureBlock:^(NSError *error) {
                            }];
                        }
                    } failureBlock:^(NSError *error) {
                    }];
                }];
                
            }
        }
    }
    else
    {
        NSMutableArray *groups = [NSMutableArray array];
        NSMutableArray *albumIDGroups = [NSMutableArray array];
        [_assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
            // 根据fetchOption确定获取的资源类型
            [group setAssetsFilter:[self assetFilter]];
            // 系统相册默认加在第一个
            if (group) {
                MTPhotoAlbum *ablum = [[MTPhotoAlbum alloc] initWithALAssetsGroup:group];
                if ([[group valueForProperty:ALAssetsGroupPropertyType] intValue] == ALAssetsGroupSavedPhotos) {
                    [groups insertObject:ablum atIndex:0];
                    [albumIDGroups insertObject:ablum.localIdentifier atIndex:0];
                }
                else if ([[group valueForProperty:ALAssetsGroupPropertyType] intValue] == ALAssetsGroupLibrary) {
                    [groups insertObject:ablum atIndex:1];
                    [albumIDGroups insertObject:ablum.localIdentifier atIndex:1];
                }
                else {
                    [groups addObject:ablum];
                    [albumIDGroups addObject:ablum.localIdentifier];
                }
            }
            if (group == nil) {
                self.photoAlbums = groups;
                self.photoAlbumIDs = albumIDGroups;
            }
        } failureBlock:^(NSError *error) {
        
        }];
    }
}

- (void)registerChangeObserver:(id<MTPhotoLibraryChangeObserver>)observer
{
    [self.changeObservers addObject:observer];
}

- (void)unregisterChangeObserver:(id<MTPhotoLibraryChangeObserver>)observer
{
    [self.changeObservers removeObject:observer];
}

- (void)createAlbum:(NSString *)title resultBlock:(MTPhotoManagerResultBlock)resultBlock
{
    void (^notifyResult)(BOOL success, NSError *error) = ^(BOOL success, NSError *error) {
        if (resultBlock) {
            resultBlock(success, error);
        }
    };
    
    [_assetsLibrary addAssetsGroupAlbumWithName:title resultBlock:^(ALAssetsGroup *group) {
        notifyResult(nil != group, nil);
    } failureBlock:^(NSError *error) {
        notifyResult(NO, error);
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
    
    NSMutableArray *groups = [NSMutableArray array];
    [_assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
        
        if (nil == group) {
            [groups enumerateObjectsUsingBlock:^(ALAssetsGroup *group, NSUInteger idx, BOOL *stop) {
                if (enumerationBlock) {
                    MTPhotoAlbum *photoAlbum = [[MTPhotoAlbum alloc] initWithALAssetsGroup:group];
                    enumerationBlock(photoAlbum, stop);
                }
            }];
            
            notifyResult(YES, nil);
            return;
        }
        
        // 只获取图片
        [group setAssetsFilter:[ALAssetsFilter allPhotos]];
        // 系统相册默认加在第一个
        if ([[group valueForProperty:ALAssetsGroupPropertyType] intValue] == ALAssetsGroupSavedPhotos) {
            [groups insertObject:group atIndex:0];
        }
        else if ([[group valueForProperty:ALAssetsGroupPropertyType] intValue] == ALAssetsGroupLibrary) {
            [groups insertObject:group atIndex:1];
        }
        else {
            [groups addObject:group];
        }
    } failureBlock:^(NSError *error) {
        notifyResult(NO, error);
    }];
}

- (void)addAsset:(MTPhotoAsset *)asset toAlbum:(MTPhotoAlbum *)photoAlbum resultBlock:(MTPhotoManagerResultBlock)resultBlock
{
    BOOL hasAdded = [[photoAlbum assetsGroup] addAsset:[asset asALAsset]];
    if (resultBlock) {
        resultBlock(hasAdded, nil);
    }
}

enum {
    kAMASSET_PENDINGDELETE = 1,
    kAMASSET_ALLFINISHED = 0
};

- (void)deleteAssets:(NSArray *)assets resultBlock:(MTPhotoManagerResultBlock)resultBlock
{
    NSMutableArray *deleteAssets = [NSMutableArray array];
    for (MTPhotoAsset *asset in assets) {
        @autoreleasepool {
            [deleteAssets addObject:[asset asALAsset]];
        }
    }
    if (0 == deleteAssets.count) {
        if (resultBlock) {
            resultBlock(YES, nil);
        }
        return;
    }
    
    __block BOOL isAllDeleted = YES;
    for (ALAsset *alAsset in deleteAssets) {
        if (!alAsset.editable) {
            isAllDeleted = NO;
            continue;
        }
        @autoreleasepool {
            NSConditionLock* assetDeleteLock = [[NSConditionLock alloc] initWithCondition:kAMASSET_PENDINGDELETE];
            [alAsset setImageData:nil metadata:nil completionBlock:^(NSURL *assetURL, NSError *error) {
                [assetDeleteLock lock];
                [assetDeleteLock unlockWithCondition:kAMASSET_ALLFINISHED];
                
                isAllDeleted &= (nil != assetURL);
            }];
            [assetDeleteLock lockWhenCondition:kAMASSET_ALLFINISHED];
            [assetDeleteLock unlock];
            assetDeleteLock = nil;
        }
    }
    
    if (resultBlock) {
        resultBlock(isAllDeleted, nil);
    }
}

- (void)deleteAlbums:(NSArray *)albums resultBlock:(MTPhotoManagerResultBlock)resultBlock
{
    if (resultBlock) {
        resultBlock(NO, nil);
    }
}

- (void)writeImageToSavedPhotosAlbum:(UIImage *)image resultBlock:(MTPhotoManagerWriteImageResultBlock)resultBlock
{
    NSData *imageData = UIImageJPEGRepresentation(image, 1.0);
    [self writeImageDataToSavedPhotosAlbum:imageData metadata:nil resultBlock:resultBlock];
}

- (void)writeImage:(UIImage *)image toAlbum:(MTPhotoAlbum *)photoAlbum resultBlock:(MTPhotoManagerWriteImageResultBlock)resultBlock
{
    NSData *imageData = UIImageJPEGRepresentation(image, 1.0);
    [self writeImageData:imageData metadata:nil toAlbum:photoAlbum resultBlock:resultBlock];
}

- (void)writeImageDataToSavedPhotosAlbum:(NSData *)imageData metadata:(NSDictionary *)metadata resultBlock:(MTPhotoManagerWriteImageResultBlock)resultBlock
{
    [_assetsLibrary writeImageDataToSavedPhotosAlbum:imageData metadata:metadata completionBlock:^(NSURL *assetURL, NSError *error) {
        if (resultBlock) {
//            MTPhotoAlbum *ablum = self.photoAlbums[0];
//            [ablum reloadALAssets];
//            MTPhotoAsset *asset = [ablum assetAtIndex:ablum.numberOfAssets - 1];
            
            NSString *assetURLString = [assetURL absoluteString];
            MTPhotoAsset *asset = [MTPhotoAsset fetchAssetWithLocalIdentifier:assetURLString];
            resultBlock(nil != assetURL, error,asset);
        }
    }];
}

- (void)writeImageData:(NSData *)imageData metadata:(NSDictionary *)metadata toAlbum:(MTPhotoAlbum *)photoAlbum resultBlock:(MTPhotoManagerWriteImageResultBlock)resultBlock
{
    void (^notifyResult)(BOOL success, NSError *error, NSURL *assetURL) = ^(BOOL success, NSError *error, NSURL *assetURL) {
        
//        MTPhotoAlbum *ablum = self.photoAlbums[0];
//        [ablum reloadALAssets];
//        MTPhotoAsset *asset = [ablum assetAtIndex:ablum.numberOfAssets - 1];
//        resultBlock(success, error,asset);
        
        NSString *assetURLString = [assetURL absoluteString];
        MTPhotoAsset *asset = [MTPhotoAsset fetchAssetWithLocalIdentifier:assetURLString];
        resultBlock(nil != assetURL, error, asset);
    };
    
    [_assetsLibrary writeImageDataToSavedPhotosAlbum:imageData metadata:metadata completionBlock:^(NSURL *assetURL, NSError *error) {
        if (nil == assetURL) {
            notifyResult(NO, error, assetURL);
            return;
        }
        [_assetsLibrary assetForURL:assetURL resultBlock:^(ALAsset *asset) {
            if (nil == asset) {
                notifyResult(NO, error, assetURL);
                return;
            }
            BOOL success = [[photoAlbum assetsGroup] addAsset:asset];
            notifyResult(success, nil, assetURL);
        } failureBlock:^(NSError *error) {
            notifyResult(NO, error, assetURL);
        }];
    }];
}

- (void)writeVideoAtPathToSavedPhotosAlbum:(NSString *)filePath resultBlock:(MTPhotoManagerResultBlock)resultBlock
{
    [_assetsLibrary writeVideoAtPathToSavedPhotosAlbum:[NSURL fileURLWithPath:filePath] completionBlock:^(NSURL *assetURL, NSError *error) {
        if (resultBlock) {
            resultBlock(nil != assetURL, error);
        }
    }];
}

- (void)writeVideoAtURLToSavedPhotosAlbum:(NSURL *)fileURL completeBlock:(MTPhotoManagerAssetsChangedBlock)completeBlock
{
    [_assetsLibrary writeVideoAtPathToSavedPhotosAlbum:fileURL completionBlock:^(NSURL *assetURL, NSError *error) {
        if (completeBlock) {
            NSArray *changedLocalIdentifiers = nil;
            if (assetURL && assetURL.absoluteString) {
                changedLocalIdentifiers = @[assetURL.absoluteString];
            }
            
            completeBlock(nil != assetURL, changedLocalIdentifiers, error);
        }
    }];
    
}



// 将App沙盒目录下的Image保存到相册
- (void)writeImageAtURLToSavedPhotosAlbum:(NSURL *)fileURL completeBlock:(MTPhotoManagerAssetsChangedBlock)completeBlock
{
    @autoreleasepool {
        UIImage *image = [[UIImage alloc] initWithContentsOfFile:fileURL.path];
        
        [_assetsLibrary writeImageToSavedPhotosAlbum:image.CGImage orientation:(ALAssetOrientation)image.imageOrientation completionBlock:^(NSURL *assetURL, NSError *error) {
            if (completeBlock) {
                NSArray *changedLocalIdentifiers = nil;
                if (assetURL && assetURL.absoluteString) {
                    changedLocalIdentifiers = @[assetURL.absoluteString];
                }
                
                completeBlock(nil != assetURL, changedLocalIdentifiers, error);
            }
        }];
        image = nil;
    }
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


- (void)assetsLibraryDidChange:(NSNotification *)note
{
    if (note.userInfo.count) {
        [self updatePhotoAlbumsWith:note];
    }
    
    if (note.userInfo && note.userInfo.count && ![self.lastNotificationUserInfo isEqual:note.userInfo]) {
        self.lastNotificationUserInfo = note.userInfo;
        for (id<MTPhotoLibraryChangeObserver> changeObserver in self.changeObservers) {
            if ([changeObserver conformsToProtocol:@protocol(MTPhotoLibraryChangeObserver)]) {
                [changeObserver assetsLibraryDidChange:note];
            }
        }
    }

}

- (void)clearCached
{
    [self.changeObservers removeAllObjects];
}

/**
 *  根据设置的fetchOption返回ALAssetsFilter对应的过滤规则
 *
 *  @return
 */
- (ALAssetsFilter *)assetFilter
{
    switch (self.fetchOption) {
        case MTPhotoAlbumsFetchOptionAll:
            _assetFilter = [ALAssetsFilter allAssets];
            break;
        case MTPhotoAlbumsFetchOptionVideos:
            _assetFilter = [ALAssetsFilter allVideos];
            break;
        case MTPhotoAlbumsFetchOptionPhotos:
        default:
            _assetFilter = [ALAssetsFilter allPhotos];
            break;
    }
    return _assetFilter;
}



- (NSMutableArray *)photoAlbums
{
    if (_photoAlbums.count == 0 || _bUpdateAlbums) {
        [self updatePhotoAlbumsWith:nil];
        _bUpdateAlbums = NO;
    }
    return _photoAlbums;
}

- (NSMutableArray *)photoAlbumsWithFetchOption:(MTPhotoAlbumsFetchOption)fetchOption {
    
    if (fetchOption != self.fetchOption || _bUpdateAlbums || _photoAlbums.count == 0) {
        self.fetchOption = fetchOption;
        [self updatePhotoAlbumsWith:nil];
        _bUpdateAlbums = NO;
    }
    return self.photoAlbums;
}


#pragma mark - PhotoAlbum API -bugfix 1.0.2
- (void)fetchPhotoAlbumsWith:(void(^)(NSMutableArray *photoAlbums))completionBlock
{
    if (_photoAlbums.count == 0 || _bUpdateAlbums) {
        [self updatePhotoAlbumsWithCompletionBlock:completionBlock];
        _bUpdateAlbums = NO;
    }
    else
    {
        if (completionBlock) {
            completionBlock(_photoAlbums);
        }
    }
}

- (void)fetchPhotoAlbumsWith:(MTPhotoAlbumsFetchOption)fetchOption completionBlock:(void(^)(NSMutableArray *photoAlbums))completionBlock
{
    if (fetchOption != self.fetchOption || _bUpdateAlbums || _photoAlbums.count == 0) {
        self.fetchOption = fetchOption;
        [self updatePhotoAlbumsWithCompletionBlock:completionBlock];
        _bUpdateAlbums = NO;
    }
//    else
//    {
//        if (completionBlock) {
//            completionBlock(_photoAlbums);
//        }
//    }
    
    if (completionBlock) {
        completionBlock(self.photoAlbums);
    }
}


- (void)updatePhotoAlbumsWithCompletionBlock:(void(^)(NSMutableArray *photAlbums))completionBlock
{
    NSMutableArray *groups = [NSMutableArray array];
    NSMutableArray *albumIDGroups = [NSMutableArray array];
    [_assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
        // 根据fetchOption确定获取的资源类型
        [group setAssetsFilter:[self assetFilter]];
        // 系统相册默认加在第一个
//        [_assetsGroup valueForProperty:ALAssetsGroupPropertyName]
//        NSLog(@"系统 :%d, 相册名字 %@",group.numberOfAssets, [group valueForProperty:ALAssetsGroupPropertyName]);
        if (group) {
            MTPhotoAlbum *ablum = [[MTPhotoAlbum alloc] initWithALAssetsGroup:group];
            if ([[group valueForProperty:ALAssetsGroupPropertyType] intValue] == ALAssetsGroupSavedPhotos) {
                [groups insertObject:ablum atIndex:0];
                [albumIDGroups insertObject:ablum.localIdentifier atIndex:0];
            }
            else if ([[group valueForProperty:ALAssetsGroupPropertyType] intValue] == ALAssetsGroupLibrary) {
                [groups insertObject:ablum atIndex:1];
                [albumIDGroups insertObject:ablum.localIdentifier atIndex:1];
            }
            else {
                [groups addObject:ablum];
                [albumIDGroups addObject:ablum.localIdentifier];
            }
        }
        if (group == nil) {
            self.photoAlbums = groups;
            self.photoAlbumIDs = albumIDGroups;
            if (completionBlock) {
                completionBlock(_photoAlbums);
            }
        }
    } failureBlock:^(NSError *error) {
        if (completionBlock) {
            completionBlock(_photoAlbums);
        }
    }];
}

-(void)fetchRecentPhotoAsset:(void (^)(MTPhotoAsset *))completionBlock {
    
    __weak typeof(self) weakSelf = self;
    //查找所有相册的缩略图
    __block MTPhotoAlbum *album = nil;
    
    [weakSelf fetchPhotoAlbumsWith:^(NSMutableArray *photoAlbums) {
        
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (photoAlbums.count > 0) {
            
            self.photoAlbums = photoAlbums;
            
            for (MTPhotoAlbum *tempAlbum in photoAlbums) {
             
                if (tempAlbum.numberOfAssets > 0) {
                    album = tempAlbum;
                    break;
                }
            }
            [album reloadALAssets];
            MTPhotoAsset *photoAsset = [strongSelf fetchRecentPhotoAssetAtFirstAlbum:album];
            completionBlock(photoAsset);
            return;
        }
        
        completionBlock(nil);
    }];
    
    if (!self.photoAlbums || _bUpdateAlbums) {
        
    }

}

- (MTPhotoAsset *)fetchRecentPhotoAssetAtFirstAlbum:(MTPhotoAlbum *)album {
    
    if (album.asALAssets.count > 0) {
        
        ALAsset *asset = [album.asALAssets lastObject];
        MTPhotoAsset *photoAsset = [MTPhotoAsset photoAssetWithALAsset:asset];
        return photoAsset;
    }
    return nil;
}
@end
