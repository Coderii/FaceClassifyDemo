//
//  MTFileManager.h
//  FaceClassify
//
//  Created by meitu on 16/6/13.
//  Copyright © 2016年 meitu. All rights reserved.
//
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@class MTAssetModel;

//创建的MTFileManager用于文件夹的一些操作
@interface MTFileManager : NSObject

@property (nonatomic, assign) NSUInteger writeFilesCount;   //写入文件数

/**
 *  单例方法
 *
 *  @return MTFileManager
 */
+ (instancetype)sharedSingleton;

/**
 *  创建所需要的目录
 */
- (void)createDirectoryAtDocumentDirectory;

/**
 *  删除目录下的文件
 */
- (void)removeItemAtDocumentDirectory;

/**
 *  删除Zip/Temp目录
 */
- (void)clearTempDirectory;

/**
 *  根据传入的目录名称获取目录路径
 *
 *  @param directoryName 目录名称
 *
 *  @return 目录所在路径
 */
- (NSString *)getDirectoryPathWithDirectoryName:(NSString *)directoryName;

/**
 *  写入图片数据到本地目录中
 *
 *  @param model      MTAssetModel 模型
 *  @param image      图片
 *  @param progress   写入进度
 *  @param completion 完成Block
 *  @param failure    失败Block
 */
- (void)writeImageDataToFileWithModel:(MTAssetModel *)model
                                image:(UIImage *)image
                             progress:(void(^)(float progress))progress
                           completion:(void(^)())completion
                              failure:(void(^)(NSError *error))failure;

/**
 *  拷贝源目录文件到目标目录中，并且删除源目录文件
 *
 *  @param completion 完成事件Block
 *  @param failure    失败事件Block
 */
- (void)moveItemAtTempDirectoryCompletion:(void(^)())completion
                                  failure:(void(^)(NSError *error))failure;

/**
 *  压缩文件
 *
 *  @param completion 完成事件Block
 *  @param failure    失败事件Block
 */
- (void)zipFileCompletion:(void(^)())completion failure:(void(^)(NSError *error))failure;

/**
 *  解压文件
 *
 *  @param completion 完成事件Block
 *  @param failure    失败事件Block
 */
- (void)unzipFilecompletion:(void(^)())completion failure:(void(^)(NSError *error))failure;
@end
