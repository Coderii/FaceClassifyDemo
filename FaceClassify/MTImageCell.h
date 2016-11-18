//
//  MTImageCell.h
//  FaceClassify
//
//  Created by meitu on 16/6/8.
//  Copyright © 2016年 meitu. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MTFaceView;
@interface MTImageCell : UICollectionViewCell

- (void)setFaceMarkWith:(NSString *)imgName pointArray:(NSArray *)pointArray;

@property (nonatomic, assign) BOOL currentChooseStatus; /**< 当前cell的选中状态，默认没有选中 **/
@property (nonatomic, assign) NSUInteger currentItem;

@property (nonatomic, strong) MTFaceView *faceView;
@end
