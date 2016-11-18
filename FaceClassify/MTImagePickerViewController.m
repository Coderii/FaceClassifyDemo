//
//  MTImagePickerViewController.m
//  FaceClassify
//
//  Created by Cheng on 16/9/2.
//  Copyright © 2016年 meitu. All rights reserved.
//

#import "MTImagePickerViewController.h"
#import "MTPhotoAssetsCollectionViewController.h"

@interface MTImagePickerViewController ()

@end

@implementation MTImagePickerViewController

#pragma mark - LifeCycle

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setupNavigationController];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Private Methods

- (void)setupNavigationController {
    MTPhotoAssetsCollectionViewController *albumViewController = [[MTPhotoAssetsCollectionViewController alloc] init];
    
    UINavigationController *inlineNavigationController = [[UINavigationController alloc] initWithRootViewController:albumViewController];
    [inlineNavigationController willMoveToParentViewController:self];
    [inlineNavigationController.view setFrame:self.view.frame];
    
    [self addChildViewController:inlineNavigationController];
    [inlineNavigationController didMoveToParentViewController:self];
}
@end
