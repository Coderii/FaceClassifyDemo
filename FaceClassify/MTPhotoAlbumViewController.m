//
//  MTPhotoAlbumViewController.m
//  MTPhotoLibrary
//
//  Created by JoyChiang on 15/6/20.
//  Copyright (c) 2015年 Meitu. All rights reserved.
//

#import "MTPhotoAssetsViewController.h"
#import "MTPhotoDetailViewController.h"
#import "MTPhotoAlbumViewController.h"
#import "MTImagePickerController.h"
#import "MTPhotoAlbumViewCell.h"
#import "MTPhotoAlbumState.h"
#import "UtilsDef.h"

NSString *const PhotoAlbumViewCellReuseIdentifier = @"PhotoAlbumViewCell";

@interface MTPhotoAlbumViewController () <UITableViewDelegate, UITableViewDataSource,MTPhotoLibraryChangeObserver>

@property (nonatomic, copy) void (^select)(MTPhotoAlbum *photoAlbum);

@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, strong) UIView *backgroundView;

@property (nonatomic, strong) MTPhotoAlbum *selectedAblum;

@property (nonatomic, strong) NSMutableArray *photoAlbums;


@end

@implementation MTPhotoAlbumViewController

- (void)dealloc
{
    [[MTPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        [[MTPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
        self.photoAlbums = [[MTPhotoLibrary sharedPhotoLibrary] photoAlbums];
    }
    return self;
}


- (instancetype)init
{
    if (self = [super init]) {
        [[MTPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
        self.photoAlbums = [[MTPhotoLibrary sharedPhotoLibrary] photoAlbums];
    }
    return self;
}



- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"Albums", nil);
    self.view.backgroundColor = [UIColor clearColor];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Back",)
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:self
                                                                            action:@selector(back:)];
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 228)
                                                  style:UITableViewStyleGrouped];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.rowHeight = kAlbumRowHeight;
    self.tableView.tableFooterView = [[UIView alloc] init];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    self.tableView.separatorColor = RGBAHEX(0xc9c9c9, 1.f);
    self.tableView.backgroundColor = RGBAHEX(0xffffff, 1.f);
    // 设置footerView大小为Zero（删除空白cell处的分割线）
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    // 设置headerView高度为0.1的UIView（group风格时，调整顶部section与导航栏的高度）
    self.tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.view.bounds.size.width, 0.01f)];
    [self.tableView registerClass:[MTPhotoAlbumViewCell class] forCellReuseIdentifier:PhotoAlbumViewCellReuseIdentifier];
    [self.view addSubview:self.tableView];
    
    self.backgroundView.alpha = 0;
    self.tableView.hidden = YES;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear: animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.currentSelectIndex inSection:0];
    [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionMiddle];
    
    [self enterTheStageWithCompletion:^{
        
    }];
}


+ (instancetype)presentFromViewController:(UIViewController *)viewController
                currentSelectedPhotoAlbum:(MTPhotoAlbum *)currentSelectedPhotoAlbum
                                   select:(void (^)(MTPhotoAlbum *))select dismissBlock:(DidDissmiss)block
{
    MTPhotoAlbumViewController *photoAlbumViewController = [[MTPhotoAlbumViewController alloc] init];
    photoAlbumViewController.select = select;
    photoAlbumViewController.dissmissBlock = block;
    
    [photoAlbumViewController willMoveToParentViewController:viewController];
    [photoAlbumViewController.view setFrame:viewController.navigationController.view.frame];
    [viewController.view addSubview:photoAlbumViewController.view];
    [viewController addChildViewController:photoAlbumViewController];
    [photoAlbumViewController didMoveToParentViewController:viewController];
    photoAlbumViewController.selectedAblum = currentSelectedPhotoAlbum;
    
    return photoAlbumViewController;
}


- (void)setSelectedAblum:(MTPhotoAlbum *)selectedAblum
{
    _selectedAblum = selectedAblum;
    
    [self refreshSeletedCellState];
}

- (void)setCurrentSelectIndex:(NSUInteger)currentSelectIndex
{
    _currentSelectIndex = currentSelectIndex;
    
    if (_currentSelectIndex > -1 && _currentSelectIndex < self.photoAlbums.count) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.currentSelectIndex inSection:0];
        [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    }
}

