//
//  MTPhotoAssetsViewCell.m
//  MTPhotoLibrary
//
//  Created by JoyChiang on 15/6/20.
//  Copyright (c) 2015年 Meitu. All rights reserved.
//

#import "MTPhotoAssetsViewCell.h"
#import "MTCloudImageDownloadManager.h"

typedef void (^DownloadProgressHandler)(float progress);

@interface MTPhotoAssetsViewCell ()
// 下载进度回调快
@property (nonatomic, copy) DownloadProgressHandler downloadProgressHandler;
// 下载成功的回调快
@property (nonatomic, copy) MTCloudImageDownloadTaskResultHandler downloadCompeletionHandler;

@end

@implementation MTPhotoAssetsViewCell

- (void)dealloc
{
    _imageView.image = nil;
    _imageView = nil;
    _imageStatusLabel = nil;
}


- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame: frame];
    if (self) {
        _imageView = [[UIImageView alloc] initWithFrame: CGRectMake(0, 0, frame.size.width, frame.size.height)];
        _imageView.center = CGPointMake(frame.size.width * 0.5, frame.size.height * 0.5);
        _imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _imageView.contentMode = UIViewContentModeScaleAspectFill;
        _imageView.clipsToBounds = YES;
        [self.contentView addSubview: _imageView];
        
        _imageStatusLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, 14)];
        _imageStatusLabel.textColor = [UIColor whiteColor];
        _imageStatusLabel.backgroundColor = [UIColor blackColor];
        _imageStatusLabel.textAlignment = NSTextAlignmentCenter;
        _imageStatusLabel.hidden = YES;
        [self.contentView addSubview:_imageStatusLabel];
    }
    return self;
}

- (void)setPhotoAsset:(MTPhotoAsset *)photoAsset
{
    _photoAsset = photoAsset;
    if (_photoAsset) {
        CGFloat screenScale = [UIScreen mainScreen].scale;
        CGSize thumbsize = CGSizeMake(80 * screenScale,80 * screenScale);
        CGFloat sx = thumbsize.width/_photoAsset.dimensions.width;
        CGFloat sy = thumbsize.height/_photoAsset.dimensions.height;
        BOOL isLargeImage = _photoAsset.dimensions.width>5000 || _photoAsset.dimensions.height > 5000;
        BOOL isLongImage = _photoAsset.dimensions.width/_photoAsset.dimensions.height > 5 || _photoAsset.dimensions.height/_photoAsset.dimensions.width > 5;
        if (isLargeImage && isLongImage) {
            sx = 80.0f/_photoAsset.dimensions.width;
            sy = 80.0f/_photoAsset.dimensions.height;
        }
        CGFloat s = MAX(sx, sy);
        CGSize thumbnailSize = CGSizeApplyAffineTransform(_photoAsset.dimensions, CGAffineTransformMakeScale(s, s));
        self.requestID = [self.imageManager requestThumbnailImageForAsset:photoAsset
                                                               targetSize:thumbnailSize
                                                              contentMode:MTImageContentModeAspectFill
                                                            resultHandler:^(UIImage *result, NSDictionary *info) {
                                                                if (nil != result) {
                                                                    self.requestID = PHInvalidImageRequestID;
                                                                    [self.imageView setImage:result];
                                                                }
                                                            }];
        if (_photoAsset.asPHAsset) {
            MTCloudImageDownloadTask *existTask = [[MTCloudImageDownloadManager defaultManager] taskForAsset:_photoAsset];
            if (existTask) {
                existTask.progressHandler = self.downloadProgressHandler;
                existTask.completionHandler = [self downloadCompletionBlock];
            }
            [self showDownloadStatus];
        }
    }
    
}

/**
 *  下载回调块
 *
 *  @return
 */
- (DownloadProgressHandler)downloadProgressHandler
{
    if (!_downloadProgressHandler) {
        __weak typeof(self) weakSelf = self;
        _downloadProgressHandler = ^(float progress) {
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong typeof(weakSelf) strongSelf = weakSelf;
                if (strongSelf) {
                    strongSelf.imageStatusLabel.text = [NSString stringWithFormat:@"%d%%", (int)(progress * 100)];
                }
            });
        };
    }
    return _downloadProgressHandler;
}


