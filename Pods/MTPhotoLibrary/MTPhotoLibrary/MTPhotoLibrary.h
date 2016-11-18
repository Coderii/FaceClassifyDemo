//
//  MTPhotoLibrary.h
//  MTPhotoLibrary
//
//  Created by JoyChiang on 15/6/20.
//  Copyright (c) 2015年 Meitu. All rights reserved.
//

#import "MTPhotoManager.h"
#import "NSURL+ALAssetsGroup.h"

@interface MTPhotoLibrary : NSObject <MTPhotoManager>

+ (instancetype)sharedPhotoLibrary;

/**
 *  释放所持有的MTPhotoManager对象，避免出现刷新异常问题
 */
+ (void)clearData;

- (void)registerChangeObserver:(id<MTPhotoLibraryChangeObserver>)observer;
- (void)unregisterChangeObserver:(id<MTPhotoLibraryChangeObserver>)observer;

@end
