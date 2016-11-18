//
//  AppDelegate.m
//  FaceClassify
//
//  Created by meitu on 16/6/6.
//  Copyright © 2016年 meitu. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate () {
    UIBackgroundTaskIdentifier bgTask;
}
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    //初始化sessionID
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:@"None" forKey:@"sessionID"];
    
    NSString *str = [userDefaults objectForKey:@"firstLanuch"];
    if (str.length == 0) {
        [userDefaults setObject:@"firstLanuchApp" forKey:@"firstLanuch"];
        [userDefaults setBool:YES forKey:@"outOrInNetWorking"];
        [userDefaults synchronize];
    }
    return YES;
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    bgTask = [application beginBackgroundTaskWithExpirationHandler:^{
        [application endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
    }];
    
    if (bgTask == UIBackgroundTaskInvalid) {
        NSLog(@"failed to start background task!");
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSTimeInterval timeRemain = 0;
       
        do {
            [NSThread sleepForTimeInterval:5];
            if (bgTask != UIBackgroundTaskInvalid) {
                timeRemain = [application backgroundTimeRemaining];
                NSLog(@"Time remaining: %f",timeRemain);
                
            }
        
        } while (bgTask!= UIBackgroundTaskInvalid && timeRemain > 0);
    });
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    if (bgTask != UIBackgroundTaskInvalid) {
        [application endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
    }
}
@end