- (MTCloudImageDownloadTaskResultHandler)downloadCompletionBlock
{
    if (_downloadCompeletionHandler) {
        return _downloadCompeletionHandler;
    }
    
    if (_photoAsset.mediaType == MTPhotoAssetMediaTypeImage) {
        __weak typeof(self) weakSelf = self;
        _downloadCompeletionHandler = ^(UIImage *image, NSDictionary *info){
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (strongSelf) {
                strongSelf.imageStatusLabel.hidden = YES;
            }
        };
    }
    else if (_photoAsset.mediaType == MTPhotoAssetMediaTypeVideo)
    {
        __weak typeof(self) weakSelf = self;
        _downloadCompeletionHandler = ^(AVPlayerItem *playerItem, NSDictionary *info){
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (strongSelf) {
                strongSelf.imageStatusLabel.hidden = YES;
            }
        };
    }
    else
    {
        __weak typeof(self) weakSelf = self;
        _downloadCompeletionHandler = ^(id result, NSDictionary *info){
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (strongSelf) {
                strongSelf.imageStatusLabel.hidden = YES;
            }
        };
    }
    return _downloadCompeletionHandler;
}


- (void)downloadAssetWithCompletion
{
    if (_photoAsset.mediaType == MTPhotoAssetMediaTypeImage) {
        [[MTCloudImageDownloadManager defaultManager] addImageDownloadTaskForAsset:_photoAsset
                                                                   progressHandler:self.downloadProgressHandler
                                                                     resultHandler:[self downloadCompletionBlock]];
        [self showDownloadStatus];
    }
    else if (_photoAsset.mediaType == MTPhotoAssetMediaTypeVideo) {
        [[MTCloudImageDownloadManager defaultManager] addVideoDownloadTaskForAsset:_photoAsset
                                                                   progressHandler:self.downloadProgressHandler
                                                                     resultHandler:[self downloadCompletionBlock]];
        [self showDownloadStatus];
    }
}

- (void)downloadAssetWithCompletion:(DownloadCompeletionHandler)completionBlock
{
    if (_photoAsset.mediaType == MTPhotoAssetMediaTypeImage) {
        [[MTCloudImageDownloadManager defaultManager] addImageDownloadTaskForAsset:_photoAsset
                                                                   progressHandler:self.downloadProgressHandler
                                                                     resultHandler:^(UIImage *result, NSDictionary *info) {
                                                                         [self downloadCompletionBlock];
                                                                         if (result) {
                                                                             completionBlock(result, info);
                                                                         }
                                                                         
                                                                     }];
        [self showDownloadStatus];
    }
    else if (_photoAsset.mediaType == MTPhotoAssetMediaTypeVideo) {
        [[MTCloudImageDownloadManager defaultManager] addVideoDownloadTaskForAsset:_photoAsset
                                                                   progressHandler:self.downloadProgressHandler
                                                                     resultHandler:^(AVPlayerItem *playerItem, NSDictionary *info) {
                                                                         [self downloadCompletionBlock];
                                                                         if (playerItem) {
                                                                             completionBlock(playerItem, info);
                                                                         }
                                                                     }];
        [self showDownloadStatus];
    }
}


- (void)cancelDownload
{
    [[MTCloudImageDownloadManager defaultManager] removeDownloadTaskForAsset:_photoAsset
                                                                  completion:^{
                                                                      [self showDownloadStatus];
                                                                  }];
}

- (void)showDownloadStatus
{
    MTCloudImageDownloadTask *existTask = [[MTCloudImageDownloadManager defaultManager] taskForAsset:_photoAsset];
    if (existTask) {
        if (existTask == [MTCloudImageDownloadManager defaultManager].currentTask) {
            self.imageStatusLabel.text = [NSString stringWithFormat:@"%d%%", (int)([MTCloudImageDownloadManager defaultManager].currentDownloadProgress * 100)];
            self.imageStatusLabel.hidden = NO;
        }
        else
        {
            self.imageStatusLabel.hidden = NO;
            self.imageStatusLabel.text = @"Waiting";
        }
    }
    else
    {
        self.imageStatusLabel.hidden = YES;
    }
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    
    if (self.requestID != PHInvalidImageRequestID) {
        [self.imageManager cancelImageRequest:self.requestID];
        self.requestID = PHInvalidImageRequestID;
    }
    
    _downloadProgressHandler = nil;
    _downloadCompeletionHandler = nil;
    
    
    self.photoAsset = nil;
    self.imageView.image = nil;
    self.imageStatusLabel.text = @"";
    self.imageStatusLabel.hidden = YES;
}

@end
