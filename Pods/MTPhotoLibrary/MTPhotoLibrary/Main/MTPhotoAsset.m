//
//  MTPhotoAsset.m
//  MTPhotoLibrary
//
//  Created by JoyChiang on 15/6/20.
//  Copyright (c) 2015年 Meitu. All rights reserved.
//

#import "MTPhotoAsset.h"
#import "MTPhotoLibrary_Prefix.h"

@interface MTPhotoAsset ()
{
    ALAsset *_alAsset;
    PHAsset *_phAsset;
 
    UIImage *_thumbnailImage;
    
    BOOL _isInCloud;
    PHImageRequestID _isInCloudRequestID;

//    UIImage *_fullScreenImage;
//    UIImage *_fullResolutionImage;
    
    unsigned long long _fileSize;
    NSString *_fileNameExtension;
    NSString *_fileName;
    
    BOOL _hasGotInfo;
    NSMutableDictionary *_metaData;
    NSURL *_assetURL;
    NSString *_UTI;
    
    UIImageOrientation _orientation;
    
    BOOL _iOS8;
}

@property (nonatomic, assign) MTPhotoAssetMediaType mediaType;
@property (nonatomic, assign) NSTimeInterval duration;

@end

@interface MTPhotoAsset (ALAssetRepresentation)
/**
 *  针对ALAsset选取图片，原图尺寸太大造成崩溃的图片尺寸限制接口
 *
 *  @param assetRepresentation ALAsset的 assetRepresentation
 *  @param size                图片最大边长图
 *
 *  @return 图片
 */
- (UIImage *)thumbnailForAsset:(ALAssetRepresentation *)assetRepresentation maxPixelSize:(NSUInteger)size;

@end






@implementation MTPhotoAsset

- (void)dealloc
{
    
    if (_isInCloudRequestID > 0) {
        [[PHImageManager defaultManager] cancelImageRequest:_isInCloudRequestID];
        _isInCloudRequestID = PHInvalidImageRequestID;
    }
    
    [self reset];
}

- (void)commonInit
{
    [self reset];
}

- (void)reset
{
    _alAsset = nil;
    _phAsset = nil;
    
    _thumbnailImage = nil;
    
    _isInCloud = NO;
    _isInCloudRequestID = PHInvalidImageRequestID;
    
    
    _fileSize = 0;
    _fileName = nil;
    _fileNameExtension = nil;
    
    _metaData = nil;
    _assetURL = nil;
    _UTI = nil;
    
    _hasGotInfo = NO;
    _orientation = UIImageOrientationUp;
    _iOS8 = SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO_8_0;
}



- (NSString *)fileName
{
    if (_fileName == nil) {
        [self getAssetFileName];
    }
    return _fileName;
}

- (void)getAssetFileName
{
    if (_iOS8) {
        PHAssetResource *resource = [[PHAssetResource assetResourcesForAsset:_phAsset] firstObject];
        if (resource) {
            _fileName = resource.originalFilename;
        }
        if (_fileName == nil) {
            _fileName = [_phAsset valueForKey:@"filename"];
        }
    }else {
        ALAssetRepresentation* representation = [_alAsset defaultRepresentation];//获取资源图片的名字
        _fileName = [representation filename];
    }
}

+ (MTPhotoAsset *)photoAssetWithALAsset:(ALAsset *)asset
{
    return [[MTPhotoAsset alloc] initWithALAsset:asset];
}

- (MTPhotoAsset *)initWithALAsset:(ALAsset *)asset
{
    if (self = [super init]) {
        
        [self commonInit];
        
        _alAsset = asset;
        
    }
    return self;
}

- (ALAsset *)asALAsset
{
    return _alAsset;
}

+ (MTPhotoAsset *)photoAssetWithPHAsset:(PHAsset *)asset
{
    return [[MTPhotoAsset alloc] initWithPHAsset:asset];
}

- (MTPhotoAsset *)initWithPHAsset:(PHAsset *)asset
{
    self = [super init];
    if (self) {
        
        [self commonInit];
        
        _phAsset = asset;
   
    }
    return self;
}

- (PHAsset *)asPHAsset
{
    return _phAsset;
}



- (BOOL)isEqualToAsset:(MTPhotoAsset *)photoAsset
{
    if (_iOS8) {
        return [[self asPHAsset] isEqual:[photoAsset asPHAsset]];
    }
    else {
        return [self.localIdentifier isEqualToString:photoAsset.localIdentifier];
    }
}

- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[MTPhotoAsset class]]) {
        MTPhotoAsset *photoAsset = object;
        if (_iOS8) {
            return [[self asPHAsset] isEqual:[photoAsset asPHAsset]];
        }
        else {
            return [self.localIdentifier isEqualToString:photoAsset.localIdentifier];
        }
    }
    return NO;
}

