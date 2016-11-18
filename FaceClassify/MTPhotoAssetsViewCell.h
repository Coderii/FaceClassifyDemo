//
//  MTPhotoAssetsViewCell.h
//  MTPhotoLibrary
//
//  Created by JoyChiang on 15/6/20.
//  Copyright (c) 2015年 Meitu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MTPhotoAsset.h"
#import "MTImageManager.h"

typedef void (^DownloadCompeletionHandler)(id result,NSDictionary *info);

static CGSize const kAssetThumbnailSize = {160.f , 160.f};
static CGSize const kAssetThumbnailMiniSize = {80.f , 80.f};

@interface MTPhotoAssetsViewCell : UICollectionViewCell

@property (nonatomic, strong, readonly) UIImageView *imageView;
@property (nonatomic, strong) UILabel *imageStatusLabel;

@property (nonatomic, assign) MTImageRequestID requestID;
@property (nonatomic, weak) MTImageManager *imageManager;

@property (nonatomic, strong) MTPhotoAsset *photoAsset;

// 从iCloud下载资源
- (void)downloadAssetWithCompletion;

- (void)downloadAssetWithCompletion:(DownloadCompeletionHandler)completionBlock;

- (void)cancelDownload;

- (void)showDownloadStatus;

@end
