//
//  MTUploadManager.h
//  FaceClassify
//
//  Created by meitu on 16/6/14.
//  Copyright © 2016年 meitu. All rights reserved.
//

#import <Foundation/Foundation.h>

//文件上传管理器
@interface MTUploadManager : NSObject

/**
 *  上传普通文件
 *
 *  @param progress   上传进度
 *  @param completion 上传成功的Block
 *  @param failure    上传失败的Block
 */
- (void)POSTJpgProgress:(void(^)(float progress))progress
             completion:(void(^)(NSArray *responseArray))completion
                failure:(void(^)(NSError *error))failure;

/**
 *  上传合并信息请求
 *
 *  @param completion 提交合并请求成功
 *  @param failure    提交合并请求失败
 */
- (void)POSTUniteInfo:(NSArray *)info
           completion:(void(^)(NSArray *responseArray))completion
                        failure:(void(^)(NSError *error))failure;

/**
 *  上传移动信息请求
 *
 *  @param info       移动的信息
 *  @param completion 提交移动请求成功
 *  @param failure    提交移动请求失败
 */
- (void)POSTMoveInfo:(NSDictionary *)info
          completion:(void (^)(NSArray *))completion
             failure:(void (^)(NSError *))failure;
@end
