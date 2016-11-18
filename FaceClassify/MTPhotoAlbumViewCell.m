//
//  MTPhotoAlbumViewCell.m
//  MTPhotoLibrary
//
//  Created by JoyChiang on 15/6/20.
//  Copyright (c) 2015年 Meitu. All rights reserved.
//

#import "MTPhotoAlbumViewCell.h"
#import <QuartzCore/QuartzCore.h>
#import "UtilsDef.h"

@interface MTPhotoAlbumViewCell ()

// The labels
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *infoLabel;
// The imageView
@property (nonatomic, strong) UIImageView *imageView1;

@property (nonatomic, strong) UIImageView *checkImageView;

@end

@implementation MTPhotoAlbumViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        
        self.backgroundColor = [UIColor whiteColor];
        
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        //ImageView
        _imageView1 = [[UIImageView alloc] init];
        _imageView1.contentMode = UIViewContentModeScaleAspectFill;
        _imageView1.frame = CGRectMake(kAlbumLeftToImageSpace, (kAlbumRowHeight-kAlbumThumbnailSize.height)/2, kAlbumThumbnailSize.width, kAlbumThumbnailSize.height);
        _imageView1.clipsToBounds = YES;
        _imageView1.translatesAutoresizingMaskIntoConstraints = YES;
        _imageView1.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
        [self.contentView addSubview:_imageView1];

        _checkImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon_photo_albums_unselect"]];
        _checkImageView.frame = CGRectMake(CGRectGetWidth(self.frame)-27-20, (kAlbumRowHeight-27)/2, 27, 27);
        _checkImageView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        [self addSubview:_checkImageView];
        
        //TextLabel
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [UIFont systemFontOfSize:15.f];
        _titleLabel.textColor = [UIColor colorWithRed:53/255.0 green:53/255.0 blue:53/255.0 alpha:1.0];//RGBAHEX(0x535353, 1);
        _titleLabel.numberOfLines = 1;
        [self addSubview:_titleLabel];
    }
    
    return self;
}

- (void)setPhotoAlbum:(MTPhotoAlbum *)photoAlbum
{
    _photoAlbum = photoAlbum;
    
    self.titleLabel.text = photoAlbum.title;
    self.imageView1.image = photoAlbum.posterImage;
//    self.detailTextLabel.text = [NSString stringWithFormat:@"%ld", (long)photoAlbum.numberOfAssets];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    
    UIImage *selectImage = [UIImage imageNamed:@"icon_photo_albums_select"];
    UIImage *unselectImage = [UIImage imageNamed:@"icon_photo_albums_unselect"];
    _checkImageView.image = selected ? selectImage : unselectImage;
    self.titleLabel.textColor = selected ? RGBAHEX(0xff6258, 1) : RGBAHEX(0x535353, 1);
}

- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
    UIImage *selectImage = [UIImage imageNamed:@"icon_photo_albums_select"];
    UIImage *unselectImage = [UIImage imageNamed:@"icon_photo_albums_unselect"];
    _checkImageView.image = selected ? selectImage : unselectImage;
    self.titleLabel.textColor = selected ? RGBAHEX(0xff6258, 1) : RGBAHEX(0x535353, 1);
}


- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
    [super setHighlighted:highlighted animated:animated];
    
    UIImage *selectImage = [UIImage imageNamed:@"icon_photo_albums_select"];
    UIImage *unselectImage = [UIImage imageNamed:@"icon_photo_albums_unselect"];
    _checkImageView.image = highlighted ? selectImage : (self.selected ? selectImage : unselectImage);
    self.titleLabel.textColor = highlighted? RGBAHEX(0xff6258, 1) : RGBAHEX(0x535353, 1);
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGRect frame = self.titleLabel.frame;
    frame.origin.x = CGRectGetMaxX(self.imageView1.frame) + kAlbumImageToTextSpace;
    frame.size.width = CGRectGetWidth(self.frame) - frame.origin.x - 55.f;
    frame.size.height = CGRectGetHeight(self.frame);
    frame.origin.y = .0f;
    self.titleLabel.frame = frame;
}

@end
