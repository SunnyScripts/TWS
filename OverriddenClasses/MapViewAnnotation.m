//
//  MapViewAnnotation.m
//  ThisWifiSucks
//
//  Created by file.open on 9/1/13.
//  Copyright (c) 2013 Ryan Berg. All rights reserved.
//

#import "MapViewAnnotation.h"

@implementation MapViewAnnotation

@synthesize title, coordinate, subtitle, wifiRating;

- (id)initWithCoordinate:(CLLocationCoordinate2D)c2d withTitle:(NSString *)ttl withSubtitle:(NSString *)subttl withRating:(int)wifiRatng{
	title = ttl;
    subtitle = subttl;
	coordinate = c2d;
    wifiRating = wifiRatng;
	return self;
}

@end
