//
//  MTMoveChooseNC.m
//  FaceClassify
//
//  Created by meitu on 16/7/5.
//  Copyright © 2016年 meitu. All rights reserved.
//

#import "MTMoveChooseNC.h"
#import "MTSortTableViewController.h"

@interface MTMoveChooseNC ()
@property (nonatomic, strong) UILabel *titleLabel;

@end

@implementation MTMoveChooseNC

#pragma mark LifeCycle

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
        _sortTbaleVC.moveStatus = YES;
        
        //设置导航栏左侧标题
        UIBarButtonItem *cancelItem = [[UIBarButtonItem alloc] initWithTitle:@"取消" style:UIBarButtonItemStylePlain target:self action:@selector(dismiss)];
        _sortTbaleVC.navigationItem.rightBarButtonItem = cancelItem;
    }
    return _sortTbaleVC;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        //设置导航栏的标题
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.text = @"移动到分类";
        _titleLabel.textColor = [UIColor whiteColor];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        [_titleLabel sizeToFit];
    }
    return _titleLabel;
}

#pragma mark Class methods

- (void)dismiss {
    [self dismissViewControllerAnimated:YES completion:nil];
}
@end
