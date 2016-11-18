//
//  MTDemoViewController.m
//  FaceClassify
//
//  Created by meitu on 16/6/6.
//  Copyright © 2016年 meitu. All rights reserved.
//

#import "MTDemoViewController.h"

//数据库
#import <Realm/Realm.h>
//网络
#import "AFNetworking.h"
//进度
#import <MBProgressHUD.h>
//图片处理
#import "MTImageModel.h"
#import "UIImage+Extension.h"

#import "MTAssetModel.h"
//文件
#import "MTFileManager.h"
//图片网络处理
#import "MTNetworking.h"
//解压缩
#import "SSZipArchive.h"
//数据库管理类
#import "MTImageModelManager.h"

#import "MTImagePickerViewController.h"
#import "MTSortViewController.h"

#define getUrl @""
#define MAXUPLOADFILES 9999

@interface MTDemoViewController ()

- (IBAction)mapClick:(id)sender;
//- (IBAction)sortClick:(id)sender;
- (IBAction)clearData:(id)sender;
- (IBAction)getResult:(id)sender;

@property (weak, nonatomic) IBOutlet UIButton *resultButton;

@property (nonatomic, copy) NSString *resultPath;

@property (nonatomic, strong) NSOperationQueue *queue;

@property (nonatomic, strong) NSArray *modelArray;

@property (nonatomic, strong) UILabel *titleLabel;

@property (nonatomic, strong) MTFileManager *mtFileManager;

@property (nonatomic, strong) MTUploadManager *uploadManager;

@property (nonatomic, strong) MTImageModelManager *modelManager;

@property (weak, nonatomic) IBOutlet UISwitch *mySwitch;
- (IBAction)switchAction:(id)sender;

@end

static int countLog = 0;

@implementation MTDemoViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    
    //设置状态栏和导航栏
    [UIApplication sharedApplication].statusBarHidden = YES;
    
    self.navigationItem.titleView = self.titleLabel;
    self.navigationController.navigationBar.barTintColor = [UIColor purpleColor];
    
    //创建工程需要的目录
    [self.mtFileManager createDirectoryAtDocumentDirectory];
    
    // user defaults
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [self.mySwitch setOn:[userDefaults boolForKey:@"outOrInNetWorking"] animated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark 导图

- (IBAction)mapClick:(id)sender {
    NSLog(@"mapClick");
    countLog = 0;
    [self.mtFileManager clearTempDirectory];
    
    if ([UIImagePickerController isSourceTypeAvailable: UIImagePickerControllerSourceTypePhotoLibrary]) {
        MTImagePickerViewController *picker = [[MTImagePickerViewController alloc] init];
        
        //返回选中的原图
        __weak typeof(self) weakSelf = self;
        [picker setDidFinishSelectAssetModels:^(NSArray *modelArr) {
            self.modelArray = modelArr;
            self.mtFileManager.writeFilesCount = modelArr.count;
            
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (strongSelf) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    //进度条
                    MBProgressHUD *progressHUD = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
                    progressHUD.mode = MBProgressHUDModeDeterminate;
                    progressHUD.label.text = @"正在解析图片数据...";
                    
                    for (MTAssetModel *model in modelArr) {
                        //取图
                        [strongSelf handleImageWithModel:model completion:^{
                            [MBProgressHUD HUDForView:self.navigationController.view].label.text = @"处理图片数据成功";
                            [[MBProgressHUD HUDForView:self.navigationController.view] hideAnimated:YES afterDelay:1.0];
                            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                //获取结果
                                [self getResult:nil];
                            });
                        } failure:^(NSError *error) {
                            [MBProgressHUD HUDForView:self.navigationController.view].label.text = error.domain;
                            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                [[MBProgressHUD HUDForView:self.navigationController.view] hideAnimated:YES];
                            });
                        }];
                    }
                });
            }
        }];
        
        [self presentViewController:picker animated:YES completion:nil];
    } else {
        NSLog(@"不支持");
    }
}

