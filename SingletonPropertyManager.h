//
//  SingletonPropertyManager.h
//  ThisWifiSucks
//
//  Created by Ryan Berg on 12/25/13.
//  Copyright (c) 2013 Ryan Berg. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SingletonPropertyManager : NSObject
{
    NSData *foursquareData;
}

@property(nonatomic)int foursquareData;

+(id)sharedPropertyManager;

@end
