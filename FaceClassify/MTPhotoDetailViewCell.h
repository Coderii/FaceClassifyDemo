//
//  MTPhotoDetailViewCell.h
//  MTPhotoLibrary
//
//  Created by JoyChiang on 15/6/20.
//  Copyright (c) 2015年 Meitu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MTPhotoAsset.h"
#import "MTImageManager.h"

@class MTPhotoDetailScrollView;

@protocol MTAssetViewCellDelegate;

@interface MTPhotoDetailViewCell : UICollectionViewCell

@property (nonatomic, weak) id<MTAssetViewCellDelegate> delegate;
@property (nonatomic, strong, readonly) UIImage *image;

@property (nonatomic, strong) MTPhotoAsset *photoAsset;

@property (nonatomic, weak) MTImageManager *imageManager;


@end

@protocol MTAssetViewCellDelegate <NSObject>

- (void)assetViewCellDidTap:(MTPhotoDetailViewCell *)viewCell numberOfTapsRequired:(NSUInteger)numberOfTapsRequired;

@end
