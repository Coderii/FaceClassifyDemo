//
//  MTSortViewController.m
//  FaceClassify
//
//  Created by meitu on 16/6/7.
//  Copyright © 2016年 meitu. All rights reserved.
//

#import "MTSortViewController.h"
#import "MTSortTableViewController.h"
#import "MTUploadManager.h"
#import "MTImageModelManager.h"
#import "MBProgressHUD.h"

@interface MTSortViewController ()

@property (nonatomic, strong) MTSortTableViewController *sortTbaleVC;

@property (nonatomic, strong) UILabel *titleLabel;

@property (nonatomic, strong) MTUploadManager *uploadManager;

@property (nonatomic, strong) MTImageModelManager *modelManager;
@end

@implementation MTSortViewController

- (instancetype)init {
    if (self = [super initWithRootViewController:self.sortTbaleVC]) {

        UINavigationBar *naviBar = [UINavigationBar appearance];
        naviBar.barTintColor = [UIColor purpleColor];
        naviBar.tintColor = [UIColor whiteColor];
    }
    return self;
}

- (instancetype)initWithRootViewController:(UIViewController *)rootViewController {
    return [self init];
} 

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated. 
}

#pragma mark - 懒加载

- (MTSortTableViewController *)sortTbaleVC {
    if (!_sortTbaleVC) {
        _sortTbaleVC = [[MTSortTableViewController alloc] init];
        
        _sortTbaleVC.navigationItem.titleView = self.titleLabel;
        _sortTbaleVC.moveStatus = NO;
        
        //设置导航栏左侧标题
        UIBarButtonItem *cancelItem = [[UIBarButtonItem alloc] initWithTitle:@"返回" style:UIBarButtonItemStylePlain target:self action:@selector(dismiss)];
        _sortTbaleVC.navigationItem.leftBarButtonItem = cancelItem;
        
        UIBarButtonItem *unite = [[UIBarButtonItem alloc] initWithTitle:@"合并" style:UIBarButtonItemStylePlain target:self action:@selector(uniteCell)];
        _sortTbaleVC.navigationItem.rightBarButtonItem = unite;
    }
    return _sortTbaleVC;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        //设置导航栏的标题
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.text = @"分类结果";
        _titleLabel.textColor = [UIColor whiteColor];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        [_titleLabel sizeToFit];
    }
    return _titleLabel;
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

#pragma mark Class methods

- (void)dismiss {
    [self dismissViewControllerAnimated:YES completion:nil];
}

//合并表格
- (void)uniteCell {
    NSLog(@"合并当前分组");
    if (self.sortTbaleVC.selectionCells.count == 0) {
        //表示没有选中一个cell
        UIAlertController *alertC = [UIAlertController alertControllerWithTitle:@"没有合并的内容" message:@"请长按分组进行选择!" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *alertAction = [UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        }];
        [alertC addAction:alertAction];
        [self presentViewController:alertC animated:YES completion:nil];
    }
    else {
        NSLog(@"合并的cells %@", self.sortTbaleVC.selectionCells);
        
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        [MBProgressHUD HUDForView:self.view].labelText = @"正在合并中...";
        
        //发送合并请求
        [self.uploadManager POSTUniteInfo:self.sortTbaleVC.selectionCells completion:^(NSArray *responseArray) {
            //更新数据库
            [self.modelManager updateJpgDataWithGetArray:responseArray completion:^{
                //更新表格
                [self.sortTbaleVC refreshTableViewData];
                [[MBProgressHUD HUDForView:self.view] hide:YES];
                
                //合并成功
                self.sortTbaleVC.selectionCells = nil;
                [self.sortTbaleVC.statusDict removeAllObjects];
            }];
            
        } failure:^(NSError *error) {
            
        }];
    }
}

@end
