//
//  MTGetManager.h
//  FaceClassify
//
//  Created by meitu on 16/6/16.
//  Copyright © 2016年 meitu. All rights reserved.
//

#import <Foundation/Foundation.h>
@class RLMResults;

@interface MTGetManager : NSObject

/**
 *  根据数据库搜索结果，发送普通文件的GET请求
 *
 *  @param rlmResults 数据库搜索结果
 *  @param progress   GET进度
 *  @param completion GET完成的Block
 *  @param failure    GET失败的Block
 */
- (void)GETJpgDataWithRLMResults:(RLMResults *)rlmResults
                        progress:(void(^)(float progress))progress
                      completion:(void(^)(NSArray *getArray))completion
                         failure:(void(^)(NSError *error))failure;

@end
