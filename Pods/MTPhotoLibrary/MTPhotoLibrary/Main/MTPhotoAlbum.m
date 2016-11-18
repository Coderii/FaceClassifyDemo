//
//  MTPhotoAlbum.m
//  MTImagePickerControllerDemo
//
//  Created by ph on 15/9/6.
//  Copyright © 2015年 Meitu. All rights reserved.
//

#import "MTPhotoAlbum.h"
#import "MTPhotoAsset.h"
#import "MTPhotoLibrary_Prefix.h"

@interface MTPhotoAlbum ()
{
    ALAssetsGroup *_assetsGroup;
    PHAssetCollection *_assetCollection;
    PHFetchResult     *_fetchResult;
    
    PHChange *_changeInstance;
    PHFetchResultChangeDetails *_fetchResultChangeDetails;
}
@property(nonatomic, strong) NSMutableArray *asALAssets;
@end

@implementation MTPhotoAlbum

- (void)dealloc
{
    
}

- (instancetype)initWithALAssetsGroup:(ALAssetsGroup *)assetsGroup
{
    self = [super init];
    if (self) {
        _assetsGroup = assetsGroup;
    }
    return self;
}

- (void)updateALAssetsGroup:(ALAssetsGroup *)assetsGroup
{
    self.assetsGroup = assetsGroup;
}


- (instancetype)initWithPHAssetCollection:(PHAssetCollection *)assetCollection assetFecthResult:(PHFetchResult *)fetchResult
{
    self = [super init];
    if (self) {
        _assetCollection = assetCollection;
        _fetchResult = fetchResult;
    }
    return self;
}

- (void)updatePHAssetCollection:(PHAssetCollection *)assetCollection assetFecthResult:(PHFetchResult *)fetchResult
{
    self.assetCollection = assetCollection;
    self.fetchResult = fetchResult;
}


//- (BOOL)isEqual:(id)object
//{
//    if ([object isKindOfClass:[MTPhotoAlbum class]]) {
//        MTPhotoAlbum *photoAlbum = object;
//        if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO_8_0) {
//            return [[self assetCollection] isEqual:[photoAlbum assetCollection]];
//        }
//        else {
//            return [self.localIdentifier isEqualToString:photoAlbum.localIdentifier];
//        }
//    }
//    return NO;
//}


- (BOOL)isEqualWithAblum:(id)object
{
    if ([object isKindOfClass:[MTPhotoAlbum class]]) {
        MTPhotoAlbum *photoAlbum = object;
        if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO_8_0) {
            return [[self assetCollection] isEqual:[photoAlbum assetCollection]];
        }
        else {
            return [self.localIdentifier isEqualToString:photoAlbum.localIdentifier];
        }
    }
    return NO;
}

- (NSInteger)numberOfAssets
{
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO_8_0) {
        return _fetchResult.count;
    }
    else {
        return _assetsGroup.numberOfAssets;
    }
}

- (NSInteger)estimatedAssetCount
{
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO_8_0) {
        return _assetCollection.estimatedAssetCount;
    }
    else
    {
        return _assetsGroup.numberOfAssets;
    }
}


- (UIImage *)posterImage
{
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO_8_0) {
        if (_fetchResult.count == 0) {
            return nil;
        }
        PHAsset *asset =  [_fetchResult objectAtIndex:_fetchResult.count-1];
        MTPhotoAsset *photoAsset = [MTPhotoAsset photoAssetWithPHAsset:asset];
        return photoAsset.thumbnail;
    }
    else {
        return[UIImage imageWithCGImage:_assetsGroup.posterImage];
    }
}
- (NSString *)title
{
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO_8_0) {
        return _assetCollection.localizedTitle;
    }
    else {
        return [_assetsGroup valueForProperty:ALAssetsGroupPropertyName];
    }
}

- (NSString *)localIdentifier
{
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO_8_0) {
        return _assetCollection.localIdentifier;
    }
    else {
        return [_assetsGroup valueForProperty:ALAssetsGroupPropertyPersistentID];
    }
}


- (PHFetchResultChangeDetails *)changeDetailsFromPHChange:(PHChange *)changeInstance
{
    if (_changeInstance != changeInstance) {
        _changeInstance = changeInstance;
        _fetchResultChangeDetails = [changeInstance changeDetailsForFetchResult:self.fetchResult];
    }
    return _fetchResultChangeDetails;
}


#pragma mark - API For Asset
- (MTPhotoAsset *)assetAtIndex:(NSUInteger)index
{
    if (self.fetchResult) {
        if (index < self.fetchResult.count) {
            PHAsset *asset = self.fetchResult[index];
            return [MTPhotoAsset photoAssetWithPHAsset:asset];
        }
        else
        {
            return nil;
        }
    }
    else if (self.assetsGroup)
    {
        MTPhotoAsset *photoAsset = [MTPhotoAsset photoAssetWithALAsset:[self.asALAssets objectAtIndex:index]];
        return photoAsset;
    }
    else
    {
        return nil;
    }
}

- (NSInteger)indexOfAsset:(MTPhotoAsset *)asset {
    if (self.fetchResult) {
        return [self.fetchResult indexOfObject:[asset asPHAsset]];
    } else if (self.assetsGroup) {
        __block NSInteger tempIndex = NSNotFound;
        [self.assetsGroup enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
            if ([[result valueForProperty:ALAssetPropertyAssetURL] isEqual:[asset.asALAsset valueForProperty:ALAssetPropertyAssetURL]]) {
                *stop = YES;
                tempIndex = index;
            }
        }];
        return tempIndex;
    } else {
        return NSNotFound;
    }
}

- (id)valueForProperty:(NSString *)property
{
    return [self.assetsGroup valueForProperty:property];
}


- (NSArray *)asPHAssets
{
    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, self.numberOfAssets)];
    return [self.fetchResult objectsAtIndexes:indexSet];
}

- (void)reloadALAssets
{
    [self reloadALAssetsWith:nil];
}


- (void)reloadALAssetsWith:(void(^)(NSMutableArray<ALAsset *> *asALAssets))completionBlock
{
    NSMutableArray *asALAssets = [NSMutableArray arrayWithCapacity:0];
    [self.assetsGroup enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
        if (result == nil) {
            *stop = YES;
            self.asALAssets = asALAssets;
            if (completionBlock) {
                completionBlock(asALAssets);
            }
        }
        else
        {
            [asALAssets addObject:result];
        }
    }];
}

- (NSArray<NSString *> *)photoAssetLocalIdentifiers
{
    NSMutableArray *photoAssetLocalIdentifiers = [[NSMutableArray alloc] initWithCapacity:0];
    
    if (self.fetchResult) {
        for(PHAsset *asset in self.asPHAssets) {
            [photoAssetLocalIdentifiers addObject:asset.localIdentifier];
        }
    }
    else if (self.assetsGroup)
    {
        [self reloadALAssets];
        for (ALAsset *asset in self.asALAssets) {
            [photoAssetLocalIdentifiers addObject:[[asset valueForProperty:ALAssetPropertyAssetURL] absoluteString]];
        }
    }
    else {
        NSLog(@"error not data");
    }
    return photoAssetLocalIdentifiers;
}

@end