- (CGSize)dimensions
{
    if (_iOS8) {
        return CGSizeMake(_phAsset.pixelWidth, _phAsset.pixelHeight);
    }
    else {
        return _alAsset.defaultRepresentation.dimensions;
    }
}

enum {
    kAMASSETMETADATA_PENDINGREADS = 1,
    kAMASSETMETADATA_ALLFINISHED = 0
};

- (NSDictionary *)metadata
{
    if (!_metaData) {
        if (_iOS8) {
            if (PHAssetMediaTypeImage == _phAsset.mediaType) {
                PHImageRequestOptions *request = [PHImageRequestOptions new];
                request.version = PHImageRequestOptionsVersionCurrent;
                request.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
                request.resizeMode = PHImageRequestOptionsResizeModeNone;
                request.synchronous = YES;
                
                [[PHImageManager defaultManager] requestImageDataForAsset:_phAsset options:request resultHandler:^(NSData *imageData, NSString *dataUTI, UIImageOrientation orientation, NSDictionary *info) {
                    CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)imageData, NULL);
                    if (NULL != source) {
                        _metaData = (NSMutableDictionary *)CFBridgingRelease(CGImageSourceCopyPropertiesAtIndex(source, 0, NULL));
                        CFRelease(source);
                    }
                }];
            }
            else if (PHAssetMediaTypeVideo == _phAsset.mediaType) {
                PHVideoRequestOptions *request = [PHVideoRequestOptions new];
                request.deliveryMode = PHVideoRequestOptionsDeliveryModeAutomatic;
                request.version = PHVideoRequestOptionsVersionCurrent;
                
                NSConditionLock *assetReadLock = [[NSConditionLock alloc] initWithCondition:kAMASSETMETADATA_PENDINGREADS];
                [[PHImageManager defaultManager] requestPlayerItemForVideo:_phAsset options:request resultHandler:^(AVPlayerItem *playerItem, NSDictionary *info) {
                    
                    _metaData = [NSMutableDictionary dictionary];
                    NSArray *commonMetaData = playerItem.asset.commonMetadata;
                    for (AVMetadataItem *item in commonMetaData) {
                        _metaData[item.commonKey] = item.value;
                    }
                    
                    [assetReadLock lock];
                    [assetReadLock unlockWithCondition:kAMASSETMETADATA_ALLFINISHED];
                }];
                [assetReadLock lockWhenCondition:kAMASSETMETADATA_ALLFINISHED];
                [assetReadLock unlock];
                assetReadLock = nil;
            }
        }
        else {
            ALAssetRepresentation *defaultRep = _alAsset.defaultRepresentation;
            _metaData = [NSMutableDictionary dictionaryWithDictionary:defaultRep.metadata];
        }
    }
    return _metaData;
}

- (NSDate *)creationDate
{
    if (_iOS8) {
        return _phAsset.creationDate;
    }
    else {
        return [_alAsset valueForProperty:ALAssetPropertyDate];
    }
}

- (CLLocation *)location
{
    if (_iOS8) {
        return _phAsset.location;
    }
    else {
        return [_alAsset valueForProperty:ALAssetPropertyLocation];
    }
}

- (NSURL *)assetURL
{
    if (!_hasGotInfo) {
        [self getInfo];
    }
    return _assetURL;
}

- (unsigned long long)fileSize
{
    if (!_hasGotInfo) {
        [self getInfo];
    }
    return _fileSize;
}

- (NSString *)fileNameExtension
{
    if (!_hasGotInfo) {
        [self getInfo];
    }
    return _fileNameExtension;
}

- (UIImageOrientation)orientation
{
    if (!_hasGotInfo) {
        [self getInfo];
    }
    return _orientation;
}

- (NSString *)UTI
{
    if (!_hasGotInfo) {
        [self getInfo];
    }
    return _UTI;
}

- (MTPhotoAssetMediaType)mediaType
{
    if (_iOS8) {
        switch (_phAsset.mediaType) {
            case PHAssetMediaTypeImage:
                _mediaType = MTPhotoAssetMediaTypeImage;
                break;
            case PHAssetMediaTypeVideo:
                _mediaType = MTPhotoAssetMediaTypeVideo;
                break;
            case PHAssetMediaTypeAudio:
                _mediaType = MTPhotoAssetMediaTypeAudio;
                break;
            default:
                _mediaType = MTPhotoAssetMediaTypeUnknown;
                break;
        }
    }
    else {
        NSString *mediaType = [_alAsset valueForProperty:ALAssetPropertyType];
        if ([mediaType isEqualToString:ALAssetTypePhoto]) {
            _mediaType = MTPhotoAssetMediaTypeImage;
        }
        else if ([mediaType isEqualToString:ALAssetTypeVideo]) {
            _mediaType = MTPhotoAssetMediaTypeVideo;
        }
        else {
            _mediaType = MTPhotoAssetMediaTypeUnknown;
        }
    }
    return _mediaType;
}

