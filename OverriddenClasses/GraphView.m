//
//  GraphView.m
//  ThisWifiSucks
//
//  Created by Ryan Berg on 12/15/13.
//  Copyright (c) 2013 Ryan Berg. All rights reserved.
//

#import "GraphView.h"

@implementation GraphView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}


- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(context, .6);
    CGContextSetStrokeColorWithColor(context, [[UIColor greenColor] CGColor]);
    CGContextBeginPath(context);
    CGContextMoveToPoint(context, 0, 50);
    CGContextAddLineToPoint(context, 50, 50);//mon
    CGContextAddLineToPoint(context, 100, 25);//tues
    CGContextAddLineToPoint(context, 150, 75);//wed
    CGContextAddLineToPoint(context, 200, 75);//thurs
    CGContextAddLineToPoint(context, 250, 50);//fri
    CGContextAddLineToPoint(context, 300, 25);//sat
    CGContextAddLineToPoint(context, 320, 50);//sun
    
    CGContextStrokePath(context);
}


@end
