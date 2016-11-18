//
//  MTSortCollectionViewController.m
//  FaceClassify
//
//  Created by meitu on 16/6/7.
//  Copyright © 2016年 meitu. All rights reserved.
//

#import "MTSortCollectionViewController.h"

#import "MTImageCell.h"
#import "MTImageModel.h"

#import "MTItemModel.h"
#import "MTPhotoBrowser.h"
#import "MBProgressHUD.h"

#import "MTMoveChooseNC.h"
#import "MTSortTableViewController.h"
#import "MTUploadManager.h"
#import "MTImageModelManager.h"

@interface MTSortCollectionViewController () {
    UIBarButtonItem *_rightButton;
    UIBarButtonItem *_leftButton;
    NSIndexPath *_indexPath;
    BOOL _moveFlag;
}

@property (nonatomic, strong) UILabel *titleLabel;

//点击手势
@property (nonatomic, strong) UITapGestureRecognizer *tapGesture;

@property (nonatomic, strong) NSMutableArray *selectionCellArray;   /**< 已经选择的cell信息数组 **/
@property (nonatomic, strong) NSMutableArray *selectionCells;   /**< 已经选择的cell **/

@property (nonatomic, strong) UIView *bottomFuncView;   /**< 下方弹出功能框 **/

@property (nonatomic, strong) UILabel *naviLabel;

@property (nonatomic, strong) MTUploadManager *uploadManager;
@property (nonatomic, strong) MTImageModelManager *modelManager;

@property (nonatomic, strong) MTMoveChooseNC *moveNC;

@property (nonatomic, strong) NSMutableDictionary *cellStatusDict;  /** 用来保存cell选中状态的字典 **/
@end

@implementation MTSortCollectionViewController

static NSString * const reuseIdentifier = @"imageCell";

#pragma mark Life cycle

- (instancetype)init
{
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.sectionInset = UIEdgeInsetsMake(10, 10, 10, 10);
    return [super initWithCollectionViewLayout:flowLayout];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.collectionView registerNib:[UINib nibWithNibName:@"MTImageCell" bundle:nil] forCellWithReuseIdentifier:reuseIdentifier];
    self.collectionView.backgroundColor = [UIColor whiteColor];
    
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    CGFloat space = 3.0f;
    CGFloat width = ([UIScreen mainScreen].bounds.size.width-space *4)/3;
    
    layout.itemSize = CGSizeMake(width, width);
    layout.minimumLineSpacing = space;
    layout.minimumInteritemSpacing = space;
    [self.collectionView.collectionViewLayout invalidateLayout];
    [self.collectionView setCollectionViewLayout:layout];
    
    self.navigationItem.titleView = self.naviLabel;
    
    _rightButton = [[UIBarButtonItem alloc] initWithTitle:@"编辑" style:UIBarButtonItemStylePlain target:self action:@selector(editPhotos)];
    self.navigationItem.rightBarButtonItem = _rightButton;
    
    //添加返回按钮
    _leftButton = [[UIBarButtonItem alloc] initWithTitle:@"返回" style:UIBarButtonItemStylePlain target:self action:@selector(chooseBackAction)];
    self.navigationItem.leftBarButtonItem = _leftButton;
    
    // status
    self.cellStatusDict = [NSMutableDictionary dictionary];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    [self.collectionView reloadData];
    [self cancleChoose];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark <UICollectionViewDataSource>
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.resultArray.count; 
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    MTImageCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    // set cell Status
    cell.currentChooseStatus = [[self.cellStatusDict objectForKey:indexPath] boolValue];
    cell.currentItem = indexPath.row;
    
    // set faceMark
    [cell setFaceMarkWith:self.resultArray[indexPath.row] pointArray:self.pointDictArray];

    cell.contentView.frame = cell.bounds; 
    return cell; 
} 

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(120, 100);
}

#pragma mark <UICollectionViewDelegate>

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    //大图显示
    MTPhotoBrowser *browser = [[MTPhotoBrowser alloc] init];
    browser.assetModels = self.resultArray;
    browser.currentIndex = indexPath.item;
    browser.pointDict = self.pointDictArray;
    
    [browser show];
}

#pragma mark Class Methods

