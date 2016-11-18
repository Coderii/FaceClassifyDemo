//
//  MTPhotoAssetsViewLayout.m
//  FaceClassify
//
//  Created by Cheng on 16/9/2.
//  Copyright © 2016年 meitu. All rights reserved.
//

#import "MTPhotoAssetsViewLayout.h"

static NSUInteger kNumberOfColumns = 3;

@implementation MTPhotoAssetsViewLayout

- (instancetype)init
{
    if (self = [super init]) {
        self.minimumInteritemSpacing = 3.f;
        
        CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
        int cellTotalUsableWidth = screenWidth - (kNumberOfColumns-1)*self.minimumInteritemSpacing;
        self.itemSize = CGSizeMake(cellTotalUsableWidth/kNumberOfColumns,
                                   cellTotalUsableWidth/kNumberOfColumns);
        double cellTotalUsedWidth = (double)self.itemSize.width*kNumberOfColumns;
        double spaceTotalWidth = (double)screenWidth-cellTotalUsedWidth;
        double spaceWidth = spaceTotalWidth/(double)(kNumberOfColumns-1);
        self.minimumLineSpacing = spaceWidth;
        
        self.sectionInset = UIEdgeInsetsMake(self.minimumInteritemSpacing, 0, 0, 0);
    }
    return self;
}

@end
