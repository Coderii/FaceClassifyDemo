//
//  MTImageCell.m
//  FaceClassify
//
//  Created by meitu on 16/6/8.
//  Copyright © 2016年 meitu. All rights reserved.
//

#import "MTImageCell.h"
#import "MTFileManager.h"
#import "MTCommonData.h"

@interface MTLineView : UIView

@end


@implementation MTLineView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    
//    // 绘制人脸框
//    CGContextRef context = UIGraphicsGetCurrentContext();
//    CGContextSetLineCap(context, kCGLineCapSquare);
//    CGContextSetLineWidth(context, 3.0);
//    CGContextSetRGBStrokeColor(context, 1.0, 0.0, 0.0, 1.0);
//    
//    CGContextBeginPath(context);
//    CGContextMoveToPoint(context, 0, 0);
//    CGContextAddLineToPoint(context, rect.size.width, 0);
//    CGContextAddLineToPoint(context, rect.size.width, rect.size.height);
//    CGContextAddLineToPoint(context, 0, rect.size.height);
//    CGContextAddLineToPoint(context, 0, 0);
//    CGContextStrokePath(context);
}

@end

@interface MTImageCell()

@property (weak, nonatomic) IBOutlet UIImageView *imageview;

@property (nonatomic, strong) UIView *tapView;
@property (nonatomic, strong) UIImageView *selectionView;

@end

@implementation MTImageCell

- (void)prepareForReuse {
    [super prepareForReuse];
    
    for (UIView *view in self.imageview.subviews) {
        if ([view.class isSubclassOfClass:[MTLineView class]]) {
            [view removeFromSuperview];
        }
    }
}

- (void)awakeFromNib {
    [super awakeFromNib];
    self.imageview.frame = CGRectMake(0, 0, 120, 100);
}

- (void)setFaceMarkWith:(NSString *)imgName pointArray:(NSArray *)pointArray {
    for (NSDictionary *pointdict in pointArray) {
        if ([pointdict[@"imageName"] isEqualToString:imgName]) {
            
            NSString *pathDocuments = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
            
            NSString *imgPath = [originImagePathName stringByAppendingPathComponent:pointdict[@"imageName"]];
            
            NSString *imagePath = [pathDocuments stringByAppendingPathComponent:imgPath];
            UIImage *originImage = [UIImage imageWithContentsOfFile:imagePath];
            
            self.imageview.image = originImage;
            
            NSDictionary *dict = pointdict[@"points"]; 
            CGFloat markX = self.imageview.frame.size.width * [dict[@"x"] floatValue];
            CGFloat markY = self.imageview.frame.size.height * [dict[@"y"] floatValue];
            CGFloat markW = self.imageview.frame.size.width * [dict[@"w"] floatValue];
            CGFloat markH = self.imageview.frame.size.height * [dict[@"h"] floatValue];
            
            MTLineView *view0 = [[MTLineView alloc] initWithFrame:CGRectMake(markX, markY, markW, 1.0f)];
            view0.backgroundColor = [UIColor redColor];
            [self.imageview addSubview:view0];
            
            MTLineView *view1 = [[MTLineView alloc] initWithFrame:CGRectMake(markX + markW, markY, 1.0f, markH)];
            view1.backgroundColor = [UIColor redColor];
            [self.imageview addSubview:view1];
            
            MTLineView *view2 = [[MTLineView alloc] initWithFrame:CGRectMake(markX, markY + markH, markW, 1.0f)];
            view2.backgroundColor = [UIColor redColor];
            [self.imageview addSubview:view2];
            
            MTLineView *view3 = [[MTLineView alloc] initWithFrame:CGRectMake(markX, markY, 1.0f,markH)];
            view3.backgroundColor = [UIColor redColor];
            [self.imageview addSubview:view3];
        }

    }
}

//设置不同选择下cell的状态
- (void)setCurrentChooseStatus:(BOOL)currentChooseStatus {
    _currentChooseStatus = currentChooseStatus;
    
    //设置选中状态
    if (_currentChooseStatus) {
        self.tapView.backgroundColor = [UIColor lightGrayColor];
        [self.selectionView setHidden:NO];
    }
    else {
        self.tapView.backgroundColor = [UIColor clearColor];
        [self.selectionView setHidden:YES];
    }
}

#pragma mark Getter/Setter

- (UIView *)tapView { 
    if (!_tapView) {
        _tapView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.imageview.frame.size.width, self.imageview.frame.size.height)];
        _tapView.alpha = 0.5;
        [self.imageview addSubview:_tapView];
    }
    return _tapView;
}

- (UIImageView *)selectionView {
    if (!_selectionView) {
        _selectionView = [[UIImageView alloc] initWithFrame:CGRectMake(self.imageview.frame.size.width - 20, self.imageview.frame.size.height - 20, 20, 20)];
        _selectionView.image = [UIImage imageNamed:@"sg_seleted"];
        [self.imageview addSubview:_selectionView];
    }
    return _selectionView;
}
@end
