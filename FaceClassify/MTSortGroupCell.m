//
//  MTSortGroupCell.m
//  FaceClassify
//
//  Created by meitu on 16/6/7.
//  Copyright © 2016年 meitu. All rights reserved.
//

#import "MTSortGroupCell.h"
#import "MTImageModel.h"
#import "MTFileManager.h"
#import "UIImage+Extension.h"
#import "MTCommonData.h"

#define EXPANSION 10;

@interface MTSortGroupCell()

@property (nonatomic, strong) NSMutableDictionary *cellStatusDict;

@end

@implementation MTSortGroupCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.selectionStyle = UITableViewCellSelectionStyleNone;
}

- (void)setThumbImageWith:(NSDictionary *)imgsDict {
    //设置label = -1情况下的缩略图
    if ([imgsDict[@"label"] intValue] == -1) {
        self.iconImageView.image = [UIImage scaleFromImage:[UIImage imageNamed:@"no_img.png"] toSize:CGSizeMake(100, 100)];
    }
    
    //设置头像
    if ([imgsDict[@"core"] intValue] == 1) {
        NSDictionary *dict = imgsDict[@"points"];
        
        NSString *pathDocuments = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        
        NSString *originImagePath = [originImagePathName stringByAppendingPathComponent:imgsDict[@"imageName"]];
        NSString *path = [pathDocuments stringByAppendingPathComponent:originImagePath];
        UIImage *originImage = [UIImage imageWithContentsOfFile:path];
        
        //1.0x
        CGFloat SATRT_X = originImage.size.width * [dict[@"x"] floatValue];
        CGFloat SATRT_Y = originImage.size.height * [dict[@"y"] floatValue];
        CGFloat WIDTH = originImage.size.width * [dict[@"w"] floatValue];
        CGFloat HEIGHT = originImage.size.height * [dict[@"h"] floatValue];
        
        //1.5x
        CGFloat new_W = WIDTH * 1.5;
        CGFloat new_H = HEIGHT * 1.5;
        CGFloat new_SATART_X = (SATRT_X + WIDTH * 0.5) - new_W * 0.5;
        CGFloat new_SATART_Y = (SATRT_Y + HEIGHT * 0.5) - new_H * 0.5;
        
        UIImage *faceImage = [UIImage getImageFromImage:originImage subImageSize:CGSizeMake(new_W, new_H) subImageRect:CGRectMake(new_SATART_X, new_SATART_Y, new_W, new_H)];
        
        self.iconImageView.image = [UIImage scaleFromImage:faceImage toSize:CGSizeMake(100, 100)];
    }
}

- (void)setCurrentChooseStatus:(BOOL)currentChooseStatus {
    _currentChooseStatus = currentChooseStatus;
    self.backgroundColor = currentChooseStatus ? [UIColor lightGrayColor] : [UIColor clearColor];
}

@end
