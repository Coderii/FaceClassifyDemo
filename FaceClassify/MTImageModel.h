//
//  MTImageModel.h
//  FaceClassify
//
//  Created by meitu on 16/6/8.
//  Copyright © 2016年 meitu. All rights reserved.
//  图片的数据库模型

#import <UIKit/UIKit.h>
#import <Realm/Realm.h>

@interface MTImageModel : RLMObject
#warning 修饰属性呢 代码整理下
@property NSString *sessionId;  /**< 请求的sessionId，唯一标识  */
@property NSString *imageName;  /**< 图片名称  */
@property NSString *imagePath;  /**< 图片的地址  */
@property NSString *thumbnailPath;  /**< 缩略图地址  */  
@property NSData *boxesFeatures;    /**< 人脸位置和256维的列表的组合  */
@property NSString *imageSet_id;    /**< 图片id  */

@property NSString *zipPath;    //zip名
@property BOOL zipStatus;   /**< 是否为压缩包状态  */
@property int faceCount;    /**< 图片中脸的个数  */
@property BOOL getMark; /**< 判断当前sessionId是否请求过  */

//添加新的属性
//@property int label;  /**< 人集合类别数，-1是离群点，也算一类，-2是未初始化 **/
//@property int core;   /**< 0表示非头像，1表示头像 **/

- (UIImage *)thumbImage;

@end
RLM_ARRAY_TYPE(MTImageModel)
