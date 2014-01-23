//
//  AppDelegate.h
//  ThisWifiSucks
//
//  Created by file.open on 8/29/13.
//  Copyright (c) 2013 Ryan Berg. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>
{
    CLLocationManager *locationManager;
}

-(NSString *)readFileNamed:(NSString *)fileName;
-(void)saveFileNamed:(NSString *)fileName andFileData:(NSString *)stringData;

@property CLLocationManager *locationManager;
@property (strong, nonatomic) UIWindow *window;

@end
