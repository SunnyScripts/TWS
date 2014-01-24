//
//  MapViewAnnotation.h
//  ThisWifiSucks
//
//  Created by file.open on 9/1/13.
//  Copyright (c) 2013 Ryan Berg. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface MapViewAnnotation : NSObject <MKAnnotation>
{
    NSString *title;
    NSString *subtitle;
    CLLocationCoordinate2D coordinate;
    int wifiRating;
}

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *subtitle;
@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;
@property (readwrite, assign) int wifiRating;

- (id)initWithCoordinate:(CLLocationCoordinate2D)c2d withTitle:(NSString *)ttl withSubtitle:(NSString *)subttl withRating:(int)wifiRatng;

@end
