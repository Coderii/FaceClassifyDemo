//
//  MTCloudImageDownloadManager.m
//  MTImagePickerControllerDemo
//
//  Created by Tang on 15/9/29.
//  Copyright © 2015年 Meitu. All rights reserved.
//

#import "MTCloudImageDownloadManager.h"

static MTCloudImageDownloadManager *defaultManager = nil;

@interface MTCloudImageDownloadManager () {
    MTCloudImageDownloadTask *_currentTask;
    NSMutableArray *_waitingTaskList;
    
    BOOL _isDownloading;
}

@end

@implementation MTCloudImageDownloadManager

+ (instancetype)defaultManager
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        defaultManager = [[MTCloudImageDownloadManager alloc]init];
    });
    return defaultManager;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _waitingTaskList = [NSMutableArray array];
    }
    return self;
}

#pragma mark 队列操作

- (void)addImageDownloadTaskForAsset:(MTPhotoAsset *)asset
                     progressHandler:(void (^)(float))progressHandler
                       resultHandler:(MTCloudImageDownloadResultHandler)resultHandler
{
    if ([self taskForAsset:asset]) {
        return;
    }
    
    MTCloudImageDownloadTask *task = [[MTCloudImageDownloadTask alloc] initWithImageAsset:asset
                                                                          progressHandler:progressHandler
                                                                            resultHandler:resultHandler];
    [_waitingTaskList addObject:task];
    [self executeTaskIfAny];
}

- (void)addVideoDownloadTaskForAsset:(MTPhotoAsset *)asset
                     progressHandler:(void (^)(float))progressHandler
                       resultHandler:(MTCloudVideoDownloadResultHandler)resultHandler
{
    if ([self taskForAsset:asset]) {
        return;
    }
    
    MTCloudImageDownloadTask *task = [[MTCloudImageDownloadTask alloc] initWithVideoAsset:asset
                                                                          progressHandler:progressHandler
                                                                            resultHandler:resultHandler];
    [_waitingTaskList addObject:task];
    [self executeTaskIfAny];
}

- (void)removeDownloadTaskForAsset:(MTPhotoAsset *)asset completion:(void (^)())completion
{
    if ([asset isEqual:_currentTask.asset]) {
        if (_currentTask.requestID > 0) {
            [[PHImageManager defaultManager] cancelImageRequest:_currentTask.requestID];
            _currentTask.requestID = PHInvalidImageRequestID;
        }
        _currentTask = nil;
        
    } else {
        for (MTCloudImageDownloadTask *task in _waitingTaskList) {
            @autoreleasepool {
                if ([asset isEqual:task.asset]) {
                    [_waitingTaskList removeObject:task];
                    break;
                }
            }
        }
    }
    
    if (_currentTask == nil && _waitingTaskList.count > 0) {
        _currentTask = _waitingTaskList[0];
        [_waitingTaskList removeObjectAtIndex:0];
        [self executeTaskIfAny];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        if (completion) {
                completion();
        }
    });
}

- (void)removeAllDownloadTasks
{
    if (_currentTask) {
        if (_currentTask.requestID > 0) {
            [[PHImageManager defaultManager] cancelImageRequest:_currentTask.requestID];
            _currentTask.requestID = PHInvalidImageRequestID;
        }
        _currentTask = nil;
    }
    _waitingTaskList = [NSMutableArray array];
    _isDownloading = NO;
    _currentDownloadProgress = 0;
}

#pragma mark 任务执行