- (NSTimeInterval)duration
{
    if (_alAsset) {
        if ([self mediaType] == MTPhotoAssetMediaTypeVideo) {
            return [[_alAsset valueForProperty:ALAssetPropertyDuration] doubleValue];
        }else {
            return 0.0f;
        }
    }
    else if (_phAsset) {
        if ([self mediaType] == MTPhotoAssetMediaTypeVideo) {
            return _phAsset.duration;
        }else {
            return 0.0f;
        }
    }
    else {
        return 0.0f;
    }
}

- (NSString *)localIdentifier
{
    if (_phAsset) {
        return _phAsset.localIdentifier;
    }
    else if (_alAsset)
    {
        return [[_alAsset valueForProperty:ALAssetPropertyAssetURL] absoluteString];
    }
    else
    {
        return nil;
    }
}

- (void)fetchAssetMIMEType:(void(^)(NSString *MIMEType))completion
{
    if (_alAsset) {
        ALAssetRepresentation *rep = [_alAsset defaultRepresentation];
        
        NSString *MIMEType = (__bridge_transfer NSString *)(UTTypeCopyPreferredTagWithClass((__bridge CFStringRef)([rep UTI]), kUTTagClassMIMEType));
        
        completion(MIMEType);
    }
    else if (_phAsset) {
        __block NSString *MIMEType = nil;
        [_phAsset requestContentEditingInputWithOptions:nil completionHandler:^(PHContentEditingInput *contentEditingInput, NSDictionary *info) {
            MIMEType = (__bridge_transfer NSString *)UTTypeCopyPreferredTagWithClass((__bridge CFStringRef)contentEditingInput.uniformTypeIdentifier, kUTTagClassMIMEType);
            
            completion(MIMEType);
        }];
    }
    else {
        completion(nil);
    }
}

- (UIImage *)thumbnail
{
    if (_thumbnailImage == nil) {
        if (_iOS8) {
            PHImageRequestOptions *request = [PHImageRequestOptions new];
            request.resizeMode = PHImageRequestOptionsResizeModeFast;
            request.deliveryMode = PHImageRequestOptionsDeliveryModeOpportunistic;
            request.version = PHImageRequestOptionsVersionCurrent;
            request.synchronous = YES;
            
            CGSize thumbsize = CGSizeMake(80*[UIScreen mainScreen].scale, 80*[UIScreen mainScreen].scale);
            CGFloat sx = thumbsize.width/self.dimensions.width;
            CGFloat sy = thumbsize.height/self.dimensions.height;
            BOOL isLargeImage = self.dimensions.width>5000 || self.dimensions.height > 5000;
            BOOL isLongImage = self.dimensions.width/self.dimensions.height > 5 || self.dimensions.height/self.dimensions.width > 5;
            if (isLargeImage && isLongImage) {
                sx = 80.0f/self.dimensions.width;
                sy = 80.0f/self.dimensions.height;
            }
            CGFloat s = MAX(sx, sy);
            thumbsize = CGSizeApplyAffineTransform(self.dimensions, CGAffineTransformMakeScale(s, s));
            [[PHImageManager defaultManager] requestImageForAsset:_phAsset targetSize:thumbsize contentMode:PHImageContentModeAspectFill options:request resultHandler:^(UIImage *result, NSDictionary *info) {
                _thumbnailImage = result;
            }];
        }
        else {
            _thumbnailImage = [UIImage imageWithCGImage:_alAsset.thumbnail];
        }
    }
    
    //如果取出来的缩略图是空的，则再取一次
    if (nil == _thumbnailImage) {
        if (_iOS8) {
            PHImageRequestOptions *request = [PHImageRequestOptions new];
            request.resizeMode = PHImageRequestOptionsResizeModeFast;
            request.deliveryMode = PHImageRequestOptionsDeliveryModeOpportunistic;
            request.version = PHImageRequestOptionsVersionCurrent;
            request.synchronous = YES;
            
            CGSize thumbsize = CGSizeMake(80*[UIScreen mainScreen].scale, 80*[UIScreen mainScreen].scale);
            CGFloat sx = thumbsize.width/self.dimensions.width;
            CGFloat sy = thumbsize.height/self.dimensions.height;
            BOOL isLargeImage = self.dimensions.width>5000 || self.dimensions.height > 5000;
            BOOL isLongImage = self.dimensions.width/self.dimensions.height > 5 || self.dimensions.height/self.dimensions.width > 5;
            if (isLargeImage && isLongImage) {
                sx = 80.0f/self.dimensions.width;
                sy = 80.0f/self.dimensions.height;
            }
            CGFloat s = MAX(sx, sy);
            thumbsize = CGSizeApplyAffineTransform(self.dimensions, CGAffineTransformMakeScale(s, s));
            [[PHImageManager defaultManager] requestImageForAsset:_phAsset targetSize:thumbsize contentMode:PHImageContentModeAspectFill options:request resultHandler:^(UIImage *result, NSDictionary *info) {
                if (nil != result) {
                    _thumbnailImage = result;
                }
            }];
        }
    }
    
    //fixBug 9.3系统在iPad mini 上无法获取缩略图
    if (nil == _thumbnailImage) {
        if (_iOS8) {
            PHImageRequestOptions *request = [PHImageRequestOptions new];
            request.resizeMode = PHImageRequestOptionsResizeModeFast;
            request.deliveryMode = PHImageRequestOptionsDeliveryModeOpportunistic;
            request.version = PHImageRequestOptionsVersionCurrent;
            request.synchronous = YES;
            
            CGSize thumbsize = CGSizeMake(80*[UIScreen mainScreen].scale, 80*[UIScreen mainScreen].scale);
            CGFloat sx = thumbsize.width/self.dimensions.width;
            CGFloat sy = thumbsize.height/self.dimensions.height;
            BOOL isLargeImage = self.dimensions.width>5000 || self.dimensions.height > 5000;
            BOOL isLongImage = self.dimensions.width/self.dimensions.height > 5 || self.dimensions.height/self.dimensions.width > 5;
            if (isLargeImage && isLongImage) {
                sx = 80.0f/self.dimensions.width;
                sy = 80.0f/self.dimensions.height;
            }
            // fixBug - 9.3系统在iPad mini 上无法获取缩略图 需修改获取尺寸
            CGFloat s = MAX(sx, sy)*2;
            thumbsize = CGSizeApplyAffineTransform(self.dimensions, CGAffineTransformMakeScale(s, s));
            [[PHImageManager defaultManager] requestImageForAsset:_phAsset targetSize:thumbsize contentMode:PHImageContentModeAspectFill options:request resultHandler:^(UIImage *result, NSDictionary *info) {
                if (nil != result) {
                    _thumbnailImage = result;
                }
            }];
        }
    }

    return _thumbnailImage;
}

