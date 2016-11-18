//
//  MTSortCollectionViewController.h
//  FaceClassify
//
//  Created by meitu on 16/6/7.
//  Copyright © 2016年 meitu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Realm/Realm.h>

/** MTSortCollectionViewController代理 **/
@protocol MTSortCollectionViewControllerDelegate <NSObject>

@optional
- (void)sortCollectionViewControllerRightBarButtonEditIsChoose:(UICollectionViewController *)collectionVC;
- (void)sortCollectionViewControllerRightBarButtonCancelIsChoose:(UICollectionViewController *)collectionVC;
- (void)sortCollectionViewControllerDeleteImageIsChoose:(UICollectionViewController *)collectionVC;
@end

@interface MTSortCollectionViewController : UICollectionViewController

@property (nonatomic, strong) RLMResults *result;

@property (nonatomic, strong) NSArray *resultArray;

@property (nonatomic, strong) NSArray *pointDictArray;

@property (nonatomic, assign) int itemCount;

@property (nonatomic, copy) NSString *markImageName;

@property (nonatomic, copy) void(^didChooseEdit)(); /**< 选择编辑功能的block **/
@property (nonatomic, copy) void(^didChooseCancel)();   /**< 选择取消功能的block **/

@property (nonatomic, weak) id<MTSortCollectionViewControllerDelegate> delegate;    /**< MTSortCollectionViewController代理 **/


@property (nonatomic, strong) NSMutableSet *sortTableViewSet;
@property (nonatomic, strong) NSMutableArray *sortTableViewArr;

@end
