//
//  MTUploadManager.m
//  FaceClassify
//
//  Created by meitu on 16/6/14.
//  Copyright © 2016年 meitu. All rights reserved.
//

#import "MTUploadManager.h"

#import "AFNetworking.h"
#import "MTFileManager.h"
#import "SSZipArchive.h"
#import "MTImageModel.h"
#import "MTCommonData.h"

/** post 请求的服务器地址 */
#define inPostUploadURL @"http://192.168.43.236:1050/recognition_upload"
#define outPostUploadURL @"http://222.76.241.154:53270/recognition_upload"

#define inPostUploadMergeUrl @"http://192.168.43.236:1050/recognition_merge"
#define outPostUploadMergeUrl @"http://222.76.241.154:53270/recognition_merge"

#define inPostUploadModifyUrl @"http://192.168.43.236:1050/recognition_modify"
#define outPostUploadModifyUrl @"http://222.76.241.154:53270/recognition_modify"

@interface MTUploadManager()

/** POST请求返回的数据信息数组 */
@property (nonatomic, strong) NSMutableArray *responseArray;

@end

@implementation MTUploadManager

#warning 注意函数体和逻辑结构
- (void)POSTJpgProgress:(void (^)(float))progress
             completion:(void (^)(NSArray *))completion
                failure:(void (^)(NSError *))failure {
    static NSUInteger uploadFlag = 0;

    MTFileManager *fileMgr = [[MTFileManager alloc] init];
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    [manager.requestSerializer willChangeValueForKey:@"timeoutInterval"];
    manager.requestSerializer.timeoutInterval = MAXFLOAT;
    [manager.requestSerializer didChangeValueForKey:@"timeoutInterval"];
    
    //单文件上传
    NSString *imagePath = [fileMgr getDirectoryPathWithDirectoryName:tempOriginImagePathName];
    
    //获取文件
    NSArray *images = [[NSFileManager defaultManager] subpathsOfDirectoryAtPath:imagePath error:nil];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *sessionID = [userDefaults objectForKey:@"sessionID"];
    
    NSString *firstURL = [NSString string];
    if ([sessionID isEqualToString:@"None"]) {
        //第一次上传,考虑第一次多张
        NSLog(@"first upload");
        if ([userDefaults boolForKey:@"outOrInNetWorking"]) {
            firstURL = [NSString stringWithFormat:@"%@/%@", inPostUploadURL, @"None"];
        }
        else {
            firstURL = [NSString stringWithFormat:@"%@/%@", outPostUploadURL, @"None"];
        }
    }
    else {
        NSLog(@"not first upload");
        //非第一次上传
        if ([userDefaults boolForKey:@"outOrInNetWorking"]) {
            firstURL = [NSString stringWithFormat:@"%@/%@", inPostUploadURL, sessionID];
        }
        else {
            firstURL = [NSString stringWithFormat:@"%@/%@", outPostUploadURL, sessionID];
        }
    }

    if (uploadFlag == 0) {  //第一次上传
        NSLog(@"第一张上传 sessionid = %@", [userDefaults objectForKey:@"sessionID"]);
        NSString *firstImgName = [images firstObject];
        
        __block NSError *error = nil;
        [manager POST:firstURL parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
            [formData appendPartWithFileURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@", @"file://",
                                                                  [imagePath stringByAppendingPathComponent:firstImgName]]]
                                       name:@"filename"
                                   fileName:firstImgName
                                   mimeType:@"image/jpeg" error:&error];
        } progress:^(NSProgress * _Nonnull uploadProgress) {
        } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            NSLog(@"1___sessionID = %@", sessionID);
            NSDictionary * resultDic = [NSDictionary dictionary];
            if (responseObject) {
                resultDic = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingMutableLeaves error:nil];
                
                //将图片名称和返回的dict对应起来
                [self.responseArray addObject:@{@"responseDict": resultDic,
                                                @"imageName" : firstImgName}];
                
                //写入sessionid
                [userDefaults setObject:resultDic[@"SessionId"] forKey:@"sessionID"];
                [userDefaults synchronize];
                
                //第一张上传成功
                uploadFlag++;
                
                //第一张之后请求
                if (images.count == 1) {    //只有一张的话，就不需要重新请求
                    if (uploadFlag == images.count) {
                        if (completion) {
                            completion(self.responseArray);
                            self.responseArray = nil;
                            uploadFlag = 0;
                        }
                    }
                }
                else {
                    //重新请求
                    [self POSTJpgProgress:progress completion:completion failure:failure];
                }
            }
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            if (failure) {
                failure(error);
            }
        }];
    }
    else {
        NSLog(@"非第一张上传 sessionid = %@", [userDefaults objectForKey:@"sessionID"]);
        for (int i = 1; i < images.count; i++) {
            NSString *imgName = images[i];
            
            __block NSError *error = nil;
            [manager POST:firstURL parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
                [formData appendPartWithFileURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@", @"file://",
                                                                      [imagePath stringByAppendingPathComponent:imgName]]]
                                           name:@"filename"
                                       fileName:imgName
                                       mimeType:@"image/jpeg" error:&error];
            } progress:^(NSProgress * _Nonnull uploadProgress) {
            } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                NSDictionary * resultDic = [NSDictionary dictionary];
                if (responseObject) {
                    resultDic = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingMutableLeaves error:nil];
                    
                    //将图片名称和返回的dict对应起来
                    [self.responseArray addObject:@{@"responseDict": resultDic,
                                                    @"imageName" : imgName}];
                    
                    //第一张上传成功
                    uploadFlag++;
                }
                
                if (uploadFlag == images.count) {
                    if (completion) {
                        completion(self.responseArray);
                        self.responseArray = nil;
                        uploadFlag = 0;
                    }
                }
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                if (failure) {
                    failure(error);
                }
            }];
        }
    }
}