- (UIImage *)fullScreenImage
{
    [self getInfo];

    
    __block UIImage *resultFullScreenImage = nil;
    
    if (_iOS8) {
        PHImageRequestOptions *request = [[PHImageRequestOptions alloc] init];
        request.resizeMode = PHImageRequestOptionsResizeModeExact;
        request.deliveryMode = PHImageRequestOptionsDeliveryModeOpportunistic;
        request.version = PHImageRequestOptionsVersionCurrent;
        request.synchronous = YES;
        
        CGFloat scale = [UIScreen mainScreen].scale;
        CGSize screenSize = [UIScreen mainScreen].bounds.size;
        screenSize.width *= scale;
        screenSize.height *= scale;
        [[PHImageManager defaultManager] requestImageForAsset:_phAsset
                                                   targetSize:screenSize
                                                  contentMode:PHImageContentModeAspectFit
                                                      options:request
                                                resultHandler:^(UIImage *result, NSDictionary *info) {
                                                    resultFullScreenImage = result;
                                                }
         ];
    }
    else {
        @autoreleasepool {
            ALAssetRepresentation *defaultAssetRep = _alAsset.defaultRepresentation;
            resultFullScreenImage = [UIImage imageWithCGImage:defaultAssetRep.fullScreenImage];
        }
    }
    return resultFullScreenImage;
}

