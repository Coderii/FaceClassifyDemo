//
//  MTItemModel.m
//  FaceClassify
//
//  Created by meitu on 16/6/12.
//  Copyright © 2016年 meitu. All rights reserved.
//

#import "MTItemModel.h"
#import "MTFileManager.h"
#import "MTCommonData.h"

@implementation MTItemModel

- (instancetype)initItemModelWithDict:(NSDictionary *)dict {
    if (self = [super init]) {
        [self setValuesForKeysWithDictionary:dict];
    }
    return self;
}

+ (instancetype)itemModelWithDict:(NSDictionary *)dict {
    return [[self alloc] initItemModelWithDict:dict];
}

- (UIImage *)thumbImage {
    NSString *pathDocuments = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    
    NSString *thumbPathName = thumbnailPathName;
    NSString *thumbPath = [NSString stringWithFormat:@"%@/%@_%@.%@",
                            thumbPathName,
                            [self.imageName stringByDeletingPathExtension],
                            @"thumbnail",
                            @"JPG"];
    
    NSString *thumbImageFilePath = [pathDocuments stringByAppendingPathComponent:thumbPath];
    return [[UIImage alloc] initWithContentsOfFile:thumbImageFilePath];
}

@end
