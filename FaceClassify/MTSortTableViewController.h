//
//  MTSortTableViewController.h
//  FaceClassify
//
//  Created by meitu on 16/6/7.
//  Copyright © 2016年 meitu. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MTSortCollectionViewController;
@interface MTSortTableViewController : UITableViewController

@property (nonatomic, strong) NSMutableArray *selectionCells;

@property (nonatomic, assign) BOOL moveStatus;  /**< 当前是否为移动状态 **/


@property (nonatomic, strong) NSMutableSet *labelSet;
@property (nonatomic, strong) NSMutableArray *labelArr;

@property (nonatomic, strong) NSArray *moveInfoArray;
@property (nonatomic, strong) NSArray *allInfoArray;
@property (nonatomic, assign) NSUInteger sourceLabel;
@property (nonatomic, strong) MTSortCollectionViewController *currentCVC;

// 保存状态的字典
@property (nonatomic, strong) NSMutableDictionary *statusDict;

/**
 *  更新tableview
 */
- (void)refreshTableViewData;
- (IBAction)sortClick:(id)sender;
@end
