//
//  MTSortTableViewController.m
//  FaceClassify
//
//  Created by meitu on 16/6/7.
//  Copyright © 2016年 meitu. All rights reserved.
//

#import "MTSortTableViewController.h"

#import <Realm/Realm.h>

#import "MTSortGroupCell.h"
#import "MTSortCollectionViewController.h"

#import "MTImageModel.h"
#import "MTItemModel.h"
#import "MBProgressHUD.h"

#import "MTNetworking.h"
#import "MTImageModelManager.h"
#import "UIImage+Extension.h"

@interface MTSortTableViewController ()<MTSortCollectionViewControllerDelegate> {
    NSIndexPath *_indexPath;
}

@property (nonatomic, strong) NSMutableArray *faceCountArr; /**< 脸的数量  */
@property (nonatomic, strong) NSArray *classifyArr;

//存储图片
@property (nonatomic, strong) NSMutableDictionary *photoDict;

@property (nonatomic, strong) NSMutableArray *photoArray;

@property (nonatomic, strong) MTGetManager *getManager;

@property (nonatomic, strong) MTUploadManager *uploadManager;

@property (nonatomic, strong) MTImageModelManager *modelManager;

@property (nonatomic, strong) NSMutableSet *detailSet;

@property (nonatomic, strong) NSArray *setSortArr;

@property (nonatomic, strong) RLMResults *results;

@property (nonatomic, strong) NSArray *detailImgarr;

@property (nonatomic, strong) NSMutableSet *imgset;
@property (nonatomic, strong) NSMutableArray *pointarr;

//手势
@property (nonatomic, strong) UILongPressGestureRecognizer *longPressGesture;

@property (nonatomic, strong) UIBarButtonItem *leftItem;

@end

static int label__1 = 0;
static int refreshFloag = 0;
static NSUInteger getInfoFlag = 0;

@implementation MTSortTableViewController

- (void)dealloc {
    refreshFloag = 0;
}

- (void)viewDidLoad {
    [super viewDidLoad]; 
    
    self.navigationItem.backBarButtonItem = self.leftItem;

    self.tableView.tableFooterView = [[UIView alloc] init];
    self.tableView.separatorInset = UIEdgeInsetsZero;
    
    //增加长按手势
    [self.tableView addGestureRecognizer:self.longPressGesture];
    
    if (!self.moveStatus) {
        [self sortClick:nil];
    }
    
    // init tableView
    [self.tableView registerNib:[UINib nibWithNibName:NSStringFromClass([MTSortGroupCell class]) bundle:nil] forCellReuseIdentifier:NSStringFromClass([MTSortGroupCell class])];
    
    // status dict
    self.statusDict = [NSMutableDictionary dictionary];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section { 
    return self.labelSet.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MTSortGroupCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MTSortGroupCell" forIndexPath:indexPath];
    cell.currentChooseStatus = [[self.statusDict objectForKey:indexPath] boolValue];
    
    //根据core选择显示缩略  
    NSSortDescriptor *sd = [[NSSortDescriptor alloc] initWithKey:nil ascending:YES];
    NSArray *sortDescriptors = [NSArray arrayWithObjects:sd, nil];
    NSArray *arrar = [self.labelSet sortedArrayUsingDescriptors:sortDescriptors];   // labelset = 0 -1
    self.setSortArr = arrar;    //-1 0
    
    int labelCount = [arrar[indexPath.row] intValue];
    
    // 获取具体的张数
    NSMutableSet *imgCountsSet = [NSMutableSet set];
    for (NSDictionary *pointdict in self.labelArr) {
        if ([pointdict[@"label"] intValue] == labelCount) {
            [imgCountsSet addObject:pointdict[@"imageName"]];
        }
    }
    
    cell.titleLabel.text = [NSString stringWithFormat:@"分类Label:%d (%@张)", labelCount, @([imgCountsSet allObjects].count)];
    
    //根据label的值设置缩略图
    for (NSDictionary *imgdict in self.labelArr) {
        if ([imgdict[@"label"] intValue] == labelCount) {
            [cell setThumbImageWith:imgdict];
        }
    }
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 126;
} 

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if (self.moveStatus) {
        [self moveClassInfoWithIndxPath:indexPath];
    }
    else {
        [self getShowInfoCompletion:^{
            [self getClassInfoWithIndexPath:indexPath];
        }];
    }
}

#pragma mark - sort

- (IBAction)sortClick:(id)sender {
    label__1 = 0;
    
    //增加进度
    [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
    [MBProgressHUD HUDForView:self.navigationController.view].label.text = @"获取识别结果...";
    dispatch_async(dispatch_get_main_queue(), ^{
        __weak typeof(self) _weakSelf = self;
        
        [self getSortDataFromServerCompletion:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                
                //获取信息
                __strong typeof(self) _strongSelf = self;
                [_weakSelf getShowInfoCompletion:^{
                    
                   [_strongSelf.tableView reloadData];
                    [MBProgressHUD HUDForView:_strongSelf.navigationController.view].label.text = @"发送请求成功!";
                    [[MBProgressHUD HUDForView:_strongSelf.navigationController.view] hideAnimated:YES afterDelay:1.0];
                }];
            });
        } failure:^(NSError *error) {
            [MBProgressHUD HUDForView:self.navigationController.view].label.text = error.domain;
            [[MBProgressHUD HUDForView:self.navigationController.view] hideAnimated:YES afterDelay:1.0];
        }];
    });
    
    refreshFloag++;
}

