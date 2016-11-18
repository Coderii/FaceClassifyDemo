//
//  MTFileManager.m
//  FaceClassify
//
//  Created by meitu on 16/6/13.
//  Copyright © 2016年 meitu. All rights reserved.
//

#import "MTFileManager.h"

#import "UIImage+Extension.h"
#import "MTAssetModel.h"
#import "SSZipArchive.h"
#import "MTCommonData.h"

//在这里修改缩放的基准值
#define STANDRD 800
#define MTWriteFileErrorDomain @"meitu.writefile.FaceClassify"
#define MTZipFileErrorDomain @"meitu.zipfile.FaceClassify"
#define MTUNZipFileErrorDomain @"meitu.unzipfile.FaceClassify"
#define MT_EPSION 0.0000001

typedef NS_ENUM(NSInteger, MTWriteFileErrorFailed) {
    MTWriteFileErrorFailedDefault = 0,  /**< 其他错误  */
    MTWriteFileErrorFailedInStorage = 1,    /**< 内存不足  */
    MTWriteFileErrorFailedFileError = 2,    /**< 文件错误  */
};

typedef NS_ENUM(NSInteger, MTZipFileErrorFailed) {
    MTZipFileErrorFailedDefault = 0,  /**< 其他错误  */
    MTZipFileErrorFailedInStorage = 1,    /**< 内存不足  */
    MTZipFileErrorFailedFileError = 2,    /**< 文件错误  */
};

typedef NS_ENUM(NSInteger, MTUNZipFileErrorFailed) {
    MTUNZipFileErrorFailedDefault = 0,  /**< 其他错误  */
    MTUNZipFileErrorFailedInStorage = 1,    /**< 内存不足  */
    MTUNZipFileErrorFailedFileError = 2,    /**< 文件错误  */
};

@implementation MTFileManager

static MTFileManager *_instance = nil;
static NSUInteger imageFlag = 0;

#pragma mark Life cycle

+ (instancetype)sharedSingleton {
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[self alloc] init];
    });
    return _instance;
}

#pragma mark Class methdos
- (void)createDirectoryAtDocumentDirectory {
    [self createDocumentWithPathsName:@[originImagePathName,
                                        thumbnailPathName,
                                        tempOriginImagePathName,
                                        tempThumbnailPathName,
                                        resultPathName,
                                        zipPathName,
                                        zipTempPathName,
                                        ]];
}

