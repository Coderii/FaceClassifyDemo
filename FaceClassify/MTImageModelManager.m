//
//  MTImageModelManager.m
//  FaceClassify
//
//  Created by meitu on 16/6/16.
//  Copyright © 2016年 meitu. All rights reserved.
//

#import "MTImageModelManager.h"
#import <Realm/Realm.h>
#import "MTImageModel.h"
#import "MTFileManager.h"
#import "MTCommonData.h"

@interface MTImageModelManager()

@property (nonatomic, strong) RLMRealm *defaultRealm;

@end

@implementation MTImageModelManager

static MTImageModelManager *_instance = nil;

#pragma mark - Singleton

+ (instancetype)sharedSingleton {
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[self alloc] init];
        _instance.defaultRealm = [RLMRealm defaultRealm];
    });
    return _instance;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    //只进行一次
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [super allocWithZone:zone];
    });
    return _instance;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    return  _instance;
}

+ (instancetype)copyWithZone:(struct _NSZone *)zone {
    return  _instance;
}

+ (instancetype)mutableCopyWithZone:(struct _NSZone *)zone {
    return _instance;
}

- (instancetype)mutableCopyWithZone:(NSZone *)zone {
    return _instance;
}

#pragma mark - Class methods
- (void)writeDataToRealmWithResponseArray:(NSArray *)responseArray {
    
    //存储数据库
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    
    RLMResults *results = [MTImageModel allObjects];
    
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSLog(@"---%@", [userDefaults objectForKey:@"sessionID"]);
    
    for (NSDictionary *dict in responseArray) {
        MTImageModel *imageModel = [self imageModelWithName:dict[@"imageName"]];
        
        NSString *name = [dict[@"imageName"] stringByDeletingPathExtension];
        NSString *lastname = [dict[@"imageName"] pathExtension];
        
        imageModel.sessionId = dict[@"responseDict"][@"SessionId"];
    
        imageModel.imagePath = [originImagePathName
                                stringByAppendingPathComponent:dict[@"imageName"]];
        
        imageModel.thumbnailPath = [thumbnailPathName
                                    stringByAppendingPathComponent:[NSString stringWithFormat:@"%@_%@.%@",
                                                                    name,
                                                                    @"thumbnail",
                                                                    lastname]];
        imageModel.boxesFeatures = [NSData data];
        imageModel.imageSet_id = dict[@"imageName"];
        imageModel.zipPath = @"";
        imageModel.zipStatus = NO;
        imageModel.getMark = NO;
        imageModel.faceCount = 0;

        BOOL exitName = NO;
        for (MTImageModel *model in results) {
            if ([dict[@"imageName"] isEqualToString:model.imageName]) {
                //存在则更新
                exitName = YES;
                break;
            }
            else {
                //不存在则增加
                exitName = NO;
            }
        }
        
        if (!exitName) {
            [MTImageModel createInRealm:realm withObject:imageModel];
        }
        else {
            [MTImageModel createOrUpdateInRealm:realm withObject:imageModel];
        }
    }
    [realm commitWriteTransaction];
}


- (void)writeZipDataToRealmWithResponseDict:(NSDictionary *)responseDict {
    MTImageModel *imageModel = [[MTImageModel alloc] init];
    
    //存储数据库
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    
    imageModel.sessionId = responseDict[@"SessionId"];
    imageModel.imageName = @"";
    imageModel.imagePath = @"";
    imageModel.thumbnailPath = @"";
    imageModel.boxesFeatures = [NSData data];
    imageModel.imageSet_id = @"";
    imageModel.zipPath = zipPathName;
    imageModel.zipStatus = YES;
    imageModel.getMark = NO;
    imageModel.faceCount = 0;
    
    [MTImageModel createInRealm:realm withObject:imageModel];
    [realm commitWriteTransaction];
}

- (MTImageModel *)imageModelWithName:(NSString *)imageName {
    RLMResults *results = [MTImageModel objectsWhere:@"imageName = %@", imageName];
    
    MTImageModel *imageModel = [results firstObject];
    
    if (!imageModel) {
        imageModel = [[MTImageModel alloc] init];
        imageModel.imageName = imageName;
    }
    
    return imageModel;
}