- (void)editPhotos {
    //添加手势
    [self.collectionView addGestureRecognizer:self.tapGesture];
    
    //变换按钮
    _rightButton = [[UIBarButtonItem alloc] initWithTitle:@"取消" style:UIBarButtonItemStylePlain target:self action:@selector(cancleChoose)];
    self.navigationItem.rightBarButtonItem = _rightButton;
    
    //显示下方功能框
    [self.view addSubview:self.bottomFuncView];
    
    //标题栏文字改变
    self.naviLabel.text = @"选择项目";
    
    //设置代理
    if ([self.delegate respondsToSelector:@selector(sortCollectionViewControllerRightBarButtonEditIsChoose:)]) {
        [self.delegate sortCollectionViewControllerRightBarButtonEditIsChoose:self];
    }
    
    //添加全选按钮
    UIBarButtonItem *chooseAllItem = [[UIBarButtonItem alloc] initWithTitle:@"全选" style:UIBarButtonItemStylePlain target:self action:@selector(chooseAllAction)];
    self.navigationItem.leftBarButtonItem = chooseAllItem;
}

- (void)cancleChoose {
    NSLog(@"取消");
    //移除手势
    [self.collectionView removeGestureRecognizer:self.tapGesture];
    
    _rightButton = [[UIBarButtonItem alloc] initWithTitle:@"编辑" style:UIBarButtonItemStylePlain target:self action:@selector(editPhotos)];
    self.navigationItem.rightBarButtonItem = _rightButton;
    
    //重置
    for (MTImageCell *cell in self.selectionCells) {
        cell.currentChooseStatus = NO;
    }
    
    //移除下方功能框
    [self.bottomFuncView removeFromSuperview];
    
    self.naviLabel.text = [NSString stringWithFormat:@"Label %d", self.itemCount];
    
    //设置代理
    if ([self.delegate respondsToSelector:@selector(sortCollectionViewControllerRightBarButtonCancelIsChoose:)]) {
        [self.delegate sortCollectionViewControllerRightBarButtonCancelIsChoose:self];
    }
    
    //添加返回按钮
    self.navigationItem.leftBarButtonItem = _leftButton;
    
    _moveFlag = NO;
    
    // remov status dict
    [self.cellStatusDict removeAllObjects];
    [self.collectionView reloadData];
}


- (void)tapCollectionViewCell:(UITapGestureRecognizer *)tapGesture {
    NSLog(@"选中了一张");
    CGPoint point = [tapGesture locationInView:self.collectionView];
    _indexPath = [self.collectionView indexPathForItemAtPoint:point];
    
    MTImageCell *cell = (MTImageCell *)[self.collectionView cellForItemAtIndexPath:_indexPath];
    //状态改变
    cell.currentChooseStatus = !cell.currentChooseStatus;
    
    // save Cell status
    [self.cellStatusDict setObject:@(cell.currentChooseStatus) forKey:_indexPath];
    
    if (cell.currentChooseStatus) {
        [self.selectionCellArray addObject:self.resultArray[_indexPath.row]];
        [self.selectionCells addObject:cell];
    }
    else {
        [self.selectionCellArray removeObject:self.resultArray[_indexPath.row]];
        [self.selectionCells removeObject:cell];
    }
}

//全选
- (void)chooseAllAction {
    
}

- (void)chooseBackAction {
    [self.navigationController popViewControllerAnimated:YES];
}

//移动图片 
- (void)moveImageTo {
    NSLog(@"移动");
    _moveFlag = YES;
    
    //用于移动弹出的相册选择界面
    self.moveNC = [[MTMoveChooseNC alloc] init];
    self.moveNC.sortTbaleVC.labelSet = self.sortTableViewSet;
    self.moveNC.sortTbaleVC.labelArr = self.sortTableViewArr;
    self.moveNC.sortTbaleVC.allInfoArray = self.resultArray;
    self.moveNC.sortTbaleVC.moveInfoArray = self.selectionCellArray;
    self.moveNC.sortTbaleVC.sourceLabel = self.itemCount;
    self.moveNC.sortTbaleVC.currentCVC = self;
    [self presentViewController:self.moveNC animated:YES completion:nil];
}

