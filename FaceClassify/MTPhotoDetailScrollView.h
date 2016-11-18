//
//  MTPhotoDetailScrollView.h
//  MTPhotoLibrary
//
//  Created by JoyChiang on 15/6/20.
//  Copyright (c) 2015年 Meitu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MTPhotoAsset.h"
#import "MTImageManager.h"

@protocol MTAssetScrollViewDelegate;

@interface MTPhotoDetailScrollView : UIScrollView

@property (nonatomic, weak) id<MTAssetScrollViewDelegate> customDelegate;
@property (nonatomic, strong, readonly) UIImage *image;

@property (nonatomic, strong) MTPhotoAsset *photoAsset;
@property (nonatomic, weak) MTImageManager *imageManager;

@property (nonatomic, strong) UILabel *icloudDownLoadTipLabel;

- (instancetype)initWithDelegate:(id<MTAssetScrollViewDelegate>)delegate;

- (void)prepareForReuse;

@end

@protocol MTAssetScrollViewDelegate <NSObject>

- (void)scrollViewDidTap:(MTPhotoDetailScrollView *)scrollView numberOfTapsRequired:(NSUInteger)numberOfTapsRequired;

@end
