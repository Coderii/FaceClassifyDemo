//
//  MTSortGroupCell.h
//  FaceClassify
//
//  Created by meitu on 16/6/7.
//  Copyright © 2016年 meitu. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MTSortGroupCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *iconImageView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@property (nonatomic, assign) BOOL currentChooseStatus; /**< 当前cell的选中状态，默认没有选中 **/

/**
 *  设置图片
 *
 *  @param imgsDict 字典数据
 */
- (void)setThumbImageWith:(NSDictionary *)imgsDict;

@end