- (void)updateJpgDataWithGetArray:(NSArray *)getArray completion:(void (^)())completion {
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    
    for (NSDictionary *getDict in getArray) {
        NSArray *imageSetArr = getDict[@"ImageSet"];
        
        for (NSDictionary *faceSetDict in imageSetArr) {
            NSArray *faceSetArr = faceSetDict[@"FaceSet"];
            
            NSString *imageName = faceSetDict[@"ImageSet_id"];
            MTImageModel *imageModel = [self imageModelWithName:imageName];
            imageModel.sessionId = getDict[@"SessionId"];
            imageModel.getMark = YES;
            
            NSString *name = [faceSetDict[@"imageName"] stringByDeletingPathExtension];
            NSString *lastname = [faceSetDict[@"imageName"] pathExtension];
            imageModel.imagePath = [originImagePathName
                                    stringByAppendingPathComponent:faceSetDict[@"imageName"]];
            
            imageModel.thumbnailPath = [thumbnailPathName
                                        stringByAppendingPathComponent:[NSString stringWithFormat:@"%@_%@.%@",
                                                                        name,
                                                                        @"thumbnail",
                                                                        lastname]];
            imageModel.imageSet_id = faceSetDict[@"imageName"];
            
            //人脸个数
            imageModel.faceCount = (int)faceSetArr.count;
            
            NSMutableArray *detailArr = [NSMutableArray array];
            
            NSDictionary *dict = [NSDictionary dictionary];
            
            for (NSDictionary *faceDict in faceSetArr) {
                //保存详细的分类信息
                dict = @{@"label": faceDict[@"Label"],
                         @"core": faceDict[@"Core"]};
                
                [detailArr addObject:@[faceDict[@"Boxes"], faceDict[@"Features"], dict]];
                imageModel.boxesFeatures = [NSKeyedArchiver archivedDataWithRootObject:detailArr];
                
                [MTImageModel createOrUpdateInRealm:realm withObject:imageModel];
            }
        }
    }
    
    if (completion) {
        completion();
    }
    
    [realm commitWriteTransaction];
}

- (void)updateZipDataWithGetArray:(NSArray *)getArray { 
    static NSUInteger ssesion_id_flag;
    NSDictionary *getDict = [getArray firstObject];
    NSArray *imageSet = getDict[@"ImageSet"];
    
    MTImageModel *imageModel = [[MTImageModel alloc] init];
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    
    for (NSDictionary *eachDict in imageSet) {
        ssesion_id_flag++;
        imageModel.sessionId = [NSString stringWithFormat:@"%@_%ld", getDict[@"SessionId"], ssesion_id_flag];
        imageModel.getMark = YES;
        
        imageModel.zipPath = @"";
        imageModel.imageSet_id = eachDict[@"ImageSet_id"];
        imageModel.imageName = eachDict[@"ImageSet_id"];
        imageModel.imagePath = [originImagePathName stringByAppendingPathComponent:eachDict[@"ImageSet_id"]];
        
        NSString *name = [eachDict[@"ImageSet_id"] stringByDeletingPathExtension];
        NSString *lastname = [eachDict[@"ImageSet_id"] pathExtension];
        imageModel.thumbnailPath = [faceClassifyPathName
                                    stringByAppendingPathComponent:[NSString stringWithFormat:@"%@_%@.%@",
                                                                    name,
                                                                    @"thumbnail", 
                                                                    lastname]];
        
        NSArray *faceSetArr = eachDict[@"FaceSet"];
        imageModel.faceCount = (int)faceSetArr.count;
        
        NSMutableArray *detailArr = [NSMutableArray array];
        
        for (NSDictionary *faceDict in faceSetArr) {
            //保存详细的分类信息
            [detailArr addObject:@[faceDict[@"Boxes"], faceDict[@"Features"]]];
        }
        imageModel.boxesFeatures = [NSKeyedArchiver archivedDataWithRootObject:detailArr];
        [MTImageModel createOrUpdateInRealm:realm withObject:imageModel];
    }
    
    [realm commitWriteTransaction];
}

- (void)clearRealmAllData {
    //清空数据库
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    [realm deleteAllObjects];
    [realm commitWriteTransaction];
}
@end