- (void)refreshSeletedCellState
{
    NSUInteger selectedIndex = 0;
    if (_selectedAblum) {
        selectedIndex =[self.photoAlbums indexOfObject:_selectedAblum];
        if (selectedIndex == NSNotFound) {
            selectedIndex = 0;
        }
    }
    [self setCurrentSelectIndex:selectedIndex];
}



- (void)dismiss
{
    __weak MTPhotoAlbumViewController *weakSelf = self;
    [self leaveTheStageWithCompletion:^{
        [weakSelf.view removeFromSuperview];
        [weakSelf removeFromParentViewController];
        if (_dissmissBlock) {
            _dissmissBlock();
        }
    }];
}

#pragma mark - Action

- (void)back:(id)sender
{
    if ([self.picker.delegate respondsToSelector:@selector(imagePickerControllerDidCancel:)]) {
        [self.picker.delegate imagePickerControllerDidCancel:self.picker];
    }
    else {
        [self.picker.navigationController popViewControllerAnimated:YES];
        [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    }
}

#pragma mark - Accessors

- (MTImagePickerController *)picker
{
    return (MTImagePickerController *)self.navigationController.parentViewController;
}

- (void)setPhotoAlbums:(NSMutableArray *)photoAlbums
{
    _photoAlbums = photoAlbums;
    
    [self.tableView reloadData];
    
    if (self.selectedAblum) {
        [self.photoAlbums enumerateObjectsUsingBlock:^(MTPhotoAlbum  *album, NSUInteger idx, BOOL * stop) {
            if ([album isEqual:self.selectedAblum]) {
                [self setCurrentSelectIndex:idx];
            }
        }];
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _photoAlbums.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MTPhotoAlbumViewCell *cell = [tableView dequeueReusableCellWithIdentifier:PhotoAlbumViewCellReuseIdentifier forIndexPath:indexPath];
    cell.photoAlbum = _photoAlbums[indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    if (self.select) {
        self.select(_photoAlbums[indexPath.row]);
    }
    self.selectedAblum = _photoAlbums[indexPath.row];
    
    [self dismiss];
}

#pragma mark - transition

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (self.select) {
        self.select(nil);
    }
    
    [self dismiss];
}

- (void)enterTheStageWithCompletion:(void (^)(void))completion
{
    self.tableView.transform = CGAffineTransformMakeTranslation(0, -CGRectGetHeight(self.tableView.frame));
    
    self.tableView.hidden = NO;
    
    [UIView animateWithDuration:0.25 animations:^{
        self.backgroundView.alpha = 1.0;
    } completion:^(BOOL finished) {
    }];
    
    [UIView animateWithDuration:0.8 delay:0 usingSpringWithDamping:0.6 initialSpringVelocity:1 options:0 animations:^{
        self.tableView.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        if (completion) {
            completion();
        }
    }];
}

- (void)leaveTheStageWithCompletion:(void (^)(void))completion
{
    [UIView animateWithDuration:0.3 animations:^{
        self.tableView.transform = CGAffineTransformMakeTranslation(0, -CGRectGetHeight(self.tableView.frame));
        self.backgroundView.alpha = .0;
    } completion:^(BOOL finished) {
        if (completion) {
            completion();
        }
    }];
}

- (UIView *)backgroundView
{
    if (!_backgroundView) {
        _backgroundView = [[UIView alloc] initWithFrame:self.view.bounds];
        _backgroundView.autoresizingMask = 0;
        _backgroundView.backgroundColor = [UIColor colorWithWhite:0 alpha:.5];
        [self.view insertSubview:_backgroundView atIndex:0];
    }
    return _backgroundView;
}


#pragma mark - MTPhotoLibraryChangeObserver

- (void)photoLibraryDidChange:(PHChange *)changeInstance
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
        [self refreshSeletedCellState];
    });
}

- (void)assetsLibraryDidChange:(NSNotification *)note
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.photoAlbums = [MTPhotoLibrary sharedPhotoLibrary].photoAlbums;
        [self.tableView reloadData];
        [self refreshSeletedCellState];
    });
}




@end
