//
//  SingletonPropertyManager.m
//  ThisWifiSucks
//
//  Created by Ryan Berg on 12/25/13.
//  Copyright (c) 2013 Ryan Berg. All rights reserved.
//

#import "SingletonPropertyManager.h"

@implementation SingletonPropertyManager

+(id)sharedPropertyManager
{
    static SingletonPropertyManager *properyManager = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        properyManager = [SingletonPropertyManager new];
    });
    return properyManager;
}
-(id)init
{
    if(self = [super init])
    {
        foursquareData = nil;
    }
    return self;
}


@end
