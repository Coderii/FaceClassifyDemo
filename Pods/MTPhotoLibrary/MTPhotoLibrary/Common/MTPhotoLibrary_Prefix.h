//
//  MTPhotoLibrary_Prefix.h
//  MTImagePickerControllerDemo
//
//  Created by JoyChiang on 15/6/23.
//  Copyright (c) 2015年 Meitu. All rights reserved.
//

#ifndef COMPARE_SYSTEM_VERSION
#define COMPARE_SYSTEM_VERSION(v)    ([[[UIDevice currentDevice] systemVersion] compare:(v) options:NSNumericSearch])
#endif

#ifndef SYSTEM_VERSION_EQUAL_TO
#define SYSTEM_VERSION_EQUAL_TO(v)                  (COMPARE_SYSTEM_VERSION(v) == NSOrderedSame)
#endif

#ifndef SYSTEM_VERSION_GREATER_THAN
#define SYSTEM_VERSION_GREATER_THAN(v)              (COMPARE_SYSTEM_VERSION(v) == NSOrderedDescending)
#endif

#ifndef SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  (COMPARE_SYSTEM_VERSION(v) != NSOrderedAscending)
#endif

#ifndef SYSTEM_VERSION_LESS_THAN
#define SYSTEM_VERSION_LESS_THAN(v)                 (COMPARE_SYSTEM_VERSION(v) == NSOrderedAscending)
#endif

#ifndef SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     (COMPARE_SYSTEM_VERSION(v) != NSOrderedDescending)
#endif

#ifndef SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO_7_0
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO_7_0 (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0"))
#endif

#ifndef SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO_8_0
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO_8_0 (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0"))
#endif