- (void)deleteImage {
    NSLog(@"删除");
    NSMutableArray *arrar = [[NSMutableArray alloc] initWithArray:self.resultArray];
    for (NSString *imageName in self.selectionCellArray) {
        [arrar removeObject:imageName];
    }
    self.resultArray = arrar;
    [self.collectionView reloadData];
    [self cancleChoose];
    
    //删除选中
    __block NSMutableArray *moveArray = [NSMutableArray array];
    [self.selectionCellArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        RLMResults *results = [MTImageModel objectsWhere:@"imageName = %@", obj];
        MTImageModel *model = [results firstObject];
        NSArray *info = [NSKeyedUnarchiver unarchiveObjectWithData:model.boxesFeatures];
        
        NSDictionary *labeDict = [info[0] lastObject];
        NSDictionary *moveDict = @{@"SourceLabel": labeDict[@"label"],
                                   @"TargetLabel": @(-3),
                                   @"ImageSet_id": obj};
        [moveArray addObject:moveDict];
        NSLog(@"moveArray = %@", moveArray);
    }];
    
    [self.uploadManager POSTMoveInfo:@{@"ImageSet": moveArray} completion:^(NSArray *info) {
        [self.modelManager updateJpgDataWithGetArray:info completion:^{
            self.selectionCellArray = nil;
        }];
    } failure:^(NSError *error) {
        self.selectionCellArray = nil;
    }];
    
    if ([self.delegate respondsToSelector:@selector(sortCollectionViewControllerDeleteImageIsChoose:)]) {
        [self.delegate sortCollectionViewControllerDeleteImageIsChoose:self];
    }
}

#pragma mark Getter/Setter

- (UITapGestureRecognizer *)tapGesture {
    if (!_tapGesture) {
        _tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapCollectionViewCell:)];
    }
    return _tapGesture;
}

- (NSMutableArray *)selectionCellArray {
    if (!_selectionCellArray) {
        _selectionCellArray = [[NSMutableArray alloc] init];
    }
    return _selectionCellArray;
}

- (NSMutableArray *)selectionCells {
    if (!_selectionCells) {
        _selectionCells = [[NSMutableArray alloc] init];
    }
    return _selectionCells;
}

- (UIView *)bottomFuncView {
    if (!_bottomFuncView) {
        CGFloat height = self.view.window.frame.size.height;
        CGFloat width = self.view.window.frame.size.width;
        
        _bottomFuncView = [[UIView alloc] initWithFrame:CGRectMake(0, (15 * height) / 16, width, height / 16)];
        
        UIButton *shareBtn = [[UIButton alloc] initWithFrame:CGRectMake(0,
                                                                        0,
                                                                        width / 3,
                                                                        _bottomFuncView.frame.size.height)];
        
        UIButton *moveBtn = [[UIButton alloc] initWithFrame:CGRectMake(shareBtn.frame.size.width,
                                                                       0,
                                                                       width / 3,
                                                                       _bottomFuncView.frame.size.height)];
        
        UIButton *deleteBtn = [[UIButton alloc] initWithFrame:CGRectMake(shareBtn.frame.size.width * 2,
                                                                         0,
                                                                         width / 3,
                                                                         _bottomFuncView.frame.size.height)];
        [shareBtn setTitle:@"分享" forState:UIControlStateNormal];
        [shareBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        
        [moveBtn setTitle:@"移动到" forState:UIControlStateNormal];
        [moveBtn addTarget:self action:@selector(moveImageTo) forControlEvents:UIControlEventTouchUpInside];
        [moveBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        
        [deleteBtn setTitle:@"删除" forState:UIControlStateNormal];
        [deleteBtn addTarget:self action:@selector(deleteImage) forControlEvents:UIControlEventTouchUpInside];
        [deleteBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        
        [_bottomFuncView addSubview:shareBtn];
        [_bottomFuncView addSubview:moveBtn];
        [_bottomFuncView addSubview:deleteBtn];
        
        _bottomFuncView.backgroundColor = [UIColor grayColor];
    }
    return _bottomFuncView;
}

- (UILabel *)naviLabel {
    if (!_naviLabel) {
        _naviLabel = [[UILabel alloc] init];
        _naviLabel.text = [NSString stringWithFormat:@"Label %d", self.itemCount];
        _naviLabel.textColor = [UIColor whiteColor];
        [_naviLabel sizeToFit];
    }
    return _naviLabel;
}

- (MTUploadManager *)uploadManager {
    if (!_uploadManager) {
        _uploadManager = [[MTUploadManager alloc] init];
    }
    return _uploadManager;
}

- (MTImageModelManager *)modelManager {
    if (!_modelManager) {
        _modelManager = [[MTImageModelManager alloc] init];
    }
    return _modelManager;
}

@end