// 创建目录
- (void)createDocumentWithPathsName:(NSArray *)array {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    for (NSString *pathName in array) {
        NSString *path = [documentsDirectory stringByAppendingPathComponent:pathName];
        
        if (![fileManager fileExistsAtPath:path]) {
            [fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
        }
    }
}

// 获取目录名
- (NSString *)pathCreateWithName:(NSString *)name {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    return [documentsDirectory stringByAppendingPathComponent:name];
}

// 删除Document目录下的所有文件
- (void)removeItemAtDocumentDirectory {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSString *resultPath = [self getDirectoryPathWithDirectoryName:resultPathName];
    NSString *faceClassifyPath = [self getDirectoryPathWithDirectoryName:faceClassifyPathName];
    
    [fileManager removeItemAtPath:resultPath error:nil];
    [fileManager removeItemAtPath:faceClassifyPath error:nil];
    
    //清除所有数据后再添加空的目录
    [self createDirectoryAtDocumentDirectory];
    
    //创建classify.plist
    NSString* strSave = [NSString stringWithFormat:@"%@/../classify.plist", [self getDirectoryPathWithDirectoryName:resultPathName]];
    [[[NSMutableArray alloc] init] writeToFile:strSave atomically:YES];
}

// 清除temp目录
- (void)clearTempDirectory {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    [fileManager removeItemAtPath:[self pathCreateWithName:tempOriginImagePathName] error:nil];
    [fileManager removeItemAtPath:[self pathCreateWithName:tempThumbnailPathName] error:nil];

    [self createDocumentWithPathsName:@[tempOriginImagePathName,
                                       tempThumbnailPathName,
                                        ]];
}

// 根据目录名获取目录路径
- (NSString *)getDirectoryPathWithDirectoryName:(NSString *)directoryName {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    NSString *createPath = [documentsDirectory stringByAppendingPathComponent:directoryName];
    return createPath;
}

//写入数据到本地文件中
- (void)writeImageDataToFileWithModel:(MTAssetModel *)model
                                image:(UIImage *)image
                             progress:(void(^)(float progress))progress
                           completion:(void(^)())completion
                              failure:(void(^)(NSError *error))failure{
    NSLog(@"写文件");
    //获取图片
    NSString *imageName = model.fileName;
    NSString *name = [imageName stringByDeletingPathExtension];
    NSString *lastname = [imageName pathExtension];
    
    
    //按比例裁剪
    CGFloat width = image.size.width;
    CGFloat height = image.size.height;
    
    CGFloat newW;
    CGFloat newH;
    
    if (width > height) {
        newW = STANDRD;
        newH = (STANDRD * image.size.height) / image.size.width;
    }
    else {
        newH = STANDRD;
        newW = (STANDRD * image.size.width) / image.size.height;
    }
    
    //图片裁剪
    UIImage *uploadImage = [UIImage scaleFromImage:image toSize:CGSizeMake(newW, newH)];
    UIImage *thumbnailImage = [UIImage thumbnailWithImageWithoutScale:image size:CGSizeMake(300, 300)];
    
    //临时目录
    NSString *imagePath = [[self getDirectoryPathWithDirectoryName:tempOriginImagePathName]
                           stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.%@", name, lastname]];
    
    NSString *thumbnailPath = [[self getDirectoryPathWithDirectoryName:tempThumbnailPathName]
                               stringByAppendingPathComponent:[NSString stringWithFormat:@"%@_%@.%@", name, @"thumbnail", lastname]];
    
    //写入文件
    BOOL writeImage = [UIImageJPEGRepresentation(uploadImage, 1.0) writeToFile:imagePath atomically:YES];
    BOOL writeThumbnailImage = [UIImageJPEGRepresentation(thumbnailImage, 1.0) writeToFile:thumbnailPath atomically:YES];
    
    //写入成功
    imageFlag++;
    
    float writeProgress = imageFlag * 1.0 / self.writeFilesCount;
    
    //写入进度Block
    if (progress) {
        progress(writeProgress);
    }
    
    if (writeImage && writeThumbnailImage) {
        if (fabsf(writeProgress - 1) < MT_EPSION) {
            if (completion) {
                completion();
                imageFlag = 0;
            }
        }
    }
    else {
        NSError *error = [self errorWithObj:@"writefile is a error" domain:MTWriteFileErrorDomain code:MTWriteFileErrorFailedDefault];
        if (failure) {
            failure(error);
        }
    }
}

- (void)moveItemAtTempDirectoryCompletion:(void(^)())completion failure:(void(^)(NSError *error))failure {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSArray *tempOriginImages = [fileManager contentsOfDirectoryAtPath:[self pathCreateWithName:tempOriginImagePathName] error:nil];
    NSArray *tempThumbnailImages = [fileManager contentsOfDirectoryAtPath:[self pathCreateWithName:tempThumbnailPathName] error:nil];
    
    //temp目录中的原图和缩略图数量
    NSUInteger tempOriginImagesCount = tempOriginImages.count;
    NSUInteger tempThumbnailImagesCount = tempThumbnailImages.count;
    
    NSString *originSourceFile = [NSString string];
    NSString *originDestFile = [NSString string];
    NSString *thumbnailSourceFile = [NSString string];
    NSString *thumbnailDestFile = [NSString string];
    
    NSError *error;
    //移动原图
    for (NSString *temoOriginImage in tempOriginImages) {
        originSourceFile = [[self pathCreateWithName:tempOriginImagePathName] stringByAppendingPathComponent:temoOriginImage];
        originDestFile = [[self pathCreateWithName:originImagePathName] stringByAppendingPathComponent:temoOriginImage];
        
        // 如果存在先删除在移动
        if ([fileManager fileExistsAtPath:originDestFile]) {
            [fileManager removeItemAtPath:originDestFile error:nil];
        }
        
        if([fileManager moveItemAtPath:originSourceFile toPath:originDestFile error:&error]) {
            //如果移动成功
            tempOriginImagesCount--;
        }
    }
    
    //移动缩略图
    for (NSString *temoThumbnailImage in tempThumbnailImages) {
        thumbnailSourceFile = [[self pathCreateWithName:tempThumbnailPathName] stringByAppendingPathComponent:temoThumbnailImage];
        thumbnailDestFile = [[self pathCreateWithName:thumbnailPathName] stringByAppendingPathComponent:temoThumbnailImage];
        
        
        if ([fileManager fileExistsAtPath:thumbnailDestFile]) {
            [fileManager removeItemAtPath:thumbnailDestFile error:nil];
        }
        
        if ([fileManager moveItemAtPath:thumbnailSourceFile toPath:thumbnailDestFile error:&error]) {
            tempThumbnailImagesCount--;
        }
    }
    
    //处理回调
    if ((tempOriginImagesCount == 0) && (tempThumbnailImagesCount == 0)) {
        if (completion) {
            completion();
        }
    }
    else {
        error = [self errorWithObj:@"copyfile is a error" domain:MTWriteFileErrorDomain code:MTWriteFileErrorFailedDefault];
        if (failure) {
            failure(error);
        }
    }
}

- (void)zipFileCompletion:(void(^)())completion failure:(void(^)(NSError *error))failure {
    NSString *zipPath = [[self pathCreateWithName:zipPathName] stringByAppendingPathComponent:uploadZipName];
    if ([SSZipArchive createZipFileAtPath:zipPath withContentsOfDirectory:[self pathCreateWithName:tempOriginImagePathName]]) {
        if (completion) {
            completion();
        }
    }
    else {
        NSError *error = [self errorWithObj:@"zipfile is a error" domain:MTZipFileErrorDomain code:MTZipFileErrorFailedDefault];
        if (failure) {
            failure(error);
        }
    }
}

- (void)unzipFilecompletion:(void (^)())completion failure:(void (^)(NSError *))failure {
    //解压
    NSString *zipPath = [[self pathCreateWithName:zipPathName] stringByAppendingPathComponent:uploadZipName];
    NSString *destinationPath = [self pathCreateWithName:zipTempPathName];
    if ([SSZipArchive unzipFileAtPath:zipPath toDestination:destinationPath]) {
        NSLog(@"解压成功");
        if (completion) {
            completion();
        }
    }
    else {
        NSError *error = [self errorWithObj:@"unzipfile is a error" domain:MTUNZipFileErrorDomain code:MTUNZipFileErrorFailedDefault];
        if (failure) {
            failure(error);
        }
    }
}

// 创建error信息
- (NSError *)errorWithObj:(id)obj domain:(NSString *)domain code:(NSInteger)code {
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:obj forKey:NSLocalizedDescriptionKey];
    NSError *error = [NSError errorWithDomain:domain code:code userInfo:userInfo];
    return error;
}
@end
