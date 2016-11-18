//
//  MTGetManager.m
//  FaceClassify
//
//  Created by meitu on 16/6/16.
//  Copyright © 2016年 meitu. All rights reserved.
//

#import "MTGetManager.h"

#import "AFNetworking.h"
#import <Realm/Realm.h>
#import "MTImageModel.h"

#define outGetURL @"http://222.76.241.154:53270/recognition_cluster/"
#define inGetURL @"http://192.168.43.236:1050/recognition_cluster/"

@interface MTGetManager()

@property (nonatomic, strong) NSMutableArray *getResponseArray;

@end

@implementation MTGetManager

- (void)GETJpgDataWithRLMResults:(RLMResults *)rlmResults
                        progress:(void (^)(float))progress
                      completion:(void (^)(NSArray *))completion
                         failure:(void (^)(NSError *))failure {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *sessionID = [userDefaults objectForKey:@"sessionID"];
    
    //唯一的sessionid进行get请求
    NSString *getUrl = [NSString string];
    if ([userDefaults boolForKey:@"outOrInNetWorking"]) {
        // 内网
        getUrl = inGetURL;
        NSLog(@"inGetURL");
    }
    else {
        // 外网
        getUrl = outGetURL;
        NSLog(@"outGetURL");
    }

    NSString *newUrl = [NSString stringWithFormat:@"%@%@", getUrl, sessionID];
    AFHTTPSessionManager *httpMrg = [AFHTTPSessionManager manager];
    httpMrg.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    [httpMrg.requestSerializer willChangeValueForKey:@"timeoutInterval"];
    httpMrg.requestSerializer.timeoutInterval = MAXFLOAT;
    [httpMrg.requestSerializer didChangeValueForKey:@"timeoutInterval"];
    
    [httpMrg GET:newUrl parameters:nil progress:^(NSProgress * _Nonnull downloadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (responseObject) {
            NSDictionary * resultDic = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingMutableLeaves error:nil];
            NSLog(@"resultdict = %@", resultDic);
            
            NSNumber *resultCode = resultDic[@"ErrorCode"];
            if ([resultCode intValue] != 0) {
                //重复请求
                NSLog(@"重复请求！");
                [self GETJpgDataWithRLMResults:rlmResults progress:progress completion:completion failure:failure];
            }
            else {
                [self.getResponseArray addObject:resultDic];
                //block传值
                if (completion) {
                    completion(self.getResponseArray);
                    self.getResponseArray = nil;
                }
            }
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"失败%@",error);
        if (failure) {
            failure(error);
        }
    }]; 
}
- (NSMutableArray *)getResponseArray {
    if (!_getResponseArray) {
        _getResponseArray = [NSMutableArray array];
    }
    return _getResponseArray;
}

@end
