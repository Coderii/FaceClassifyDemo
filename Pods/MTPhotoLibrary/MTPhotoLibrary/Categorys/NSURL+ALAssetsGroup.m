//
//  NSURL+ALAssetsGroup.m
//  MTImagePickerControllerDemo
//
//  Created by ph on 15/9/30.
//  Copyright © 2015年 Meitu. All rights reserved.
//

#import "NSURL+ALAssetsGroup.h"

@implementation NSURL (ALAssetsGroup)
- (NSString *)photolibrary_assetsGroupID
{
    NSString *urlString = [self absoluteString];
    NSArray *stringArray = [urlString componentsSeparatedByString:@"&"];
    NSString *tmpString = stringArray[0];
    return [tmpString componentsSeparatedByString:@"="][1];
}
@end