- (UIImage *)fullResolutionImage
{
    [self getInfo];

    __block UIImage *resultFullResolutionImage = nil;
    
    if (_iOS8) {
        PHImageRequestOptions *request = [[PHImageRequestOptions alloc] init];
        request.resizeMode = PHImageRequestOptionsResizeModeNone;
        request.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
        request.version = PHImageRequestOptionsVersionCurrent;
        request.synchronous = YES;
        
        [[PHImageManager defaultManager] requestImageDataForAsset:_phAsset
                                                          options:request
                                                    resultHandler:^(NSData *imageData, NSString *dataUTI, UIImageOrientation orientation, NSDictionary *info) {
                                                        resultFullResolutionImage = [UIImage imageWithData:imageData];
                                                    }
         ];
    }
    else {
        @autoreleasepool {
            ALAssetRepresentation *defaultAssetRep = _alAsset.defaultRepresentation;
            
            // iOS7Bug: http://www.cnblogs.com/sohobloo/p/3988990.html
            NSString *adj = [defaultAssetRep metadata][@"AdjustmentXMP"];
            if (adj) {
                CGImageRef fullResImage = [defaultAssetRep fullResolutionImage];
                NSData *xmlData = [adj dataUsingEncoding:NSUTF8StringEncoding];
                CIImage *image = [CIImage imageWithCGImage:fullResImage];
                NSError *error = nil;
                NSArray *filters = [CIFilter filterArrayFromSerializedXMP:xmlData
                                                         inputImageExtent:[image extent]
                                                                    error:&error];
                CIContext *context = [CIContext contextWithOptions:nil];
                if (filters && !error) {
                    for (CIFilter *filter in filters) {
                        [filter setValue:image forKey:kCIInputImageKey];
                        image = [filter outputImage];
                    }
                    fullResImage = [context createCGImage:image fromRect:[image extent]];
                    resultFullResolutionImage = [UIImage imageWithCGImage:fullResImage
                                                          scale:[defaultAssetRep scale]
                                                    orientation:(UIImageOrientation)[defaultAssetRep orientation]];
                }
            } else {
                resultFullResolutionImage = [UIImage imageWithCGImage:defaultAssetRep.fullResolutionImage
                                                           scale:defaultAssetRep.scale
                                                     orientation:(UIImageOrientation)defaultAssetRep.orientation];               
            }

        }
    }
    return resultFullResolutionImage;
}

- (UIImage *)fullResolutionImageWithMaxLength:(CGFloat)maxLength {
    __block UIImage *resultFullResolutionImage = nil;
    if (_phAsset) {
        return [self fullResolutionImage];
    }
    else {
        [self getInfo];
        
        ALAssetRepresentation *defaultAssetRep = _alAsset.defaultRepresentation;
        NSString *adj = [defaultAssetRep metadata][@"AdjustmentXMP"];
        
        @autoreleasepool {
            if (adj) {
                resultFullResolutionImage = [self fullScreenImage];
            } else {
                resultFullResolutionImage = [self thumbnailForAsset:defaultAssetRep maxPixelSize:maxLength];
            }
            
        }
    }
    
    return resultFullResolutionImage;
}

    
- (UIImage *)fix_fullResolutionImageWithMaxLength:(CGFloat)maxLength {
        __block UIImage *resultFullResolutionImage = nil;
        if (_phAsset) {
                PHImageRequestOptions *request = [PHImageRequestOptions new];
                request.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
                request.resizeMode = PHImageRequestOptionsResizeModeExact;
                request.version = PHImageRequestOptionsVersionCurrent;
                request.networkAccessAllowed = NO;
                request.synchronous = YES;
        
                CGFloat ratio = maxLength / MAX(_phAsset.pixelWidth, _phAsset.pixelHeight);
                CGSize targetSize = CGSizeMake(_phAsset.pixelWidth * ratio,
                                               _phAsset.pixelHeight * ratio);
        
                [[PHImageManager defaultManager] requestImageForAsset:_phAsset targetSize:targetSize contentMode:PHImageContentModeDefault options:request resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
                    resultFullResolutionImage = result;
                }];
        }
        else {
            
            ALAssetRepresentation *defaultAssetRep = _alAsset.defaultRepresentation;
            NSString *adj = [defaultAssetRep metadata][@"AdjustmentXMP"];
            
            @autoreleasepool {
                if (adj) {
                    resultFullResolutionImage = [self fullScreenImage];
                } else {
                    resultFullResolutionImage = [self thumbnailForAsset:defaultAssetRep maxPixelSize:maxLength];
                }
                
            }
        }
        
        return resultFullResolutionImage;
    }

