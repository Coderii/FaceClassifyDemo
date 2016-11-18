//
//  MTMainViewController.m
//  FaceClassify
//
//  Created by Cheng on 16/8/26.
//  Copyright © 2016年 meitu. All rights reserved.
//

#import "MTMainViewController.h"
#import "MTImagePickerViewController.h"

@interface MTMainViewController ()

@property (weak, nonatomic) IBOutlet UISwitch *mySwitch;

- (IBAction)switchAction:(id)sender;
- (IBAction)uploadImage:(id)sender;

@end

@implementation MTMainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Switch Network

- (IBAction)switchAction:(id)sender {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setBool:self.mySwitch.on forKey:@"outOrInNetWorking"];
    [userDefaults synchronize];
}

- (IBAction)uploadImage:(id)sender {
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        MTImagePickerViewController *picker = [[MTImagePickerViewController alloc] init];
        [self presentViewController:picker animated:YES completion:nil];
    }
    else {
        NSLog(@"error");
    }
}

@end
