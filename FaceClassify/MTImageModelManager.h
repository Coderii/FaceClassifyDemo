//
//  MTImageModelManager.h
//  FaceClassify
//
//  Created by meitu on 16/6/16.
//  Copyright © 2016年 meitu. All rights reserved.
//

#import <Foundation/Foundation.h>

//定义MTImageModelManager用于管理数据库模型
@interface MTImageModelManager : NSObject

/**
 *  单例
 *
 *  @return MTImageModelManager
 */
+ (instancetype)sharedSingleton;

/**
 *  写入数据到数据库中
 *
 *  @param responseArray 根据POST返回的数据数组
 */
- (void)writeDataToRealmWithResponseArray:(NSArray *)responseArray;

/**
 *  写入压缩包数据到数据库中
 *
 *  @param responseDict 根据POST返回的数据数组
 */
- (void)writeZipDataToRealmWithResponseDict:(NSDictionary *)responseDict;

/**
 *  更新数据库中的单文件数据
 *
 *  @param getArray 根据GET返回的数据数组
 */
- (void)updateJpgDataWithGetArray:(NSArray *)getArray completion:(void(^)())completion;

/**
 *  更新数据库中的压缩包中的数据
 *
 *  @param getArray 根据GET返回的数据数组
 */
- (void)updateZipDataWithGetArray:(NSArray *)getArray;

/**
 *  清除数据库
 */
- (void)clearRealmAllData;

@end
