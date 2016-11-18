//
//  MTItemModel.h
//  FaceClassify
//
//  Created by meitu on 16/6/12.
//  Copyright © 2016年 meitu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@interface MTItemModel : NSObject

@property (nonatomic, assign) NSNumber *faceIndex;
@property (nonatomic, copy) NSString *imageName;

/**
 *  根据传入的Dict初始化model
 *
 *  @param dict 字典数据
 *
 *  @return MTItemModel
 */
- (instancetype)initItemModelWithDict:(NSDictionary *)dict;

/**
 *  类方法初始化model
 *
 *  @param dict 字典数据
 *
 *  @return MTItemModel
 */
+ (instancetype)itemModelWithDict:(NSDictionary *)dict;

- (UIImage *)thumbImage;
@end
