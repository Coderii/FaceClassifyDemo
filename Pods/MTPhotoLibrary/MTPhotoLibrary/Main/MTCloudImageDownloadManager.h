//
//  MTCloudImageDownloadManager.h
//  MTImagePickerControllerDemo
//
//  Created by Tang on 15/9/29.
//  Copyright © 2015年 Meitu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MTPhotoAsset.h"
#import "MTImageManager.h"


typedef void(^MTCloudImageDownloadResultHandler)(UIImage *result, NSDictionary *info);
typedef void(^MTCloudVideoDownloadResultHandler)(AVPlayerItem *playerItem, NSDictionary *info);
typedef void(^MTCloudImageDownloadTaskResultHandler)(id result, NSDictionary *info);

@class MTCloudImageDownloadTask;

/**
 *  支持从iCloud单任务队列下载
 */
@interface MTCloudImageDownloadManager : NSObject

@property (nonatomic, strong) MTCloudImageDownloadTask *currentTask;
@property (nonatomic, strong) NSMutableArray *waitingTaskList;
@property (nonatomic, assign) float currentDownloadProgress;

+ (instancetype)defaultManager;


#pragma mark 队列操作

- (void)addImageDownloadTaskForAsset:(MTPhotoAsset *)asset
                     progressHandler:(void (^)(float))progressHandler
                       resultHandler:(MTCloudImageDownloadResultHandler)resultHandler;

- (void)addVideoDownloadTaskForAsset:(MTPhotoAsset *)asset
                     progressHandler:(void (^)(float))progressHandler
                       resultHandler:(MTCloudVideoDownloadResultHandler)resultHandler;

- (void)removeDownloadTaskForAsset:(MTPhotoAsset *)asset
                        completion:(void(^)())completion;

- (void)removeAllDownloadTasks;


#pragma mark 任务执行

- (void)executeTaskIfAny;

#pragma mark Helper

- (MTCloudImageDownloadTask *)taskForAsset:(MTPhotoAsset *)asset;

@end


#pragma mark - MTCloudImageDownloadTask

@interface MTCloudImageDownloadTask : NSObject

#pragma mark common

@property (nonatomic, strong) MTPhotoAsset *asset;
@property (nonatomic, assign) MTImageRequestID requestID;
@property (nonatomic, copy) void(^progressHandler)(float progress);
@property (nonatomic, copy) MTCloudImageDownloadTaskResultHandler completionHandler;
#pragma mark image

- (instancetype)initWithImageAsset:(MTPhotoAsset *)asset
                   progressHandler:(void(^)(float))progressHandler
                     resultHandler:(MTCloudImageDownloadResultHandler)resultHandler;

#pragma mark video

- (instancetype)initWithVideoAsset:(MTPhotoAsset *)asset
                   progressHandler:(void (^)(float))progressHandler
                     resultHandler:(MTCloudVideoDownloadResultHandler)resultHandler;

@end
