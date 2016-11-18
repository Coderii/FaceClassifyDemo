//
//  MTPhotoDetailViewCell.m
//  MTPhotoLibrary
//
//  Created by JoyChiang on 15/6/20.
//  Copyright (c) 2015年 Meitu. All rights reserved.
//

#import "MTPhotoDetailViewCell.h"
#import "MTPhotoDetailScrollView.h"

@interface MTPhotoDetailViewCell() <MTAssetScrollViewDelegate>

@property (nonatomic, strong) MTPhotoDetailScrollView *imageScrollView;

@end

@implementation MTPhotoDetailViewCell

#pragma mark - Init

- (void)dealloc
{
    _imageScrollView = nil;
    _photoAsset = nil;
}


- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.contentView.backgroundColor = [UIColor clearColor];
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        self.imageScrollView = [[MTPhotoDetailScrollView alloc] initWithDelegate:self];
        self.imageScrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.imageScrollView.frame = CGRectMake(0.0f,
                                                0.0f,
                                                self.bounds.size.width,
                                                self.bounds.size.height);
        
        [self.contentView addSubview:self.imageScrollView];
    }
    return self;
}

#pragma mark - Public

- (void)setPhotoAsset:(MTPhotoAsset *)photoAsset
{
    if (![photoAsset isEqual:_photoAsset]) {
        _photoAsset = photoAsset;
        _imageScrollView.photoAsset = photoAsset;
    }
}

- (void)setImageManager:(MTImageManager *)imageManager
{
    _imageManager = imageManager;
    
    _imageScrollView.imageManager = imageManager;
}

- (UIImage *)image
{
    return _imageScrollView.image;
}


#pragma mark - Reuse

- (void)prepareForReuse
{
    [super prepareForReuse];
    
    _photoAsset = nil;
    [self.imageScrollView prepareForReuse];
//    [self.imageScrollView removeFromSuperview];
//    
//    self.imageScrollView = [[MTPhotoDetailScrollView alloc] initWithDelegate:self];
//    self.imageScrollView.frame = CGRectMake(0.0f,
//                                            0.0f,
//                                            self.bounds.size.width,
//                                            self.bounds.size.height);
//
//    self.imageScrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
//    [self.contentView addSubview:self.imageScrollView];
}

#pragma mark - MTAssetScrollViewDelegate

- (void)scrollViewDidTap:(MTPhotoDetailScrollView *)scrollView numberOfTapsRequired:(NSUInteger)numberOfTapsRequired
{
    if ([self.delegate respondsToSelector:@selector(assetViewCellDidTap:numberOfTapsRequired:)]) {
        [self.delegate assetViewCellDidTap:self numberOfTapsRequired:numberOfTapsRequired];
    }
}

@end
