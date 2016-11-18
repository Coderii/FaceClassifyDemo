//
//  MTPhotoAlbumViewCell.h
//  MTPhotoLibrary
//
//  Created by JoyChiang on 15/6/20.
//  Copyright (c) 2015年 Meitu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MTPhotoAlbum.h"

static int kAlbumRowHeight = 65.f;
static int kAlbumLeftToImageSpace = 8.f;
static int kAlbumImageToTextSpace = 15.f;
static CGSize const kAlbumThumbnailSize = {40.f , 40.f};

@interface MTPhotoAlbumViewCell : UITableViewCell

@property (nonatomic, strong) MTPhotoAlbum *photoAlbum;

@end