- (void)getInfo
{
    if (!_hasGotInfo) {
        _hasGotInfo = YES;
        if (_iOS8) {
            if (PHAssetMediaTypeImage == _phAsset.mediaType) {
                PHImageRequestOptions *request = [PHImageRequestOptions new];
                request.version = PHImageRequestOptionsVersionCurrent;
                request.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
                request.resizeMode = PHImageRequestOptionsResizeModeNone;
                request.synchronous = YES;
                
                [[PHImageManager defaultManager] requestImageDataForAsset:_phAsset
                                                                  options:request
                                                            resultHandler:^(NSData *imageData, NSString *dataUTI, UIImageOrientation orientation, NSDictionary *info) {
                                                                _fileSize = imageData.length;
                                                                _UTI = dataUTI;
//                                                                _assetURL = info[@"PHImageFileURLKey"];
                                                                NSRange range = [_phAsset.localIdentifier rangeOfString:@"/"];
                                                                NSString *UUID = [_phAsset.localIdentifier substringToIndex:range.location];
                                                                NSString *ALAssetURLStr = [NSString stringWithFormat:@"assets-library://asset/asset.JPG?id=%@&ext=JPG", UUID];
                                                                _assetURL = [NSURL URLWithString:ALAssetURLStr];
                                                                
                                                                _orientation = orientation;
                                                                
                                                                _fileNameExtension = (__bridge_transfer NSString *)UTTypeCopyPreferredTagWithClass((__bridge CFStringRef)_UTI, kUTTagClassFilenameExtension);
                                                            }
                 ];
            }
            else if (PHAssetMediaTypeVideo == _phAsset.mediaType) {
                PHVideoRequestOptions *request = [PHVideoRequestOptions new];
                request.deliveryMode = PHVideoRequestOptionsDeliveryModeAutomatic;
                request.version = PHVideoRequestOptionsVersionCurrent;
                
                NSConditionLock* assetReadLock = [[NSConditionLock alloc] initWithCondition:kAMASSETMETADATA_PENDINGREADS];
                [[PHImageManager defaultManager] requestPlayerItemForVideo:_phAsset options:request resultHandler:^(AVPlayerItem *playerItem, NSDictionary *info) {
                    
                    if ([playerItem.asset isKindOfClass:[AVComposition class]]) {
                        NSString *fileSandboxExtensionToken = info[@"PHImageFileSandboxExtensionTokenKey"];
                        NSString *filePath = [[fileSandboxExtensionToken componentsSeparatedByString:@";"] lastObject];
                        _assetURL = [NSURL fileURLWithPath:filePath];
                        NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:filePath];
                        _fileSize = [fileHandle seekToEndOfFile];
                        [fileHandle closeFile];
                        _UTI = CFBridgingRelease(UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)([_assetURL pathExtension]), NULL));
                        _fileNameExtension = (__bridge_transfer NSString *)UTTypeCopyPreferredTagWithClass((__bridge CFStringRef)CFBridgingRelease(UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)([_assetURL pathExtension]), NULL)), kUTTagClassFilenameExtension);
                    }
                    else if ([playerItem.asset isKindOfClass:[AVURLAsset class]]){
                        NSNumber *fileSize = nil;
                        AVURLAsset *urlAsset = (AVURLAsset *)playerItem.asset;
                        [urlAsset.URL getResourceValue:&fileSize forKey:NSURLFileSizeKey error:nil];
                        _fileSize = [fileSize unsignedLongLongValue];
                        _UTI = CFBridgingRelease(UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)([urlAsset.URL pathExtension]), NULL));
                        _assetURL = urlAsset.URL;
                        
                        _fileNameExtension = (__bridge_transfer NSString *)UTTypeCopyPreferredTagWithClass((__bridge CFStringRef)CFBridgingRelease(UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)([urlAsset.URL pathExtension]), NULL)), kUTTagClassFilenameExtension);
                    }
                    
                    [assetReadLock lock];
                    [assetReadLock unlockWithCondition:kAMASSETMETADATA_ALLFINISHED];
                }];
                [assetReadLock lockWhenCondition:kAMASSETMETADATA_ALLFINISHED];
                [assetReadLock unlock];
                assetReadLock = nil;
            }
        }
        else {
            ALAssetRepresentation *defaultRep = _alAsset.defaultRepresentation;
            _fileSize = defaultRep.size;
            _UTI = defaultRep.UTI;
            _assetURL = [_alAsset valueForProperty:ALAssetPropertyAssetURL];
            _orientation = (UIImageOrientation)_alAsset.defaultRepresentation.orientation;
            
            _fileNameExtension = (__bridge_transfer NSString *)(UTTypeCopyPreferredTagWithClass((__bridge CFStringRef)(_UTI), kUTTagClassFilenameExtension));
        }
    }
}


+ (void)fetchAsset:(MTPhotoAsset *)asset rawData:(void (^)(NSData *, NSURL *, ALAssetRepresentation *))result
{
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO_8_0) {
        if (MTPhotoAssetMediaTypeImage == asset.mediaType) {
            PHImageRequestOptions *request = [[PHImageRequestOptions alloc] init];
            request.resizeMode = PHImageRequestOptionsResizeModeNone;
            request.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
            request.version = PHImageRequestOptionsVersionCurrent;
            request.synchronous = NO;
            
            [[PHImageManager defaultManager] requestImageDataForAsset:asset.asPHAsset
                                                              options:request
                                                        resultHandler:^(NSData *imageData, NSString *dataUTI, UIImageOrientation orientation, NSDictionary *info) {
                                                            result(imageData, nil, nil);
                                                        }
             ];
        }
        else if (MTPhotoAssetMediaTypeVideo == asset.mediaType) {
            PHVideoRequestOptions *request = [[PHVideoRequestOptions alloc] init];
            request.deliveryMode = PHVideoRequestOptionsDeliveryModeAutomatic;
            request.version = PHVideoRequestOptionsVersionCurrent;
            
            [[PHImageManager defaultManager] requestPlayerItemForVideo:asset.asPHAsset
                                                               options:request
                                                         resultHandler:^(AVPlayerItem *playerItem, NSDictionary *info) {
                                                             AVURLAsset *urlAsset = (AVURLAsset *)playerItem.asset;
                                                             result(nil, urlAsset.URL, nil);
                                                         }
             ];
        }
    }
    else {
        result(nil, nil, asset.asALAsset.defaultRepresentation);
    }
}

