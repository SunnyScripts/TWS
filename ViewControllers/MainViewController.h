//
//  ViewController.h
//  ThisWifiSucks
//
//  Created by file.open on 8/29/13.
//  Copyright (c) 2013 Ryan Berg. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "TWS_CLController.h"



@interface ViewController : UIViewController <MKMapViewDelegate, UISearchBarDelegate>
{
    IBOutlet UITableView *mainTableView;
    NSMutableArray *pinArray;
    NSMutableArray *firebaseArray;
    NSMutableArray *addressArray;
    NSMutableArray *subViews;
    NSDictionary *yelpJSON;
    NSMutableData *data;
    //ViewController *viewController;
    NSString *clickedTitle;
    CLLocationManager *locationManager;
}

-(void)dismissModal;

@property(nonatomic,retain) NSMutableArray *pinArray;
@property(nonatomic, retain) NSMutableArray *firebaseArray;
@property(nonatomic, retain) NSMutableArray *addressArray;
@property(retain, nonatomic) IBOutlet MKMapView *mapView;
@property(strong, nonatomic) IBOutlet UILabel *howIsTheWifiLabel;
@property (strong, nonatomic) IBOutlet UITableView *mainTableView;
@property(nonatomic, retain) NSMutableArray *subViews;
//@property(nonatomic, retain) ViewController *viewController;
@property(nonatomic, copy) NSString *clickedTitle;

@property (strong, nonatomic) IBOutlet UIImageView *shareRatingImageView;
@property (strong, nonatomic) IBOutlet UIView *rateNavBarView;
@property (strong, nonatomic) IBOutlet UILabel *shareRatingLabel;
@property (strong, nonatomic) IBOutlet UIImageView *shareCategoryImageView;
@property (strong, nonatomic) IBOutlet UILabel *shareBusinessTitle;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (strong, nonatomic) IBOutlet UIButton *shareButton;

@property (strong, nonatomic) IBOutlet UILabel *tableViewResizer;
@property (strong, nonatomic) IBOutlet UISearchBar *searchBar;
@property (strong, nonatomic) IBOutlet UIButton *refreshButton;
@property (strong, nonatomic) IBOutlet UISegmentedControl *searchFilter;
@property (strong, nonatomic) IBOutlet UIButton *searchToggleButton;
@property (strong, nonatomic) IBOutlet UIButton *arrowGPS;


- (IBAction)Unbearable:(id)sender;
- (IBAction)Meh:(id)sender;
- (IBAction)SoGood:(id)sender;
- (IBAction)backPgOne:(id)sender;
- (IBAction)refresh:(id)sender;
- (IBAction)searchToggleButton:(id)sender;
- (IBAction)activateGPS:(id)sender;
- (IBAction)share:(id)sender;
- (IBAction)locationButton:(id)sender;
- (IBAction)infoButtonClicked:(id)sender;


@end