- (void)executeTaskIfAny
{
    if (_isDownloading == YES) {
        return;
    }
    
    if (_currentTask == nil) {
        if (_waitingTaskList.count > 0) {
            _currentTask = _waitingTaskList[0];
            [_waitingTaskList removeObjectAtIndex:0];
        } else {
            _isDownloading = NO;
            return;
        }
    }
    _isDownloading = YES;
    
    if (_currentTask.asset.mediaType == MTPhotoAssetMediaTypeImage && _currentTask.requestID == PHInvalidImageRequestID) {
        PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
        options.progressHandler = ^(double progress, NSError *error, BOOL *stop, NSDictionary *info){
            if (error) {
                _isDownloading = NO;
                _currentDownloadProgress = 0;
                *stop = YES;
            }
            else
            {
                _currentDownloadProgress = progress;
                if (_currentTask.progressHandler) {
                    _currentTask.progressHandler(progress);
                }
            }
        };
        options.networkAccessAllowed = YES;
        options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
        
        _currentTask.requestID = [[PHImageManager defaultManager] requestImageForAsset:[_currentTask.asset asPHAsset]
                                                                            targetSize:PHImageManagerMaximumSize
                                                                           contentMode:PHImageContentModeDefault
                                                                               options:options
                                                                         resultHandler:^(UIImage *result, NSDictionary *info) {
                                                                             _isDownloading = NO;
                                                                             _currentDownloadProgress = 0;
                                                                             if (_currentTask.completionHandler) {
                                                                                 _currentTask.completionHandler(result, info);
                                                                             }
                                                                             _currentTask = nil;
                                                                             [self executeTaskIfAny];
                                                                         }];
    }
    else if (_currentTask.asset.mediaType == MTPhotoAssetMediaTypeVideo && _currentTask.requestID == PHInvalidImageRequestID) {
        PHVideoRequestOptions *options = [[PHVideoRequestOptions alloc] init];
        options.progressHandler = ^(double progress, NSError *error, BOOL *stop, NSDictionary *info){
            if (error) {
                _isDownloading = NO;
                _currentDownloadProgress = 0;
                *stop = YES;
            }
            _currentDownloadProgress = progress;
            if (_currentTask.progressHandler) {
                _currentTask.progressHandler(progress);
            }
        };
        options.networkAccessAllowed = YES;
        options.deliveryMode = PHVideoRequestOptionsDeliveryModeHighQualityFormat;
        
        _currentTask.requestID = [[PHImageManager defaultManager] requestPlayerItemForVideo:[_currentTask.asset asPHAsset]
                                                                                    options:options
                                                                              resultHandler:^(AVPlayerItem *playerItem, NSDictionary *info) {
                                                                                  _isDownloading = NO;
                                                                                  if (_currentTask.completionHandler) {
                                                                                      _currentTask.completionHandler(playerItem, info);
                                                                                  }
                                                                                  _currentDownloadProgress = 0;
                                                                                  _currentTask = nil;
                                                                                  [self executeTaskIfAny];
                                                                              }];
    }
}

#pragma mark Helper

- (MTCloudImageDownloadTask *)taskForAsset:(MTPhotoAsset *)asset
{
    if ([_currentTask.asset.localIdentifier isEqualToString:asset.localIdentifier]) {
        return _currentTask;
    }
    else
    {
        for (MTCloudImageDownloadTask *task in _waitingTaskList) {
            @autoreleasepool {
                if ([task.asset.localIdentifier isEqualToString:asset.localIdentifier]) {
                    return task;
                }
            }
        }
    }
    return nil;
}

@end


#pragma mark - MTCloudImageDownloadTask

@implementation MTCloudImageDownloadTask

- (instancetype)initWithImageAsset:(MTPhotoAsset *)asset
                   progressHandler:(void (^)(float))progressHandler
                     resultHandler:(MTCloudImageDownloadResultHandler)resultHandler
{
    if (self = [super init]) {
        self.asset = asset;
        self.progressHandler = progressHandler;
        self.completionHandler = resultHandler;
    }
    return self;
}

- (instancetype)initWithVideoAsset:(MTPhotoAsset *)asset
                   progressHandler:(void (^)(float))progressHandler
                     resultHandler:(MTCloudVideoDownloadResultHandler)resultHandler
{
    if (self = [super init]) {
        self.asset = asset;
        self.progressHandler = progressHandler;
        self.completionHandler = resultHandler;
    }
    return self;
}

@end