- (void)getSortDataFromServerCompletion:(void(^)())completion failure:(void(^)(NSError *error))failure {
    //GET请求
    RLMResults *results = [MTImageModel objectsWhere:@"getMark = 0"];
    [self.getManager GETJpgDataWithRLMResults:results progress:nil completion:^(NSArray *getArray) {    //GET单文件数据成功
        //更新数据库数据
        [self.modelManager updateJpgDataWithGetArray:getArray completion:^{
            //block回调
            if (completion) {
                completion();
            }
        }];
    } failure:^(NSError *error) {   //GET单文件数据失败
        if (failure) {
            failure(error);
        }
    }];
}

//从数据库获取需要显示的信息
- (void)getShowInfoCompletion:(void(^)())completion {
    //数据库更新完毕，更新UI界面
    RLMResults *results = [MTImageModel allObjects];
    self.results = results;
    
    self.labelSet = nil;
    self.labelArr = nil;
    getInfoFlag = 0;
    
    for (MTImageModel *model in results) {
        NSArray *array = [NSArray array];
        if (model.boxesFeatures.length != 0) {
            array = [NSKeyedUnarchiver unarchiveObjectWithData:model.boxesFeatures];
        }
        
        NSDictionary *imgDict = [NSDictionary dictionary];
        for (NSArray *arr in array) {
            NSDictionary *dict = [arr lastObject];
            
            NSDictionary *pointDict = [arr firstObject];
            
            //分类的种类label种类
            [self.labelSet addObject:dict[@"label"]];   //0 -1
            
            imgDict = @{@"imageName": model.imageName,
                        @"label": dict[@"label"],
                        @"core": dict[@"core"],
                        @"points": pointDict};
            
            //人脸信息
            [self.labelArr addObject:imgDict];
        }
        
        getInfoFlag++;
        
        if (getInfoFlag == results.count) {
            if (completion) {
                completion();
            }
        }
    }
}

#pragma mark Class methods

//合并UitableViewCell
- (void)longPressTabelViewCell:(UILongPressGestureRecognizer *)longPressGesture {
    if (longPressGesture.state == UIGestureRecognizerStateBegan) {
        //获取所在的view
        CGPoint point = [longPressGesture locationInView:self.tableView];
        _indexPath = [self.tableView indexPathForRowAtPoint:point];

        MTSortGroupCell *cell = [self.tableView cellForRowAtIndexPath:_indexPath];
        //设置选中状态
        if ([self.setSortArr[_indexPath.row] intValue] != -1) {
            cell.currentChooseStatus = !cell.currentChooseStatus;
            [self.statusDict setObject:@(cell.currentChooseStatus) forKey:_indexPath];
            if (cell.currentChooseStatus) {
                //删除选中的label
                [self.selectionCells addObject:self.setSortArr[_indexPath.row]];
            }
            else {
                //添加选中的label
                [self.selectionCells removeObject:self.setSortArr[_indexPath.row]];
            }
        }
    }
}

- (void)refreshTableViewData {
    //获取信息
    __weak typeof(self) __weakSelf = self;
    [self getShowInfoCompletion:^{
        //更新表格信息
        [__weakSelf.tableView reloadData];
    }];
}

//移动功能
- (void)moveClassInfoWithIndxPath:(NSIndexPath *)indexPath {
    refreshFloag = 0;
    
    NSSortDescriptor *sd = [[NSSortDescriptor alloc] initWithKey:nil ascending:YES];
    NSArray *sortDescriptors = [NSArray arrayWithObjects:sd, nil];
    NSArray *arrar = [self.labelSet sortedArrayUsingDescriptors:sortDescriptors];   // labelset = 0 -1
    
    __block NSMutableArray *moveArray = [NSMutableArray array];
    [self.moveInfoArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSDictionary *moveDict = @{@"SourceLabel": @(self.sourceLabel),
                                   @"TargetLabel": @([arrar[indexPath.row] intValue]),
                                   @"ImageSet_id": obj};
        [moveArray addObject:moveDict];
        NSLog(@"moveArray = %@", moveArray);
    }];
    
    MBProgressHUD *progressHUD = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
    progressHUD.label.text = @"正在移动";
    [self.uploadManager POSTMoveInfo:@{@"ImageSet": moveArray} completion:^(NSArray *getinfo) {
        
        //更新数据库
        [self.modelManager updateJpgDataWithGetArray:getinfo completion:^{
            [self getShowInfoCompletion:^{
                [progressHUD hideAnimated:YES];
                
                self.imgset = nil;
                self.pointarr = nil;
                for (NSDictionary *pointdict in self.labelArr) {
                    if ([pointdict[@"label"] intValue] == self.sourceLabel) {
                        [self.imgset addObject:pointdict[@"imageName"]];
                        [self.pointarr addObject:pointdict];
                    }
                }
                
                self.currentCVC.resultArray = [self.imgset allObjects];
                self.currentCVC.pointDictArray = self.pointarr;
                
                [self.tableView reloadData];
                [self dismissViewControllerAnimated:YES completion:nil];
                self.moveInfoArray = nil;
            }];
        }];
    } failure:^(NSError *error) {
        self.moveInfoArray = nil;
    }];
}

