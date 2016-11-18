//
//  MTPhotoDetailScrollView.m
//  MTPhotoLibrary
//
//  Created by JoyChiang on 15/6/20.
//  Copyright (c) 2015年 Meitu. All rights reserved.
//

#import "MTPhotoDetailScrollView.h"
#import "MTPhotoDetailViewCell.h"
#import "CALayer+Animations.h"
#import "Masonry.h"

@interface MTPhotoDetailScrollView () <UIScrollViewDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, assign) CGSize cachingImageTargetSize;
@property (nonatomic, assign) MTImageRequestID requestID;
@property (nonatomic, assign) BOOL isInIcloud;

@property (nonatomic, strong) UIView *icloudDownLoadTipView;

@end

@implementation MTPhotoDetailScrollView

- (void)dealloc
{
    _imageView.image = nil;
}

#pragma mark - Init

- (instancetype)initWithDelegate:(id<MTAssetScrollViewDelegate>)delegate
{
    if (self = [self initWithFrame:CGRectZero]) {
        self.customDelegate = delegate;
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
    self.backgroundColor = [UIColor clearColor];
    self.showsHorizontalScrollIndicator = NO;
    self.showsVerticalScrollIndicator = NO;
    self.scrollEnabled = YES;
    self.bouncesZoom = YES;
    self.zoomScale = 1.0f;
    self.delegate = self;
    
    _cachingImageTargetSize = [UIScreen mainScreen].bounds.size;
    _cachingImageTargetSize.width *= [UIScreen mainScreen].scale;
    _cachingImageTargetSize.height *= [UIScreen mainScreen].scale;
    
    self.imageView = [[UIImageView alloc] init];
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.imageView.userInteractionEnabled = YES;
    self.imageView.autoresizingMask = 0x3F;
    
    UITapGestureRecognizer *doubleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                       action:@selector(handleTapGesture:)];
    doubleTapGesture.numberOfTouchesRequired = 1;
    doubleTapGesture.numberOfTapsRequired = 2;
    doubleTapGesture.delegate = self;
    [self.imageView addGestureRecognizer:doubleTapGesture];
    
    UITapGestureRecognizer *singleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                       action:@selector(handleTapGesture:)];
    singleTapGesture.numberOfTouchesRequired = 1;
    singleTapGesture.numberOfTapsRequired = 1;
    singleTapGesture.delegate = self;
    [singleTapGesture requireGestureRecognizerToFail:doubleTapGesture];
    [self addGestureRecognizer:singleTapGesture];
    
    [self addSubview:self.imageView];
    
    self.icloudDownLoadTipView = [[UIView alloc] init];
    self.icloudDownLoadTipView.backgroundColor = [UIColor whiteColor];
    self.icloudDownLoadTipView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:self.icloudDownLoadTipView];
    [self.icloudDownLoadTipView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self).with.insets(UIEdgeInsetsMake(44, 0, 60, 0));
    }];
    
    self.icloudDownLoadTipLabel = [[UILabel alloc] init];
    self.icloudDownLoadTipLabel.text = NSLocalizedString(@"iCloud云相册的照片，需要您先下载到系统相册，再重试哦～ ", nil);
    self.icloudDownLoadTipLabel.textColor = [UIColor blackColor];
    self.icloudDownLoadTipLabel.font = [UIFont systemFontOfSize:15.f];
    self.icloudDownLoadTipLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.icloudDownLoadTipLabel.numberOfLines = 0;
    [self.icloudDownLoadTipView addSubview:self.icloudDownLoadTipLabel];
    self.icloudDownLoadTipLabel.center = self.imageView.center;
    
    self.icloudDownLoadTipView.hidden = YES;
    
}

- (void)layoutSubviews
{
    [super layoutSubviews];
}

#pragma mark - Config Image

- (void)setPhotoAsset:(MTPhotoAsset *)photoAsset
{
    _photoAsset = photoAsset;
    
    __weak MTPhotoDetailScrollView *weakSelf = self;
    self.requestID = [self.imageManager requestImageForAsset:photoAsset
                                                  targetSize:_cachingImageTargetSize
                                                 contentMode:MTImageContentModeAspectFit
                                               resultHandler:^(UIImage *result, NSDictionary *info) {
                                                   self.requestID = PHInvalidImageRequestID;
                                                   if ([info[@"PHImageResultIsInCloudKey"] boolValue] && result == nil) {
                                                       weakSelf.isInIcloud = YES;
                                                       weakSelf.imageView.image = nil;
                                                       weakSelf.imageView.frame = CGRectMake(0, 44, weakSelf.bounds.size.width, weakSelf.bounds.size.height-106);
                                                       CGSize size = CGSizeMake([UIScreen mainScreen].bounds.size.width-60, 300);
                                                       weakSelf.icloudDownLoadTipLabel.bounds = [weakSelf.icloudDownLoadTipLabel.text boundingRectWithSize:size
                                                                                                                                           options:NSStringDrawingUsesLineFragmentOrigin
                                                                                                                                        attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:15.0f]}
                                                                                                                                           context:nil];
                                                       weakSelf.icloudDownLoadTipView.hidden = NO;
                                                       weakSelf.icloudDownLoadTipView.frame = CGRectMake(0, 44, weakSelf.bounds.size.width, weakSelf.bounds.size.height-106);
                                                       weakSelf.icloudDownLoadTipLabel.center = CGPointMake(weakSelf.imageView.bounds.size.width/2, weakSelf.imageView.bounds.size.height/2);
                                                   }
                                                   else
                                                   {
                                                       weakSelf.isInIcloud = NO;
                                                       weakSelf.icloudDownLoadTipView.hidden = YES;
                                                       [weakSelf.imageView.layer addAnimation:[CALayerAnimations animationChangeImageViewContent:AnimationEasyInOut] forKey:nil];
                                                       weakSelf.imageView.image = result;
                                                       [weakSelf fitImageViewFrameByImageSize:weakSelf.imageView.image.size
                                                                              centerPoint:weakSelf.center];
                                                   }
                                               }];
}

