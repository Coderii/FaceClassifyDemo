//
//  MTPhotoAlbumViewController.h
//  MTPhotoLibrary
//
//  Created by JoyChiang on 15/6/20.
//  Copyright (c) 2015年 Meitu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MTPhotoLibrary.h"

typedef void(^DidDissmiss)(void);


@interface MTPhotoAlbumViewController : UIViewController
@property (nonatomic, readonly) NSMutableArray *photoAlbums;
@property (nonatomic, assign) NSUInteger currentSelectIndex;
@property (nonatomic, copy) DidDissmiss dissmissBlock;

+ (instancetype)presentFromViewController:(UIViewController *)viewController
                currentSelectedPhotoAlbum:(MTPhotoAlbum *)currentSelectedPhotoAlbum
                                   select:(void (^)(MTPhotoAlbum *))select dismissBlock:(DidDissmiss)block;


- (void)dismiss;

@end