//获取每一个详细分类界面的结果
- (void)getClassInfoWithIndexPath:(NSIndexPath *)indexPath { 
    MTSortCollectionViewController *collectionVC = [[MTSortCollectionViewController alloc] init];
    collectionVC.itemCount = [self.setSortArr[indexPath.row] intValue] ;//indexPath.row;
    collectionVC.delegate = self;
    
    //保存当前分类结果信息
    collectionVC.sortTableViewSet = self.labelSet;
    collectionVC.sortTableViewArr = self.labelArr;
    
    self.imgset = nil;
    self.pointarr = nil;
    for (NSDictionary *pointdict in self.labelArr) {
        if ([pointdict[@"label"] intValue] == collectionVC.itemCount) {
            [self.imgset addObject:pointdict[@"imageName"]];
            [self.pointarr addObject:pointdict];
        }
    }
    
    collectionVC.resultArray = [self.imgset allObjects];
    collectionVC.pointDictArray = self.pointarr;
    
    if (!self.moveStatus) {
        [self.navigationController pushViewController:collectionVC animated:YES];
    }
}

#pragma mark MTSortCollectionViewControllerDelegate

- (void)sortCollectionViewControllerRightBarButtonEditIsChoose:(UICollectionViewController *)collectionVC {
    
}

- (void)sortCollectionViewControllerRightBarButtonCancelIsChoose:(UICollectionViewController *)collectionVC {
    self.navigationItem.backBarButtonItem = self.leftItem;
}

- (void)sortCollectionViewControllerDeleteImageIsChoose:(UICollectionViewController *)collectionVC {
    refreshFloag = 0;
}
#pragma mark - 懒加载

//根据label进行分类的结果数组
- (NSMutableArray *)labelArr {
    if (!_labelArr) {
        _labelArr = [NSMutableArray array];
    }
    return _labelArr;
}

- (NSMutableSet *)labelSet {
    if (!_labelSet) {
        _labelSet = [NSMutableSet set];
    }
    return _labelSet;
}

- (NSArray *)classifyArr {
    if (!_classifyArr) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *filename = [documentsDirectory stringByAppendingPathComponent:@"classify.plist"];
        NSArray *dictArray = [NSArray arrayWithContentsOfFile:filename];
        _classifyArr = dictArray;
    }
    return _classifyArr;
}

- (NSMutableDictionary *)photoDict {
    if (!_photoDict) {
        _photoDict = [NSMutableDictionary dictionary];
    }
    return _photoDict;
}

- (NSMutableArray *)photoArray {
    if (!_photoArray) {
        _photoArray = [[NSMutableArray alloc] init];
    }
    return _photoArray;
}

- (NSArray *)detailImgarr {
    if (!_detailImgarr) {
        _detailImgarr = [NSMutableArray array];
    }
    return _detailImgarr;
}

- (NSMutableSet *)detailSet {
    if (!_detailSet) {
        _detailSet = [NSMutableSet set];
    }
    return _detailSet;
}

- (NSArray *)setSortArr {
    if (!_setSortArr) {
        _setSortArr = [NSArray array];
    }
    return _setSortArr;
}

- (NSMutableSet *)imgset {
    if (!_imgset) {
        _imgset = [[NSMutableSet alloc] init];
    }
    return _imgset;
}

- (NSMutableArray *)pointarr {
    if (!_pointarr) {
        _pointarr = [[NSMutableArray alloc] init];
    }
    return _pointarr;
}

- (MTGetManager *)getManager {
    if (!_getManager) {
        _getManager = [[MTGetManager alloc] init];
    }
    return _getManager;
}

- (MTUploadManager *)uploadManager {
    if (!_uploadManager) {
        _uploadManager = [[MTUploadManager alloc] init];
    }
    return _uploadManager;
}

- (MTImageModelManager *)modelManager {
    if (!_modelManager) {
        _modelManager = [MTImageModelManager sharedSingleton];
    }
    return _modelManager;
}

- (NSMutableArray *)selectionCells {
    if (!_selectionCells) {
        _selectionCells = [NSMutableArray array];
    }
    return _selectionCells;
}

- (UILongPressGestureRecognizer *)longPressGesture {
    if (!_longPressGesture) {
        _longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressTabelViewCell:)];
        _longPressGesture.minimumPressDuration = 0.3f;
    }
    return _longPressGesture;
}

- (UIBarButtonItem *)leftItem {
    if (!_leftItem) {
        _leftItem = [[UIBarButtonItem alloc] init];
        _leftItem.title = @"返回";
    }
    return _leftItem;
}
@end
