//
//  MTPhotoAsset.h
//  MTPhotoLibrary
//
//  Created by JoyChiang on 15/6/20.
//  Copyright (c) 2015年 Meitu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Photos/Photos.h>
#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <MobileCoreServices/MobileCoreServices.h>

typedef NS_ENUM(NSInteger, MTPhotoAssetMediaType) {
    MTPhotoAssetMediaTypeUnknown = 0,
    MTPhotoAssetMediaTypeImage   = 1,
    MTPhotoAssetMediaTypeVideo   = 2,
    MTPhotoAssetMediaTypeAudio   = 3,
};

/**
 *  图片对象
 */
@interface MTPhotoAsset : NSObject

@property (nonatomic, readonly, assign) MTPhotoAssetMediaType mediaType;

@property (nonatomic, readonly, assign) CGSize dimensions;
@property (nonatomic, readonly, strong) NSDictionary *metadata;
@property (nonatomic, readonly, strong) NSDate *creationDate;
@property (nonatomic, readonly, strong) NSURL *assetURL;
@property (nonatomic, readonly, copy) NSString *localIdentifier;

@property (nonatomic, readonly, strong) UIImage *thumbnail;

// Image Property
@property (nonatomic, readonly, assign) UIImageOrientation orientation;

@property (nonatomic, readonly, strong) UIImage *fullScreenImage;
@property (nonatomic, readonly, strong) UIImage *fullResolutionImage;


// Video Property
@property (nonatomic, readonly, assign) NSTimeInterval duration;

// File Name
@property (nonatomic, readonly, copy) NSString *fileName;


/**
 *  iOS7使用,初始化
 *
 *  @param asset 传入的ALAsset对象
 *
 *  @return MTPHotoAsset对象
 */
+ (MTPhotoAsset *)photoAssetWithALAsset:(ALAsset *)asset;
- (ALAsset *)asALAsset;



/**
 *  iOS8使用,初始化
 *
 *  @param asset 传入的PHAsset对象
 *
 *  @return MTPhotoAsset对象
 */
+ (MTPhotoAsset *)photoAssetWithPHAsset:(PHAsset *)asset;
- (PHAsset *)asPHAsset;

/**
 *  针对iOS7 maxLength才有效，返回图片最大边长不超过maxLength; iOS 8 与fullResolutionImage无差异
 *
 *  @param maxLength 限制图片最大边长，用于解决iOS图片太大，选图闪退
 *
 *  @return
 */
- (UIImage *)fullResolutionImageWithMaxLength:(CGFloat)maxLength;


#pragma mark -  针对fullResolutionImageWithMaxLength的修正接口
/**
 *  返回图片最大边长不超过maxLength; （与fullResolutionImageWithMaxLength相比修正了IOS8之后maxLength无效问题）
 *
 *  @param maxLength maxLength 限制图片最大边长，用于解决iOS图片太大，选图闪退
 *
 *  @return
 */
- (UIImage *)fix_fullResolutionImageWithMaxLength:(CGFloat)maxLength;


/**
 *  判断当前相册与目标相册是否一致
 *
 *  @param photoAsset 目标相册
 *
 *  @return 
 */
- (BOOL)isEqualToAsset:(MTPhotoAsset *)photoAsset;

/**
 *  获取图像的专用数据类型
 *
 *  @param completion
 */
- (void)fetchAssetMIMEType:(void(^)(NSString *MIMEType))completion;

/*
 For Image: use rawData
 For Video: create NSFileHandle with rawDataURL
 */
+ (void)fetchAsset:(MTPhotoAsset *)asset
           rawData:(void(^)(NSData *rawData, NSURL *rawDataURL, ALAssetRepresentation *assetRepresentation))result;

- (void)requestJudgeIsAssetInCloud:(void(^)(BOOL flag))handler;

- (void)cancelRequestJudgeIsAssetInCloud;

- (unsigned long long)fileSize;

- (CLLocation *)location;

- (NSString *)fileNameExtension;

#pragma mark - 更具asset的identifier获取MTPhotoAsset的类方法

/**
 *  获取identifier对应的MTPhotoAsset
 *
 *  @param identifier 某个MTPhotoAsset的唯一标示
 *
 *  @return 返回相册中identifier对应的MTPhotoAsset，可能为空
 */
+ (MTPhotoAsset *)fetchAssetWithLocalIdentifier:(NSString *)identifier;

/**
 *  获取identifiers对应的MTPhotoAssets
 *
 *  @param identifiers 一组MTPhotoAsset的唯一标示数组
 *
 *  @return 返回相册中identifiers对应的MTPhotoAssets，可能为空
 */
+ (NSArray<MTPhotoAsset *> *)fetchAssetsWithLocalIdentifiers:(NSArray *)identifiers;

@end