- (void)handleImageWithModel:(MTAssetModel *)model completion:(void(^)())completion failure:(void(^)(NSError *error))failure {
    NSLog(@"===%@", [NSThread currentThread]);
    [model getOriginImageCompletion:^(UIImage *originImage) {   //取图成功
        //写入临时目录
        [self.mtFileManager writeImageDataToFileWithModel:model image:originImage progress:nil completion:^{    //写入本地成功
            //网络请求
            [self requestNetworkCompletion:^() {  //请求网络成功
                //将temp目录数据移动到主目录中
                [self.mtFileManager moveItemAtTempDirectoryCompletion:^{    //清除临时缓存目录成功
                    if (completion) {
                        completion();
                    }
                } failure:^(NSError *error) {   //清除临时缓存目录失败
                    if (failure) {
                        failure(error);
                    }
                }];
            } failure:^(NSError *error) {   //请求网络失败
                if (failure) {
                    failure(error);
                }
            }];
            
        } failure:^(NSError *error) {   //写入本地数据失败
            if (failure) {
                failure(error);
            }
        }];
        
    } failure:^(NSError *error) {   //取图失败
        if (failure) {
            failure(error);
        }
    }];
}

- (void)requestNetworkCompletion:(void(^)())completion failure:(void(^)(NSError *error))failure {
    NSLog(@"POST请求");
    //单文件上传
    [self.uploadManager POSTJpgProgress:nil completion:^(NSArray *responseArray) {  //post JPG成功
        NSLog(@"responseArray = %@", responseArray);
        
        //写入数据库
        [self.modelManager writeDataToRealmWithResponseArray:responseArray];
        if (completion) {
            completion();
        }
    } failure:^(NSError *error) {   //post JPG失败
        if (failure) {
            failure(error);
        }
    }];
}

#pragma mark 结果

- (IBAction)getResult:(id)sender {
 
    RLMResults *results = [MTImageModel allObjects];
    
    if (results.count != 0) {
        MTImageModel *model = [results firstObject];
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        [userDefaults setObject:model.sessionId forKey:@"sessionID"];
        [userDefaults synchronize];
        
        MTSortViewController *sortVC = [[MTSortViewController alloc] init];   
        [self presentViewController:sortVC animated:YES completion:nil];
    }
}

- (IBAction)clearData:(id)sender {
    //清除sessionid
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:@"None" forKey:@"sessionID"];
    [userDefaults synchronize];
    
    //清空数据
    [self.mtFileManager removeItemAtDocumentDirectory];
    
    //清空数据库
    [self.modelManager clearRealmAllData];
}

#pragma mark Provate Methods

- (void)cancelWork {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[MBProgressHUD HUDForView:self.navigationController.view] hideAnimated:YES];
    });
}

#pragma mark - 懒加载

- (NSOperationQueue *)queue {
    if (!_queue) {
        _queue = [[NSOperationQueue alloc] init];
        _queue.maxConcurrentOperationCount = 5;
    }
    return _queue;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.text = @"实验室Demo";
        _titleLabel.textColor = [UIColor whiteColor];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        [_titleLabel sizeToFit]; 
    }
    return _titleLabel;
}

- (MTFileManager *)mtFileManager {
    if (!_mtFileManager) {
        _mtFileManager = [MTFileManager sharedSingleton];
    }
    return _mtFileManager;
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

- (dispatch_queue_t)progrossQueue
{
    static dispatch_queue_t progrossQueue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        progrossQueue = dispatch_queue_create("myQueue", NULL/*DISPATCH_QUEUE_SERIAL*/);
    });
    return progrossQueue;
}

#pragma mark - 内外网选择

- (IBAction)switchAction:(id)sender {
    NSLog(@"---%@", @(self.mySwitch.on));
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setBool:self.mySwitch.on forKey:@"outOrInNetWorking"];
    [userDefaults synchronize];
}

@end