- (void)POSTUniteInfo:(NSArray *)info
           completion:(void (^)(NSArray *))completion
              failure:(void (^)(NSError *))failure {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *sessionID = [userDefaults objectForKey:@"sessionID"];
    
    NSString *uniteUrl = [NSString string];
    if ([userDefaults boolForKey:@"outOrInNetWorking"]) {
        uniteUrl = [NSString stringWithFormat:@"%@/%@", inPostUploadMergeUrl, sessionID];
    }
    else {
        uniteUrl = [NSString stringWithFormat:@"%@/%@", outPostUploadMergeUrl, sessionID];
    }
    
    NSData *infoData = [NSJSONSerialization dataWithJSONObject:@{@"mergeLabelList": info}
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:nil];
    
    
    //字典装换为JSON数据格式
    NSString *jsonStr = [[NSString alloc] initWithData:infoData encoding:NSUTF8StringEncoding];
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];

    [manager POST:uniteUrl parameters:jsonStr progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (responseObject) {
            [self.responseArray addObject:responseObject];
            if (completion) {
                completion(self.responseArray);
            }
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (failure) {
            failure(error);
        }
    }];
}

- (void)POSTMoveInfo:(NSDictionary *)info
          completion:(void (^)(NSArray *))completion
             failure:(void (^)(NSError *))failure {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *sessionID = [userDefaults objectForKey:@"sessionID"];
    
    NSString *moveUrl;
    if ([userDefaults boolForKey:@"outOrInNetWorking"]) {
        moveUrl = [NSString stringWithFormat:@"%@/%@", inPostUploadModifyUrl, sessionID];
    }
    else {
        moveUrl = [NSString stringWithFormat:@"%@/%@", outPostUploadModifyUrl, sessionID];
    }
    NSData *infoData = [NSJSONSerialization dataWithJSONObject:info
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:nil];
    
    
    //字典装换为JSON数据格式
    NSString *jsonStr = [[NSString alloc] initWithData:infoData encoding:NSUTF8StringEncoding];
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer = [AFJSONResponseSerializer serializerWithReadingOptions:NSJSONReadingAllowFragments];
    [manager POST:moveUrl parameters:jsonStr progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (responseObject) {
            [self.responseArray addObject:responseObject];
            if (completion) {
                completion(self.responseArray);
            }
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (failure) {
            failure(error);
        }
    }];
}

- (NSMutableArray *)responseArray {
    if(!_responseArray) {
        _responseArray = [NSMutableArray array];
    }
    return _responseArray;
}
@end
