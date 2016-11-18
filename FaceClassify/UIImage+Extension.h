//
//  UIImage+Extension.h
//  Graduationdesign
//
//  Created by chengpeng on 16-2-26.
//  Copyright (c) 2016年 chengpeng. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (Extension)

/**
*  根据图片名自动加载适配iOS6\7的图片
*
*  @param name 图片名
*
*  @return 改变后的图片
*/
+ (UIImage *)imageWithName:(NSString *)name;

/**
 *  根据图片名返回一张能够自由拉伸的图片
 *
 *  @param name 图片名 
 *
 *  @return 改变后的图片
 */
+ (UIImage *)resizedImage:(NSString *)name;

/**
 *  改变图像的尺寸，方便上传服务器
 *
 *  @param image 图片
 *  @param size  尺寸
 *
 *  @return 改变后的图片
 */
+ (UIImage *)scaleFromImage: (UIImage *)image toSize:(CGSize)size;

/**
 *  保持原来的长宽比，生成一个缩略图
 *
 *  @param image 图片
 *  @param asize 尺寸
 *
 *  @return 生成的缩略图
 */
+ (UIImage *)thumbnailWithImageWithoutScale:(UIImage *)image size:(CGSize)asize;

/**
 *  根据坐标值和宽高，裁剪图片
 *
 *  @param superImage   原图
 *  @param subImageSize 需要裁剪的Size
 *  @param subImageRect 需要裁剪的Rect
 *
 *  @return 裁剪后的图片
 */
+ (UIImage *)getImageFromImage:(UIImage*) superImage subImageSize:(CGSize)subImageSize subImageRect:(CGRect)subImageRect;
@end
