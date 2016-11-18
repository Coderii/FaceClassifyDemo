//
//  MTPhotoAlbum.h
//  MTImagePickerControllerDemo
//
//  Created by ph on 15/9/6.
//  Copyright © 2015年 Meitu. All rights reserved.
//

#import <Photos/Photos.h>
#import <Foundation/Foundation.h>
#import <AssetsLibrary/AssetsLibrary.h>

@class MTPhotoAlbum;
@class MTPhotoAsset;

typedef void (^MTPhotoManagerResultBlock)(BOOL success, NSError *error);
typedef void (^MTPhotoManagerCheckBlock)(MTPhotoAlbum *album, NSError *error);
typedef void (^MTPhotoManagerAlbumEnumerationBlock)(MTPhotoAlbum *album, BOOL *stop);
typedef void (^MTPhotoManagerAssetEnumerationBlock)(MTPhotoAsset *asset, NSUInteger index, BOOL *stop);
typedef void (^MTPhotoAlbumAssetResultBlock)(MTPhotoAsset *asset, NSUInteger index);
typedef void (^MTPhotoManagerWriteImageResultBlock)(BOOL success, NSError *error, MTPhotoAsset *asset);

typedef void (^MTPhotoManagerAssetsChangedBlock)(BOOL success, NSArray<NSString *> *changedLocalIdentifiers, NSError *error);

/**
 *  相册信息
 */
@interface MTPhotoAlbum : NSObject

#pragma mark - common property
@property (nonatomic, readonly, copy) NSString *title;                  //相册的名字
@property (nonatomic, readonly, copy) NSString *localIdentifier;        //相册的唯一id
@property (nonatomic, readonly, assign) NSInteger numberOfAssets;       //相册里面含有的相片数量
@property (nonatomic, readonly, strong) UIImage *posterImage;           //相册的缩略图
@property (nonatomic, readonly, assign) NSInteger estimatedAssetCount;  //估算的相片数量


#pragma mark - API For AssetsLibrary (IOS 7)
@property (nonatomic, strong) ALAssetsGroup *assetsGroup;               //当前相册
@property(nonatomic, strong,readonly) NSMutableArray *asALAssets;       //相册照片
/**
 *  基于AssetsLibrary初始化接口  IOS7 使用接口
 *
 *  @param assetsGroup ALAssetsGroup
 *
 *  @return
 */
- (instancetype)initWithALAssetsGroup:(ALAssetsGroup *)assetsGroup;



#pragma mark - API For Photos (IOS 8 Later)
@property (nonatomic, strong) PHAssetCollection *assetCollection;       //当前相册
@property (nonatomic, strong) PHFetchResult *fetchResult;               //获取到的资源集合
@property (nonatomic, strong, readonly) NSArray *asPHAssets;            //相册照片
#pragma mark - API For Photos.framework
/**
 *  基于Photos初始化接口  IOS8之后 使用接口
 *
 *  @param assetCollection
 *  @param fetchResult
 *
 *  @return
 */
- (instancetype)initWithPHAssetCollection:(PHAssetCollection *)assetCollection assetFecthResult:(PHFetchResult *)fetchResult;

/**
 *  更新相册的 assetCollection 和 fetchResult
 *
 *  @param assetCollection
 *  @param fetchResult
 */
- (void)updatePHAssetCollection:(PHAssetCollection *)assetCollection assetFecthResult:(PHFetchResult *)fetchResult;


/**
 *  相册变更处理
 *
 *  @param changeInstance 相册变更时返回的PHChange对象
 *
 *  @return
 */
- (PHFetchResultChangeDetails *)changeDetailsFromPHChange:(PHChange *)changeInstance;


#pragma mark - API For Asset
/**
 *  获取相册中下标位置的Asset
 *
 *  @param index
 *
 *  @return
 */
- (MTPhotoAsset *)assetAtIndex:(NSUInteger)index;

/**
 *  获取照片(或视频)的asset在相册中的下标，
 *
 *  @param asset 指定的照片(或视频)的asset
 *
 *  @return  asset在相册中的位置，如果不在返回NSNotFound
 */
- (NSInteger)indexOfAsset:(MTPhotoAsset *)asset;


- (void)reloadALAssets;

/**
 *  重新加载相册中的所有ALAsset对象
 *
 *  @param completionBlock 加载完成的回调块
 */
- (void)reloadALAssetsWith:(void(^)(NSMutableArray<ALAsset *> *asALAssets))completionBlock;

/*
*  获取相册中所有的Asset的localIdentifier
*
*  @return
*/
- (NSArray<NSString *> *)photoAssetLocalIdentifiers;


/**
 *  新增接口判断两个相册是否相等
 *
 *  @param object 相册对象
 */
- (BOOL)isEqualWithAblum:(id)object;

@end
