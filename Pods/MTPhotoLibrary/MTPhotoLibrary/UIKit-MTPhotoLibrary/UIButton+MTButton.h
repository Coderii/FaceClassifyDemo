//
//  UIButton+MTButton.h
//  MTImagePickerControllerDemo
//
//  Created by meitu on 16/7/14.
//  Copyright © 2016年 Meitu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MTPhotoLibrary.h"

typedef void(^MTButtonEventHandler)(id sender);

@interface UIButton (MTButton) <MTPhotoLibraryChangeObserver>

/**
 *  创建一个最新的照片按钮, 能够自动监听系统相册数据的变化
 *
 *
 *  @param frame         按钮大小
 *  @param controlEvents 按钮事件类型
 *  @param handler       按钮事件回调
 */
+ (instancetype)mt_createRecentImageButtonWithFrame:(CGRect)frame
                                          events:(UIControlEvents)controlEvents
                                       eventHandler:(MTButtonEventHandler)handler;

/**
 *  移除监听的通知, 默认自动开启监听
 */
- (void)mt_removeObserver;
@end
