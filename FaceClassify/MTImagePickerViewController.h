//
//  MTImagePickerViewController.h
//  FaceClassify
//
//  Created by Cheng on 16/9/2.
//  Copyright © 2016年 meitu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MTPhotoAsset.h>

@protocol MTImagePickerViewControllerDelegate;

@interface MTImagePickerViewController : UIViewController

@property (nonatomic, weak) id<MTImagePickerViewControllerDelegate> delegate;

@end

@protocol MTImagePickerViewControllerDelegate <NSObject>

- (void)imagePickerController:(MTImagePickerViewController *)picker didFinishPickingPhotoAsset:(MTPhotoAsset *)photoAsset;

@end