- (void)requestJudgeIsAssetInCloud:(void (^)(BOOL flag))handler
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (_iOS8) {
            if (_phAsset.mediaType == PHAssetMediaTypeImage) {
                PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
                options.deliveryMode = PHImageRequestOptionsDeliveryModeFastFormat;
                
                _isInCloudRequestID = [[PHImageManager defaultManager] requestImageForAsset:_phAsset
                                                                                 targetSize:CGSizeMake(400, 400)
                                                                                contentMode:PHImageContentModeDefault
                                                                                    options:nil
                                                                              resultHandler:^(UIImage *result, NSDictionary *info) {
                                                                                  BOOL degraded = [info[PHImageResultIsDegradedKey] boolValue];
                                                                                  if (!degraded) {
                                                                                      if (result == nil && [info[@"PHImageResultIsInCloudKey"] boolValue]) {
                                                                                          if (handler) {
                                                                                              handler(YES);
                                                                                          }
                                                                                      } else {
                                                                                          if (handler) {
                                                                                              handler(NO);
                                                                                          }
                                                                                      }
                                                                                  }
                                                                              }];
            }
            else if (_phAsset.mediaType == PHAssetMediaTypeVideo) {
                PHVideoRequestOptions *options = [[PHVideoRequestOptions alloc] init];
                options.deliveryMode = PHVideoRequestOptionsDeliveryModeHighQualityFormat;
                
                _isInCloudRequestID = [[PHImageManager defaultManager] requestPlayerItemForVideo:_phAsset
                                                                                         options:options
                                                                                   resultHandler:^(AVPlayerItem *playerItem, NSDictionary *info) {
                                                                                       if (playerItem == nil) {
                                                                                           dispatch_async(dispatch_get_main_queue(), ^{
                                                                                               if (handler) {
                                                                                                   handler(YES);
                                                                                               }
                                                                                           });
                                                                                       } else {
                                                                                           dispatch_async(dispatch_get_main_queue(), ^{
                                                                                               if (handler) {
                                                                                                   handler(NO);
                                                                                               }
                                                                                           });
                                                                                       }
                                                                                   }];
            }
        }
    });
}

- (void)cancelRequestJudgeIsAssetInCloud
{
    if (_isInCloudRequestID !=  PHInvalidImageRequestID) {
        [[PHImageManager defaultManager] cancelImageRequest:_isInCloudRequestID];
        _isInCloudRequestID = PHInvalidImageRequestID;
    }
}



//--------------------------------------------------------------------------------------------------
// BugFix: invalid attempt to access ALAssetPrivate past the lifetime of its owning ALAssetsLibrary
// Reference: http://www.daveoncode.com/2011/10/15/solve-xcode-error-invalid-attempt-to-access-alassetprivate-past-the-lifetime-of-its-owning-alassetslibrary/
//--------------------------------------------------------------------------------------------------
+ (ALAssetsLibrary *)defaultAssetsLibrary {
    static dispatch_once_t pred = 0;
    static ALAssetsLibrary *library = nil;
    dispatch_once(&pred, ^{
        library = [[ALAssetsLibrary alloc] init];
    });
    return library;
}

+ (MTPhotoAsset *)fetchAssetWithLocalIdentifier:(NSString *)identifier
{
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO_8_0) {
        PHFetchOptions *fetchOptions = [[PHFetchOptions alloc] init];
        PHFetchResult *fetchResult = [PHAsset fetchAssetsWithLocalIdentifiers:@[identifier] options:fetchOptions];
        if ([fetchResult firstObject]) {
            return [MTPhotoAsset photoAssetWithPHAsset:[fetchResult firstObject]];
        }
        else
        {
            return nil;
        }
    }
    else {
        __block MTPhotoAsset *photoAsset = nil;
        
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0);
        dispatch_async(queue, ^{
            ALAssetsLibrary *assetLibrary = [[self class] defaultAssetsLibrary]; //[[ALAssetsLibrary alloc] init];
            [assetLibrary assetForURL:[NSURL URLWithString:identifier] resultBlock:^(ALAsset *asset) {
                photoAsset = [MTPhotoAsset photoAssetWithALAsset:asset];
                dispatch_semaphore_signal(sema);
                
            } failureBlock:^(NSError *error) {
                dispatch_semaphore_signal(sema);
            }];
        });
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
        return photoAsset;
    }
}

