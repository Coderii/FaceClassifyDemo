//
//  MTCommonData.h
//  FaceClassify
//
//  Created by Cheng on 16/7/27.
//  Copyright © 2016年 meitu. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifndef MTCommonData_h
#define MTCommonData_h

/** Demo初始化创建的各目录名称 */
static NSString *uploadZipName = @"upload.zip";
static NSString *faceClassifyPathName = @"FaceClassify";
static NSString *originImagePathName = @"FaceClassify/originImage";
static NSString *thumbnailPathName = @"FaceClassify/thumbnailImage";
static NSString *resultPathName = @"Result";
static NSString *zipPathName = @"Zip";
static NSString *zipTempPathName = @"Zip/temp"; /**< 解压的暂存目录  */
static NSString *tempOriginImagePathName = @"Temp/originImage";
static NSString *tempThumbnailPathName = @"Temp/thumbnailImage";

#define RGB(r,g,b)        [UIColor colorWithRed:r / 255.f green:g / 255.f blue:b / 255.f alpha:1.f]
#define RGBA(r,g,b,a)     [UIColor colorWithRed:r / 255.f green:g / 255.f blue:b / 255.f alpha:a]
#define RGBAHEX(hex,a)    RGBA((float)((hex & 0xFF0000) >> 16),(float)((hex & 0xFF00) >> 8),(float)(hex & 0xFF),a)

#endif /* MTCommonData_h */
