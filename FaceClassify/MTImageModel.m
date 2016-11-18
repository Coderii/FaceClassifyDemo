//
//  MTImageModel.m
//  FaceClassify
//
//  Created by meitu on 16/6/8.
//  Copyright © 2016年 meitu. All rights reserved.
//

#import "MTImageModel.h"
#import "MTFileManager.h"

@implementation MTImageModel

/** 生成主键 */
+ (NSString *)primaryKey {
//    return @"sessionId";
    return @"imageName";
}

- (UIImage *)thumbImage {
    NSString *pathDocuments = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *thumbImageFilePath = [pathDocuments stringByAppendingPathComponent:self.thumbnailPath];
    
    return [[UIImage alloc] initWithContentsOfFile:thumbImageFilePath];
}


@end