+ (NSArray<MTPhotoAsset *> *)fetchAssetsWithLocalIdentifiers:(NSArray *)identifiers {

    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO_8_0) {
        PHFetchOptions *fetchOptions = [[PHFetchOptions alloc] init];
        if (identifiers.count) {
            PHFetchResult *fetchResult = [PHAsset fetchAssetsWithLocalIdentifiers:identifiers options:fetchOptions];
            if ([fetchResult count]) {
                NSMutableArray *assetsArray = [NSMutableArray arrayWithCapacity:0];
                for (NSInteger i = 0; i< fetchResult.count; i++) {
                    [assetsArray addObject:[MTPhotoAsset photoAssetWithPHAsset:[fetchResult objectAtIndex:i]]];
                }
                return assetsArray;
            }
        }
        return nil;
    }
    else {
        __block NSMutableArray *assetsArray = [NSMutableArray arrayWithCapacity:0];
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0);
        dispatch_async(queue, ^{
            ALAssetsLibrary *assetLibrary = [[self class] defaultAssetsLibrary]; //[[ALAssetsLibrary alloc] init];
            
            for (NSInteger i = 0; i< identifiers.count; i++) {
                [assetLibrary assetForURL:[NSURL URLWithString:identifiers[i]] resultBlock:^(ALAsset *asset) {
                    [assetsArray addObject:[MTPhotoAsset photoAssetWithALAsset:asset]];
                } failureBlock:^(NSError *error) {
                    
                }];
            }
            dispatch_semaphore_signal(sema);
        });
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
        return assetsArray;
    }
}

@end


@implementation MTPhotoAsset (ALAssetRepresentation)

#pragma mark - 从相册数据中获取图片

- (UIImage *)thumbnailForAsset:(ALAssetRepresentation *)assetRepresentation maxPixelSize:(NSUInteger)size
{
    NSParameterAssert(assetRepresentation != nil);
    NSParameterAssert(size > 0);
    
    //    ALAssetRepresentation *rep = [asset defaultRepresentation];
    
    CGDataProviderDirectCallbacks callbacks =
    {
        .version = 0,
        .getBytePointer = NULL,
        .releaseBytePointer = NULL,
        .getBytesAtPosition = getAssetBytesCallback,
        .releaseInfo = releaseAssetCallback,
    };
    
    CGDataProviderRef provider = CGDataProviderCreateDirect((void *)CFBridgingRetain(assetRepresentation), [assetRepresentation size], &callbacks);
    
    CGImageSourceRef source = CGImageSourceCreateWithDataProvider(provider, NULL);
    
    CGImageRef imageRef = CGImageSourceCreateThumbnailAtIndex(source, 0, (__bridge CFDictionaryRef)
                                                              @{   (NSString *)kCGImageSourceCreateThumbnailFromImageAlways : @YES,
                                                                   (NSString *)kCGImageSourceThumbnailMaxPixelSize : [NSNumber numberWithUnsignedInteger:size],
                                                                   (NSString *)kCGImageSourceCreateThumbnailWithTransform : @YES,
                                                                   });
    
    if (source) {
        CFRelease(source);
    }
    if (provider) {
        CFRelease(provider);
    }
    
    if (!imageRef) {
        return nil;
    }
    
    UIImage *toReturn = [UIImage imageWithCGImage:imageRef];
    
    if (imageRef) {
        CFRelease(imageRef);
    }
    
    return toReturn;
}


// Helper methods for thumbnailForAsset:maxPixelSize:
static size_t getAssetBytesCallback(void *info, void *buffer, off_t position, size_t count)
{
    ALAssetRepresentation *rep = (__bridge id)info;
    
    NSError *error = nil;
    size_t countRead = [rep getBytes:(uint8_t *)buffer fromOffset:position length:count error:&error];
    
    if (countRead == 0 && error) {
        // We have no way of passing this info back to the caller, so we log it, at least.
        NSLog(@"thumbnailForAsset:maxPixelSize: got an error reading an asset: %@", error);
    }
    
    return countRead;
}


static void releaseAssetCallback(void *info)
{
    // The info here is an ALAssetRepresentation which we CFRetain in thumbnailForAsset:maxPixelSize:.
    // This release balances that retain.
    CFRelease(info);
}

@end


