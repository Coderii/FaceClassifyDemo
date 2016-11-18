//
//  MTPhotoAssetsCollectionViewController.m
//  FaceClassify
//
//  Created by Cheng on 16/9/2.
//  Copyright © 2016年 meitu. All rights reserved.
//

#import "MTPhotoAssetsCollectionViewController.h"
#import <MTImageManager.h>
#import <MTPhotoLibrary.h>

#import "MTPhotoAssetsViewLayout.h"
#import "MTCommonData.h"
#import "UIButton+EdgeInsets.h"
#import "MTPhotoAlbumViewController.h"

@interface MTPhotoAssetsCollectionViewController ()<MTPhotoLibraryChangeObserver>

@property (nonatomic, strong) MTImageManager *imageManager;
@property (nonatomic, strong) MTPhotoAlbumViewController *photoAlbumViewController;

@property (nonatomic, strong) NSMutableArray *photoAlbums;
@property (nonatomic, strong) UIButton *titleButton;
@end

@implementation MTPhotoAssetsCollectionViewController

static NSString * const reuseIdentifier = @"Cell";

#pragma mark - LifeCycle

- (void)dealloc {
    [[MTPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];
}

- (instancetype)init {
    self = [super initWithCollectionViewLayout:[[MTPhotoAssetsViewLayout alloc] init]];
    if (self) {
        _imageManager = [[MTImageManager alloc] init];
        [[MTPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.titleView = self.titleButton;
    [self setSelectedAlbumlTitle:self.photoAlbum.title];
    
    // Register cell classes
    [self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:reuseIdentifier];
    self.collectionView.alwaysBounceVertical = YES;
    self.collectionView.backgroundColor = [UIColor whiteColor];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark Setter/Getter

-(UIButton *)titleButton {
    if (_titleButton == nil) {
        _titleButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [[_titleButton titleLabel] setFont:[UIFont systemFontOfSize:17]];
        [_titleButton setTitleColor:RGBAHEX(0x535353, 1) forState:UIControlStateNormal];
        [_titleButton setTitleColor:RGBAHEX(0xff6258, 1) forState:UIControlStateHighlighted];
        [_titleButton setImage:[UIImage imageNamed:@"icon_albums_packup_normal"] forState:UIControlStateNormal];
        [_titleButton setImage:[UIImage imageNamed:@"icon_albums_packup_disable"] forState:UIControlStateHighlighted];
        [_titleButton addTarget:self action:@selector(actionPhotoAlbums:) forControlEvents:UIControlEventTouchUpInside];
        [_titleButton layoutButtonWithEdgeInsetsStyle:ButtonEdgeInsetsStyleImageRight imageTitlespace:3];
    }
    return _titleButton;
}

#pragma mark Private Methods

- (void)actionPhotoAlbums:(id)sender {
    if (self.photoAlbumViewController == nil && self.photoAlbums.count) {
        __weak typeof(self) weakSelf = self;
        
        self.photoAlbumViewController = [MTPhotoAlbumViewController presentFromViewController:self currentSelectedPhotoAlbum:self.photoAlbum select:^(MTPhotoAlbum *photoAlbum) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (photoAlbum != strongSelf.photoAlbum && photoAlbum != nil) {
                    strongSelf.photoAlbum = photoAlbum;
                    [strongSelf.collectionView reloadData];
                    
                    if ([strongSelf numberOfAssets] > 0) {
                        [strongSelf scrollToBottom];
                    }
                }
            });
        } dismissBlock:^{
            [self updateIconImageForTitleButton];
        }];
    }
}

-(NSInteger)numberOfAssets {
    if (self.photoAlbum.assetsGroup) {
        return self.photoAlbum.asALAssets.count;
    }
    else {
        return self.photoAlbum.numberOfAssets;
    }
}

- (void)scrollToBottom {
    NSInteger section = [self.collectionView numberOfSections] - 1;
    NSInteger item = [self.collectionView numberOfItemsInSection:section] - 1;
    if (section >= 0 && item >= 0) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:item inSection:section];
        [self.collectionView scrollToItemAtIndexPath:indexPath
                                    atScrollPosition:UICollectionViewScrollPositionBottom
                                            animated:NO];
    }
}

- (void)updateIconImageForTitleButton {
    UIImage *iconImage = nil;
    if (self.photoAlbumViewController) {
        iconImage = [UIImage imageNamed:@"icon_albums_expand"];
    }
    else {
        iconImage = [UIImage imageNamed:@"icon_albums_packup_normal"];
        
    }
    [_titleButton setImage:iconImage forState:UIControlStateNormal];
}

- (void)setSelectedAlbumlTitle:(NSString *)title {
    self.title = title;
    
    [_titleButton setTitle:self.title forState:UIControlStateNormal];
    [_titleButton setTitle:self.title forState:UIControlStateHighlighted];
    [_titleButton setImage:[UIImage imageNamed:@"icon_albums_packup_normal"] forState:UIControlStateNormal];
    [_titleButton setImage:[UIImage imageNamed:@"icon_albums_packup_disable"] forState:UIControlStateDisabled];
    _titleButton.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    CGSize titleSize = [self.title sizeWithAttributes:@{NSFontAttributeName:_titleButton.titleLabel.font}];
    titleSize.width = 200;
    [_titleButton setBounds:CGRectMake(0, 0, titleSize.width+_titleButton.imageView.bounds.size.width+3, 44)];
    [_titleButton layoutButtonWithEdgeInsetsStyle:ButtonEdgeInsetsStyleImageRight imageTitlespace:3];
}

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 0;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return 0;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    
    // Configure the cell
    
    return cell;
}

#pragma mark <UICollectionViewDelegate>

/*
// Uncomment this method to specify if the specified item should be highlighted during tracking
- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}
*/

/*
// Uncomment this method to specify if the specified item should be selected
- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}
*/

/*
// Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
- (BOOL)collectionView:(UICollectionView *)collectionView shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath {
	return NO;
}

- (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	return NO;
}

- (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	
}
*/

@end
