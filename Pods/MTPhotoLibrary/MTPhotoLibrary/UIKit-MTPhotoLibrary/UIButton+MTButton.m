//
//  UIButton+MTButton.m
//  MTImagePickerControllerDemo
//
//  Created by meitu on 16/7/14.
//  Copyright © 2016年 Meitu. All rights reserved.
//

#import "UIButton+MTButton.h"
#import <objc/runtime.h>
#import "MTPhotoLibrary_Prefix.h"


static char kMTButtonEventHandleKey;
@implementation UIButton (MTButton)

+ (instancetype)mt_createRecentImageButtonWithFrame:(CGRect)frame
                                             events:(UIControlEvents)controlEvents
                                       eventHandler:(MTButtonEventHandler)handler {
    
    
    NSAssert(!CGRectEqualToRect(frame, CGRectZero), @"frame 不能为CGRectZero");
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setFrame:frame];
    [button registerDidChangeObserver];
    [button displayRecentImage];
    [button events:controlEvents handler:handler];
    return button;
}


#pragma mark - Private Method

- (void)displayRecentImage{
    
    [[MTPhotoLibrary sharedPhotoLibrary] fetchRecentPhotoAsset:^(MTPhotoAsset *asset) {
        
            [self setImage:asset.thumbnail forState:UIControlStateNormal];
            [self setImage:asset.thumbnail forState:UIControlStateHighlighted];
    }];
}

- (void)events:(UIControlEvents)events handler:(MTButtonEventHandler)handler {
    
    objc_setAssociatedObject(self, &kMTButtonEventHandleKey, handler, OBJC_ASSOCIATION_COPY);
    [self addTarget:self action:@selector(didTapAction:) forControlEvents:events];
}

- (void)didTapAction:(UIButton *)button {
    
    MTButtonEventHandler handler = (MTButtonEventHandler)objc_getAssociatedObject(self, &kMTButtonEventHandleKey);
    if (handler) {
        handler(button);
    }
}

- (void)registerDidChangeObserver {
    
    [[MTPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
}

- (void)mt_removeObserver {
    
    [[MTPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];
}


#pragma mark - MTPhotoLibraryChangeObserver
-(void)photoLibraryDidChange:(PHChange *)changeInstance {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self displayRecentImage];
    });
}

- (void)assetsLibraryDidChange:(NSNotification *)note {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self displayRecentImage];
    });
}

@end