- (void)prepareForReuse
{
    if (self.requestID != PHInvalidImageRequestID) {
        [self.imageManager cancelImageRequest:self.requestID];
        self.requestID = PHInvalidImageRequestID;
    }
    
    self.imageView.image = nil;
    [self.imageView.layer removeAllAnimations];
}

- (UIImage *)image
{
    return self.imageView.image;
}

#pragma mark - Calculate ImageView frame

- (void)fitImageViewFrameByImageSize:(CGSize)size centerPoint:(CGPoint)center
{
    CGFloat imageWidth = size.width;
    CGFloat imageHeight = size.height;
    
    if (self.zoomScale != 1.0f) {
        [self zoomBackWithCenterPoint:center animated:NO];
    }
    
    CGFloat scale_max = 1.0f * 1.618f;
    CGFloat scale_mini = 1.0f;
    
    self.maximumZoomScale = 1.0f * 1.618f;
    self.minimumZoomScale = 1.0f;
    
    BOOL overWidth = imageWidth > self.bounds.size.width;
    BOOL overHeight = imageHeight > self.bounds.size.height;
    
    CGSize fitSize = CGSizeMake(imageWidth, imageHeight);
    
    if (overWidth && overHeight) {
        CGFloat timesThanScreenWidth = (imageWidth / self.bounds.size.width);
        if (!((imageHeight / timesThanScreenWidth) > self.bounds.size.height)) {
            scale_max =  timesThanScreenWidth * 1.618f;
            fitSize.width = self.bounds.size.width;
            fitSize.height = imageHeight / timesThanScreenWidth;
        } else {
            CGFloat timesThanScreenHeight = (imageHeight / self.bounds.size.height);
            scale_max =  timesThanScreenHeight * 1.618f;
            fitSize.width = imageWidth / timesThanScreenHeight;
            fitSize.height = self.bounds.size.height;
        }
    } else if (overWidth && !overHeight) {
        CGFloat timesThanFrameWidth = (imageWidth / self.bounds.size.width);
        scale_max =  timesThanFrameWidth * 1.618f;
        fitSize.width = self.bounds.size.width;
        fitSize.height = imageHeight / timesThanFrameWidth;
    } else if (overHeight && !overWidth) {
        fitSize.height = self.bounds.size.height;
    }
    
    self.imageView.frame = CGRectMake((center.x - fitSize.width / 2),
                                      (center.y - fitSize.height / 2),
                                      fitSize.width,
                                      fitSize.height);
    
    self.contentSize = CGSizeMake(fitSize.width, fitSize.height);
    
    self.maximumZoomScale = scale_max;
    self.minimumZoomScale = scale_mini;
}

#pragma mark - Scale

- (CGRect)zoomRectForScale:(CGFloat)scale withCenter:(CGPoint)center
{
    CGRect zoomRect;
    zoomRect.size.height = self.frame.size.height / scale;
    zoomRect.size.width  = self.frame.size.width  / scale;
    zoomRect.origin.x    = center.x - (zoomRect.size.width  / 2);
    zoomRect.origin.y    = center.y - (zoomRect.size.height / 2);
    
    return zoomRect;
}

#pragma mark - UIScrollViewDelegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.imageView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView
{
    CGFloat offsetX =
    (self.bounds.size.width > self.contentSize.width) ?
    (self.bounds.size.width - self.contentSize.width) * 0.5f : 0.0f;
    
    CGFloat offsetY =
    (self.bounds.size.height > self.contentSize.height)?
    (self.bounds.size.height - self.contentSize.height) * 0.5f : 0.0f;
    
    self.imageView.center = CGPointMake(self.contentSize.width * 0.5f + offsetX,
                                        self.contentSize.height * 0.5f + offsetY);
}

#pragma mark - Zoom Action

- (void)zoomBackWithCenterPoint:(CGPoint)center animated:(BOOL)animated
{
    CGRect rect = [self zoomRectForScale:1.0f withCenter:center];
    [self zoomToRect:rect animated:animated];
}

- (void)handleTapGesture:(UITapGestureRecognizer *)tapGesture
{ 
    if (tapGesture.numberOfTapsRequired == 2) {
        BOOL range_left = self.zoomScale > (self.maximumZoomScale * 0.9f);
        BOOL range_right = self.zoomScale <= self.maximumZoomScale;
        
        if (range_left && range_right) {
            CGRect rect = [self zoomRectForScale:self.minimumZoomScale
                                      withCenter:[tapGesture locationInView:tapGesture.view]];
            [self zoomToRect:rect animated:YES];
        } else {
            CGRect rect = [self zoomRectForScale:self.maximumZoomScale
                                      withCenter:[tapGesture locationInView:tapGesture.view]];
            [self zoomToRect:rect animated:YES];
        }
    } else if (tapGesture.numberOfTapsRequired == 1) {
        
    }
    
    if ([self.customDelegate respondsToSelector:@selector(scrollViewDidTap:numberOfTapsRequired:)]) {
        [self.customDelegate scrollViewDidTap:self numberOfTapsRequired:tapGesture.numberOfTapsRequired];
    }
}

@end
