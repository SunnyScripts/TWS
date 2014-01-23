//
//  ViewController.m
//  ThisWifiSucks
//
//  Created by Ryan Berg on 8/29/13.
//
#import "ViewController.h"
#import <Firebase/Firebase.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>
#import "MapViewAnnotation.h"
#import "AnimatedUserLocation.h"//used for custom user location animated icon
#import "UIImage+PDF.h"
#import <Accelerate/Accelerate.h>
#import "GPUImage.h"
#import <OAuthConsumer/OAuthConsumer.h>
#import "InfoViewController.h"
#import "AppDelegate.h"
#import "ModalTableViewViewController.h"

#define METERS_PER_MILE 1609.344

typedef enum
{
    arts,airports,bookstores,churches,coffee,education,food,hostels,hotels,internetcafe,publicservicesgovt,restaurants,sharedofficespaces,stadiumsarenas,venues
    
}BusinessCategory;

typedef enum
{
    here, nearby, find
    
}SearchCategory;

@interface ViewController()
{
    CLGeocoder *_geocoder;
    UIImage* pinIcon;
    MapViewAnnotation *currentAnnotation;
    MapViewAnnotation *clickedAnnotation;
    CLLocationCoordinate2D coordinates;
    NSArray* businesses;
    NSArray* animationFrames;
    NSArray* categoryTypeArray;
    UIImageView *userLocationView;
    BOOL dismissedAlert;
    BOOL isOnShareView;
    MKMapView* mapView;
    UIImageView* blurView;
    UIView* mainView;
    UIImage* blurredImage;
    UIView* rateMiddleView;
    UIView* rateBottomView;
    UIView* shareBottomView;
    UIView* shareMiddleView;
    CLLocation* tempUserLocation;
    int halfScreenWidth;
    int halfScreenHeight;
    NSString *searchAddressString;
    NSString *searchBusinessNameString;
    BOOL isTitledName;
    BOOL wasShowMoreClicked;
    int reloadedData;
    BusinessCategory businessCategory;
    SearchCategory searchCategory;
    BOOL gpsWasClicked;
    int searchOffset;
    NSMutableArray* tableViewIndexPathArray;
    BOOL didRecieveHTTPResponse;
    NSMutableArray* businessArray;
    int clickedRow;
    int searchType;
    NSData* oldData;
    InfoViewController* infoViewController;
    ModalTableViewViewController* modalTableViewController;
}
@property CLGeocoder *geocoder;
@end


@implementation ViewController
{
    AppDelegate* delegate;
    CLLocation* currentLocation;
    CLLocationCoordinate2D* currentCoords;
    int userID;
}
@synthesize geocoder = _geocoder;
@synthesize mapView;
@synthesize pinArray;
@synthesize firebaseArray;
@synthesize addressArray;
@synthesize howIsTheWifiLabel;
@synthesize subViews; //forces subview to be held in memory
@synthesize clickedTitle;
//@synthesize viewController;
@synthesize mainTableView;
@synthesize shareRatingImageView;
@synthesize rateNavBarView;
@synthesize shareRatingLabel;
@synthesize shareCategoryImageView;
@synthesize shareBusinessTitle;
@synthesize searchBar;
@synthesize refreshButton;
@synthesize searchFilter;
@synthesize activityIndicator;
@synthesize arrowGPS;
//@synthesize navigationController;
@synthesize shareButton;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        userID = -1;
    }
    return self;
}


- (void)viewWillAppear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    [super viewWillAppear:animated];
}
-(void)viewWillDisappear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [super viewWillAppear:animated];
}
- (void)viewDidLoad
{
    
    [super viewDidLoad];
    
    
    if([self readFileNamed:@"userID"] == NULL)
    {
        NSLog(@"you are here");
        Firebase *dataRef = [[Firebase alloc] initWithUrl:@"https://thiswifisucks.firebaseio.com/usersList/numberOfUsers/"];
        [dataRef observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *numberOfUsers)
         {
             userID = [numberOfUsers.value intValue];
             [self writeFileNamed:@"userID" andFileData:[NSString stringWithFormat:@"%d", userID]];
             [dataRef setValue:@([numberOfUsers.value intValue] + 1)];
              NSLog(@"userID: %d", userID);
         }];
    }
    else
    {
        NSLog(@"you argh here");
        userID = [[self readFileNamed:@"userID"] intValue];
        NSLog(@"userID: %d", userID);
    }
    
    halfScreenWidth = [[UIScreen mainScreen]bounds].size.width*.5;
    halfScreenHeight = [[UIScreen mainScreen]bounds].size.height*.5;
    
    categoryTypeArray = @[@"arts",@"airports",@"bookstores",@"churches",@"coffee",@"education",@"food",@"hostels",@"hotels",@"internetcafe",@"publicservicesgovt",@"restaurants",@"sharedofficespaces",@"stadiumsarenas",@"venues"];
    
    infoViewController = [InfoViewController new];
    modalTableViewController = [ModalTableViewViewController new];
    
    
    self.subViews = [[NSMutableArray alloc] initWithCapacity:3];
    //self.viewController = [[ViewController alloc] init];
    userLocationView = [[UIImageView alloc] init];
    
	self.pinArray = [[NSMutableArray alloc] init];
	self.firebaseArray = [[NSMutableArray alloc] init];
    self.addressArray = [[NSMutableArray alloc] init];
    businessArray = [[NSMutableArray alloc] init];
    oldData = [[NSData alloc]init];
    
    dismissedAlert = NO;
    isOnShareView = NO;
    wasShowMoreClicked = NO;
    isTitledName = YES;
    gpsWasClicked = NO;
    didRecieveHTTPResponse = YES;
    activityIndicator.layer.cornerRadius = 5;
    searchOffset = 0;
    searchType = 3;
    
    clickedRow = -1;
    
    self.mapView.delegate = self;
    
    blurView = (UIImageView *)[self.view viewWithTag:20];
    rateBottomView = (UIImageView *)[self.view viewWithTag:-2];
    rateMiddleView = (UIImageView *)[self.view viewWithTag:-3];
    shareBottomView = (UIImageView *)[self.view viewWithTag:-4];
    shareMiddleView = (UIImageView *)[self.view viewWithTag:-5];
    
    mainView = (UIView *)[self.view viewWithTag:-1];
    [mainView setClipsToBounds:YES];
    
    
    UIButton *backButton = (UIButton *)[self.view viewWithTag:1];
    UIImage *backButtonImg = [UIImage imageWithPDFNamed:@"buttonBack.pdf" atHeight:backButton.bounds.size.height*.35];
    [backButton setImage:backButtonImg forState:UIControlStateNormal];
    
    UIButton *unbearableButton = (UIButton *)[self.view viewWithTag:2];
    UIImage *unbearableButtonImg = [UIImage imageWithPDFNamed:@"buttonUnbearable.pdf" atHeight:unbearableButton.bounds.size.height];
    [unbearableButton setImage:unbearableButtonImg forState:UIControlStateNormal];
    unbearableButton.layer.cornerRadius = 10;
    unbearableButton.clipsToBounds = YES;
    
    UIButton *mehButton = (UIButton *)[self.view viewWithTag:3];
    UIImage *mehButtonImg = [UIImage imageWithPDFNamed:@"buttonMeh.pdf" atHeight:mehButton.bounds.size.height];
    [mehButton setImage:mehButtonImg forState:UIControlStateNormal];
    mehButton.layer.cornerRadius = 10;
    mehButton.clipsToBounds = YES;
    
    UIButton *soGoodButton = (UIButton *)[self.view viewWithTag:4];
    UIImage *soGoodButtonImg = [UIImage imageWithPDFNamed:@"buttonSoGood.pdf" atHeight:soGoodButton.bounds.size.height];
    [soGoodButton setImage:soGoodButtonImg forState:UIControlStateNormal];
    soGoodButton.layer.cornerRadius = 10;
    soGoodButton.clipsToBounds = YES;
    
    UIImage *refreshButtonImg = [UIImage imageWithPDFNamed:@"refreshButton.pdf" atHeight:40];
    [refreshButton setImage:refreshButtonImg forState:UIControlStateNormal];
    refreshButton.clipsToBounds = YES;
    
    [arrowGPS setImage:[UIImage imageWithPDFNamed:@"arrowGPS.pdf" atHeight:arrowGPS.bounds.size.height] forState:UIControlStateNormal];
    arrowGPS.layer.cornerRadius = arrowGPS.bounds.size.width*.5;
    arrowGPS.clipsToBounds = YES;
    
    [shareButton setImage:[UIImage imageWithPDFNamed:@"share.pdf" atHeight:shareButton.bounds.size.height] forState:UIControlStateNormal];
    
    
    [searchFilter addTarget:self action:@selector(changedSearchFilter) forControlEvents:UIControlEventValueChanged];
    
    if(nil == locationManager)
    {
        locationManager = [[CLLocationManager alloc]init];
        locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers;
        //locationManager.distanceFilter = 10000;
        locationManager.activityType = CLActivityTypeFitness;
        
        
        NSLog(@"created location manager!");
        //[locationManager startUpdatingLocation];
    }
    
    [self yelpCall:searchOffset];
    //[rateView insertSubview:blurringView atIndex:100];
    /*
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"title CONTAINS[cd] %@", @"ington"];
    //cd is c = ignore case, d = ignore diactric (å)
    
    NSArray *filteredArray = [pinArray filteredArrayUsingPredicate:predicate];
    
    NSLog(@"%@", filteredArray);
    */
    
}


-(void)changedSearchFilter
{
    searchOffset = 0;
    [businessArray removeAllObjects];
    [self yelpCall:searchOffset];
}

-(void)searchBarTextDidBeginEditing:(UISearchBar *)_searchBar
{
    [UIView animateWithDuration:.5 animations:^
     {
         //[searchNavView setFrame:CGRectMake(searchNavView.bounds.origin.x, searchNavView.bounds.origin.y, halfScreenWidth*2, searchNavView.bounds.size.height)];
         //[searchBar setFrame:CGRectMake(searchBar.frame.origin.x, searchBar.frame.origin.y, halfScreenWidth*2, searchBar.bounds.size.height)];
         //[searchFilter setCenter:CGPointMake(halfScreenWidth, searchNavView.bounds.size.height+searchFilter.bounds.size.height*.5)];
     }];
}

-(void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    if(isTitledName)
        searchAddressString = @"";
    else
        searchBusinessNameString = @"";
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if(searchBar.isFirstResponder)
    {
        [UIView animateWithDuration:.3 animations:^
         {
             [searchBar setAlpha:0];
             [searchBar resignFirstResponder];
         }];
    }
}

-(void)searchBarSearchButtonClicked:(UISearchBar *)_searchBar
{
    if(isTitledName)
        searchAddressString = searchBar.text;
    else
        searchBusinessNameString = searchBar.text;
    
    [self yelpCall:searchOffset];
    
    [UIView animateWithDuration:.5 animations:^
     {
         
         
         //[searchFilter setCenter:CGPointMake(halfScreenWidth, searchNavView.bounds.size.height*.5)];
     }];
    
    [searchBar resignFirstResponder];
}

- (UIImage *)captureScreenInRect:(UIView *)captureView

{
    UIGraphicsBeginImageContextWithOptions(captureView.bounds.size,YES,[UIScreen mainScreen].scale);

    [captureView drawViewHierarchyInRect:captureView.bounds afterScreenUpdates:NO];
    UIImage *screenCapture = UIGraphicsGetImageFromCurrentImageContext();
    screenCapture = [self blurImage:screenCapture blurringRadius:4];
    
    UIGraphicsEndImageContext();

    return screenCapture;
}

- (UIImage *)blurImage:(UIImage *)sourceImage blurringRadius:(NSInteger)blurRadius
{
    GPUImageGaussianBlurFilter *blurFilter = [[GPUImageGaussianBlurFilter alloc] init];
    blurFilter.blurRadiusInPixels = blurRadius;
    return [blurFilter imageByFilteringImage:sourceImage];
}



/************TABLE VIEW****************/


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [businessArray count] +1;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
    }
    if([businessArray count] > 0 && indexPath.row < [businessArray count])
    {
        //TO DO:implementation of colored rows
        //cell.backgroundColor = [UIColor whiteColor];//alpha?
        NSDictionary* business = [businessArray objectAtIndex:indexPath.row];
        cell.textLabel.text = [business objectForKey:@"name"];
        
        //arts,airports,bookstores,churches,coffee,education, food,hostels,hotels,internetcafe,publicservicesgovt,restaurants,sharedofficespaces,stadiumsarenas,venues
        
        NSArray* categories = [business objectForKey:@"categories"];
        NSArray* categoryArray = categories[0];
        NSString* category = categoryArray[1];
        //int cellHeight = cell.imageView.bounds.size.height*.25;
        
        UIImage *cellImage;
        businessCategory = (int)[categoryTypeArray indexOfObject:category];
        
        switch(businessCategory)
        {
            case arts:
                cellImage = [UIImage imageWithPDFNamed:@"music.pdf" atHeight:15];
                [cellImage setAccessibilityIdentifier:@"music"];
                cell.imageView.image = cellImage;
                break;
            case airports:
                cellImage = [UIImage imageWithPDFNamed:@"airport.pdf" atHeight:15];
                [cellImage setAccessibilityIdentifier:@"airport"];
                cell.imageView.image = cellImage;
                break;
            case bookstores:
                cellImage = [UIImage imageWithPDFNamed:@"book.pdf" atHeight:15];
                [cellImage setAccessibilityIdentifier:@"book"];
                cell.imageView.image = cellImage;
                break;
            case churches:
                cellImage = [UIImage imageWithPDFNamed:@"church.pdf" atHeight:15];
                [cellImage setAccessibilityIdentifier:@"church"];
                cell.imageView.image = cellImage;
                break;
            case coffee:
                cellImage = [UIImage imageWithPDFNamed:@"coffee.pdf" atHeight:15];
                [cellImage setAccessibilityIdentifier:@"coffee"];
                cell.imageView.image = cellImage;
                break;
            case education:
                cellImage = [UIImage imageWithPDFNamed:@"education.pdf" atHeight:15];
                [cellImage setAccessibilityIdentifier:@"education"];
                cell.imageView.image = cellImage;
                break;
            case food:
                cellImage = [UIImage imageWithPDFNamed:@"restaurants.pdf" atHeight:15];
                [cellImage setAccessibilityIdentifier:@"restaurants"];
                cell.imageView.image = cellImage;
                break;
            case hostels:
                cellImage = [UIImage imageWithPDFNamed:@"hostel.pdf" atHeight:15];
                [cellImage setAccessibilityIdentifier:@"hostel"];
                cell.imageView.image = cellImage;
                break;
            case hotels:
                cellImage = [UIImage imageWithPDFNamed:@"hotel.pdf" atHeight:15];
                [cellImage setAccessibilityIdentifier:@"hotel"];
                cell.imageView.image = cellImage;
                break;
            case internetcafe:
                cellImage = [UIImage imageWithPDFNamed:@"laptop.pdf" atHeight:15];
                [cellImage setAccessibilityIdentifier:@"laptop"];
                cell.imageView.image = cellImage;
                break;
            case publicservicesgovt:
                cellImage = [UIImage imageWithPDFNamed:@"book.pdf" atHeight:15];
                [cellImage setAccessibilityIdentifier:@"book"];
                cell.imageView.image = cellImage;
                break;
            case restaurants:
                cellImage = [UIImage imageWithPDFNamed:@"restaurants.pdf" atHeight:15];
                [cellImage setAccessibilityIdentifier:@"restaurants"];
                cell.imageView.image = cellImage;
                break;
            case sharedofficespaces:
                cellImage = [UIImage imageWithPDFNamed:@"laptop.pdf" atHeight:15];
                [cellImage setAccessibilityIdentifier:@"laptop"];
                cell.imageView.image = cellImage;
                break;
            case stadiumsarenas:
                cellImage = [UIImage imageWithPDFNamed:@"venues.pdf" atHeight:15];
                [cellImage setAccessibilityIdentifier:@"venues"];
                cell.imageView.image = cellImage;
                break;
            case venues:
                cellImage = [UIImage imageWithPDFNamed:@"venues.pdf" atHeight:15];
                [cellImage setAccessibilityIdentifier:@"venues"];
                cell.imageView.image = cellImage;
                break;
            default:
                cellImage = [UIImage imageWithPDFNamed:@"defaultCategory.pdf" atHeight:15];
                [cellImage setAccessibilityIdentifier:@"defaultCategory"];
                cell.imageView.image = cellImage;
                break;
        }
    }
    else
    {
        cell.textLabel.text = @"Show More";
        //cell.imageView.image = [UIImage imageNamed:<#(NSString *)#>//:@"plus.pdf" //atHeight:15];
    }
    //[tableViewIndexPathArray addObject:[NSIndexPath indexPathForRow:indexPath.row inSection:indexPath.row]];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.row == [businessArray count])
    {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        if(searchBusinessNameString.length > 0 && !isTitledName)
        {
            searchOffset += 3;
        }
        else
        {
            searchOffset += 10;
        }
        wasShowMoreClicked = YES;
        [self yelpCall:searchOffset];
    }
    else
    {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
        clickedTitle = [tableView cellForRowAtIndexPath:indexPath].textLabel.text;
        howIsTheWifiLabel.text = [NSString stringWithFormat:@"So you're at\r%@\rHow's the wifi?", clickedTitle];
        
        clickedRow = (int)indexPath.row;
    
        blurredImage = [self captureScreenInRect:mapView];
        [blurView setImage:blurredImage];
        
        if([tableView cellForRowAtIndexPath:indexPath].imageView.image.accessibilityIdentifier.length > 0)
        {
            shareCategoryImageView.image = [UIImage imageWithPDFNamed:[NSString stringWithFormat:@"%@BG.pdf", [tableView cellForRowAtIndexPath:indexPath].imageView.image.accessibilityIdentifier] atHeight:shareCategoryImageView.bounds.size.height];
        }
        else
        {
            shareCategoryImageView.image = [UIImage imageWithPDFNamed:@"defaultCategoryBG.pdf" atHeight:shareCategoryImageView.bounds.size.height];;//set to default needed!!!!!!!!!!
        }
    
        [UIView animateWithDuration:.5 animations:^
         {
             [mainTableView setCenter:CGPointMake(mainTableView.center.x, halfScreenHeight*3)];
             [searchFilter setCenter:CGPointMake(halfScreenWidth, refreshButton.bounds.size.height*.5)];
             [activityIndicator setCenter:CGPointMake(halfScreenWidth, refreshButton.bounds.size.height*.5)];
         }completion:^(BOOL finished)
         {
             
         }];
    
        [UIView animateWithDuration:.4 delay:.2 options:UIViewAnimationOptionCurveLinear animations:^
         {
             [rateMiddleView setCenter:CGPointMake(halfScreenWidth, rateMiddleView.center.y)];
             [rateBottomView setCenter:CGPointMake(halfScreenWidth, rateBottomView.center.y)];
             [rateNavBarView setCenter:CGPointMake(halfScreenWidth, rateNavBarView.bounds.size.height*.5)];
             [blurView setAlpha:1];
         }completion:^(BOOL finished)
         {
             //[blurVie1w setContentMode:UIViewContentModeTopLeft];
         }];
    }
    
}

/*- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [NSString stringWithFormat:@"Wifi Near %@", location];
}*/


/************USER MOVING ACTION****************/


//mkusertrackingmode  track view to userLocation?
-(void)mapView:(MKMapView *)_mapView didFailToLocateUserWithError:(NSError *)error
{
    //to do
    NSLog(@"Can't find user: %@", error);
}
-(void)mapView:(MKMapView *)_mapView didSelectAnnotationView:(MKAnnotationView *)view
{//crashes here!!!!!!!
    [mainTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:[pinArray indexOfObject:view.annotation] inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
}
-(void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)_userLocation
{
    NSLog(@"updated user location");
    if(didRecieveHTTPResponse)
    {
        //[self yelpCall:searchOffset];
    }
}

-(void)centerMapView
{
    MKMapRect zoomRect = MKMapRectNull;
    for (id <MKAnnotation> annotation in mapView.annotations)
    {
        if(![annotation isKindOfClass:[MKUserLocation class]])
        {
            MKMapPoint annotationPoint = MKMapPointForCoordinate(annotation.coordinate);
            MKMapRect pointRect = MKMapRectMake(annotationPoint.x, annotationPoint.y, .1, .1);
            zoomRect = MKMapRectUnion(zoomRect, pointRect);
        }
    }
    [mapView setVisibleMapRect:zoomRect animated:YES];
}

-(void)yelpCall:(int)offset
{
    didRecieveHTTPResponse = NO;
    NSURL *url;
    NSString* category;
    
    [locationManager startUpdatingLocation];
    
    
    /*
    switch(searchFilter.selectedSegmentIndex)//what tab of the segmented controller are we on
    {{
        case here:
            
            //foursquare venues api, 5,000 queries/ hour without using OAuth
            url = [NSURL URLWithString:[NSString stringWithFormat:@"https://api.foursquare.com/v2/venues/search?client_id=4AS5WGWKSTRO1FRKWEQSICMSVQIJGP5F5LPSUT1SKGF5EFZJ&client_secret=1ONFG5JEFULGI1ASZLWON0FKQ01204BCDEYSYB4YOC54MEMD&v=20130815&ll=%f,%f&limit=10", locationManager.location.coordinate.latitude, locationManager.location.coordinate.longitude]];
        NSLog(@"url: %@", url);
        
            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:5];
            
            [request setHTTPMethod: @"GET"];
        
        
            NSError *requestError;
            NSURLResponse *urlResponse = nil;
            
            
        NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&urlResponse error:&requestError];//make async please!!!!!
        
        NSString *responseString = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
        NSLog(@"foursquare response: %@", responseString);
        
        
        //put response in dictionary for obj c use
        if(responseData)//you have internet connection
        {
            NSDictionary* jsonData = [NSJSONSerialization JSONObjectWithData:responseData options:kNilOptions error:nil];
            NSDictionary* responseObject = [jsonData objectForKey:@"response"];
            NSArray* venueArray = [responseObject objectForKey:@"venues"];
            NSDictionary* businessInfo = [venueArray objectAtIndex:0];
            NSString* name = [businessInfo objectForKey:@"name"];
            NSLog(@"business name %@", name);
            
            //do firebase stuff, ie get rating
            
            //use foursquare business coordinates!!!!!
            CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(locationManager.location.coordinate.latitude, locationManager.location.coordinate.longitude);
            MapViewAnnotation* _annotation = [[MapViewAnnotation alloc] initWithCoordinate:coordinate withTitle:name withSubtitle:@"" withRating:2];
            [mapView addAnnotation:_annotation];
            
            [self centerMapView];
        }
        else
        {
            NSLog(@"no response data :(, are you connected to internet?");
        }
        
        [locationManager stopUpdatingLocation];
        
    }
            break;
        case nearby:
     
            break;
        case find:
            break;
    }
    
    
    
    
    */
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    switch(searchCategory)
    {
        case 1:
            category = @"hotelstravel";
            break;
        case 2:
            category = @"food";
            break;
        case 0:
        default:
            category = @"";
            break;
    }
    
    NSLog(@"category: %@", category);
    
    
    /*
    if(searchAddressString.length > 0 && isTitledName)
    {
        if(searchType != 0)//make a typedef enum?
        {
            searchOffset = 0;
            [businessArray removeAllObjects];
        }
        url = [NSURL URLWithString:[[NSString stringWithFormat:@"http://api.yelp.com/v2/search?term=wifi&limit=10&location=%@&sort=1&category_filter=%@&offset=%d", searchAddressString, category, offset] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        NSLog(@"spot A: %@", url);
        searchType = 0;
    }
    else if(searchBusinessNameString.length > 0 && !isTitledName)
    {
        if(searchAddressString.length > 0)
        {
            if(searchType != 1)
            {
                searchOffset = 0;
                [businessArray removeAllObjects];
            }
            url = [NSURL URLWithString:[[NSString stringWithFormat:@"http://api.yelp.com/v2/search?term=%@&limit=2&location=%@&sort=0&category_filter=%@&offset=%d", searchBusinessNameString, searchAddressString, category, offset] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
            NSLog(@"spot B: %@", url);
            searchType = 1;
        }
        else
        {
            if(searchType != 2)
            {
                searchOffset = 0;
                [businessArray removeAllObjects];
            }
            url = [NSURL URLWithString:[[NSString stringWithFormat:@"http://api.yelp.com/v2/search?term=%@&ll=%f,%f&limit=2&sort=0&category_filter=%@&offset=%d", searchBusinessNameString, locationManager.location.coordinate.latitude, locationManager.location.coordinate.longitude, category, offset] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
            NSLog(@"spot C: %@", url);
            searchType = 2;
        }
    }
    else
    {
        if(searchType != 3)
        {
            searchOffset = 0;
            [businessArray removeAllObjects];
        }
        //url = [NSURL URLWithString:[NSString stringWithFormat:@"http://api.yelp.com/v2/search?term=wifi&limit=10&ll=%f,%f,%f&sort=1&category_filter=%@&offset=%d", locationManager.location.coordinate.latitude, locationManager.location.coordinate.longitude, ((locationManager.location.horizontalAccuracy + locationManager.location.verticalAccuracy) *.5), category, offset]];
        
       

        
        NSLog(@"spot D: %@", url);
        searchType = 3;
        
        //url = [NSURL URLWithString:[NSString stringWithFormat:@"https://www.googleapis.com/youtube/v3/channels?part=contentDetails&mine=true"]];
    
        
    }
    */
    /*remove old annotations*/
    /*
    if(!wasShowMoreClicked)
    {
        [mapView removeAnnotations:pinArray];
        [pinArray removeAllObjects];
        [businessArray removeAllObjects];
        NSLog(@"removing old annotations!");
    }
    else
    {
        wasShowMoreClicked = NO;
    }
    */
    /*
    OAConsumer *consumer = [[OAConsumer alloc]initWithKey:@"-07gQVKXURJ06Xlq9AYjkQ" secret:@"xCgF_Mj1NRsBzOWa3Djzf4tsuuk"];
    OAToken *token = [[OAToken alloc]initWithKey:@"qRiytysKrQezcF7cyzN43NpzJot13duw" secret:@"esJUgn8ndfXcLXDxATUN6_HB96w"];
    
    //id<OASignatureProviding, NSObject> provider = [[OAHMAC_SHA1SignatureProvider alloc]init];
    
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc] initWithURL:url consumer:consumer token:token realm:nil signatureProvider:nil];
    //[request prepare];
    //[data.];
    
    [request setHTTPMethod:@"GET"];
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [activityIndicator startAnimating];
    [UIView animateWithDuration:.5 animations:^
     {
         [activityIndicator setCenter:CGPointMake(halfScreenWidth, refreshButton.bounds.size.height+searchFilter.bounds.size.height+activityIndicator.bounds.size.height*.5)];
     }];
    
    OADataFetcher *fetcher = [[OADataFetcher alloc]init];
    [fetcher fetchDataWithRequest:request delegate:self didFinishSelector:@selector(requestTokenTicket:didFinishWithData:) didFailSelector:@selector(requestTokenTicket:didFailWithError:)];
    
    */
    
}

-(void)requestTokenTicket:(OAServiceTicket *)ticket didFailWithError:(NSData *)_data
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [activityIndicator stopAnimating];
    [UIView animateWithDuration:.5 animations:^
     {
         [activityIndicator setCenter:CGPointMake(halfScreenWidth, refreshButton.bounds.size.height)];
     }];
    NSLog(@"fail data: %@", _data);
    //NSString *responseBody = [[NSString alloc]initWithData:_data encoding:NSUTF8StringEncoding];
    didRecieveHTTPResponse = YES;
}

- (void)mapViewDidFinishLoadingMap:(MKMapView *)mapView
{
    //NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://api.yelp.com/business_review_search?term=wifi&lat=%f&long=%f&radius=1.5&limit=2&ywsid=zYc7ai2VYpLEZ6twERVDRA", locationManager.location.coordinate.latitude, locationManager.location.coordinate.longitude]]];
    //[NSURLConnection connectionWithRequest:request delegate:self];
    

}
-(void)mapViewDidFailLoadingMap:(MKMapView *)mapView withError:(NSError *)error
{
    
}
-(void)mapViewWillStartLocatingUser:(MKMapView *)mapView
{
    
}
-(void)mapViewDidStopLocatingUser:(MKMapView *)mapView
{
    
}

-(void)mapView:(MKMapView *)mapView didAddAnnotationViews:(NSArray *)views
{
    //NSLog(@"lum");
    //[self.mapView showAnnotations:self.mapView.annotations animated:YES];
    //[self.mapView setVisibleMapRect:MKMapRectMake(self.mapView.annotationVisibleRect.origin.x, self.mapView.annotationVisibleRect.origin.y, self.mapView.annotationVisibleRect.size.width, self.mapView.annotationVisibleRect.size.height) animated:YES];
     //self.mapView.pitchEnabled = YES;
}


/************ANNOTATION VIEW****************/


- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(MapViewAnnotation *)annotation
{
    
    MKAnnotationView *annotationView = (MKAnnotationView *)[self.mapView dequeueReusableAnnotationViewWithIdentifier:@"viewIdentifier"];
	if(annotationView == nil)
	{
		annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"viewIdentifier"];
	}
    
    if([annotation isKindOfClass:[MKUserLocation class]])
    {
        //created annotation twice?????? fix this!
        annotationView = [[AnimatedUserLocation alloc] initWithAnnotation:annotation reuseIdentifier:@"viewIdentifier"];
        return annotationView;
       // return nil;
    }
    
    //new rating will be -1 0 and 1
	switch (annotation.wifiRating)
    {
        case 1:
             annotationView.image = [UIImage imageNamed:@"bad.png"];
            annotationView.frame = CGRectMake(0, 0, annotationView.image.size.width * .166, annotationView.image.size.height * .166);
            break;
        case 2:
            annotationView.image = [UIImage imageNamed:@"meh.png" ];
            annotationView.frame = CGRectMake(0, 0, annotationView.image.size.width * .166, annotationView.image.size.height * .166);
            break;
        case 3:
            annotationView.image = [UIImage imageNamed:@"soGood.png"];
            annotationView.frame = CGRectMake(0, 0, annotationView.image.size.width * .166, annotationView.image.size.height * .166);//.166 = 1/6 
            break;
        default:
            annotationView.image = [UIImage imageNamed:@"noRating.png"];
            break;
    }
    
    UIButton *rightButton   =   [UIButton buttonWithType:UIButtonTypeCustom];
    rightButton.frame       =   CGRectMake(0, 0, 50, 30);
    [rightButton setBackgroundColor:[UIColor blueColor]];//:@"Info!" forState:UIControlStateNormal];
    
    annotationView.rightCalloutAccessoryView = rightButton;
    
    annotationView.canShowCallout = YES;
    
    return annotationView;
}



/************URL FUNCTIONS****************/

-(void)requestTokenTicket:(OAServiceTicket *)ticket didFinishWithData:(NSData *)_data
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [activityIndicator stopAnimating];
    [UIView animateWithDuration:.5 animations:^
     {
         [activityIndicator setCenter:CGPointMake(halfScreenWidth, refreshButton.bounds.size.height)];
     }];
    NSString *responseBody = [[NSString alloc]initWithData:_data encoding:NSUTF8StringEncoding];
    
    NSLog(@"Data Retrieved: %@", responseBody);
    

    if(oldData != _data)
    {
        yelpJSON = [NSJSONSerialization JSONObjectWithData:_data options:kNilOptions error:nil];//no error handling?
        businesses = [yelpJSON objectForKey:@"businesses"];
        [businessArray addObjectsFromArray:businesses];
        NSLog(@"new array: %@", businessArray);
        [mainTableView reloadData];
        reloadedData++;
        NSLog(@"loaded data: %d time(s)", reloadedData);
        [self runFirebase];
        oldData = _data;

    }
    didRecieveHTTPResponse = YES;
}


- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    data = [[NSMutableData alloc]init];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)newData
{
    if ([newData bytes] < 0)
    {
        NSLog(@"Connection error");
        [connection cancel];
        return;
    }
    [data appendData:newData];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{

    /*
    !!!!! I really suggest using a RESTful php server or node.js server for queries to ourself !!!!!
    
     
     */
}
-(void)runFirebase
{
    for (int i = 0; i < [businesses count]; i++)
    {
        NSDictionary* business = businesses[i];
        NSDictionary* location = [business objectForKey:@"location"];
        
        [addressArray insertObject:[NSString stringWithFormat:@"%@ %@ %@", [location objectForKey:@"address"], [location objectForKey:@"country_code"], [location objectForKey:@"postal_code"]] atIndex:i];
        [firebaseArray insertObject:[[NSString stringWithFormat:@"%@ %@", [business objectForKey:@"name"], addressArray[i]]stringByReplacingOccurrencesOfString:@"." withString:@" "] atIndex:i];
        
        NSLog(@"Firebase id: %@ at index%d",firebaseArray[i], i);
        
        //Firebase* rubySlippers = [[Firebase alloc] initWithUrl:([NSString stringWithFormat:@"https://thiswifisucks.firebaseio.com/businessList/%@", firebaseArray[i]])];//don't need to init this every iteration, once onLoad should be fine

        Firebase* title = [[Firebase alloc] initWithUrl:([NSString stringWithFormat:@"https://thiswifisucks.firebaseio.com/businessList/%@", firebaseArray[i]])];

        [title observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *titleSnap)
        {
            //check if business exists in firebase
            if(titleSnap.value == [NSNull null])
            {
                //get geolocation
                if(!self.geocoder)
                {
                    self.geocoder = [[CLGeocoder alloc] init];
                }
                [self.geocoder geocodeAddressString:addressArray[i] completionHandler:^(NSArray *placemarks, NSError *error) {
                    if ([placemarks count] > 0)
                    {
                        CLPlacemark *placemark = [placemarks objectAtIndex:0];
                        CLLocation *location = placemark.location;
                        CLLocationCoordinate2D coordinate = location.coordinate;
                        
                        
                        //set values to firebase
                        [title updateChildValues:@{@"ratingAvg": @(2), @"latitude": @(coordinate.latitude), @"longitude": @(coordinate.longitude), @"ratingCount": @(0)}];
                        
                        
                        //listen for changes
                        [title observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot)
                         {
                             //create annotation
                             currentAnnotation = [[MapViewAnnotation alloc] initWithCoordinate:coordinate withTitle:firebaseArray[i] withSubtitle:@"New" withRating:2];
  
                             //put annotation in mapView.annotations array
                             [self.pinArray addObject:currentAnnotation];
                             [self updateAnnotations];
                             
                             //update mapView
                             /*for (id<MKAnnotation> annotation in mapView.annotations)
                             {
                                 [mapView removeAnnotation:annotation];
                                 //update annotation image
                                 //clickedAnnotation.wifiRating = [snapshot.value intValue];
                                 [mapView addAnnotation:annotation];
                             }*/
                         }];
                    }
                    else
                    {
                        NSLog(@"invalid geolocation");
                    }
                }];
            }
            else
            {
                //check lat and long values once
                Firebase* latitude = [[Firebase alloc] initWithUrl:([NSString stringWithFormat:@"https://thiswifisucks.firebaseio.com/businessList/%@/latitude", firebaseArray[i]])];
                [latitude observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *latitudeSnap)
                 {
                     Firebase* longitude = [[Firebase alloc] initWithUrl:([NSString stringWithFormat:@"https://thiswifisucks.firebaseio.com/businessList/%@/longitude", firebaseArray[i]])];
                     [longitude observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *longitudeSnap)
                      {
                          //listen to rating value
                          Firebase* fRating = [[Firebase alloc] initWithUrl:([NSString stringWithFormat:@"https://thiswifisucks.firebaseio.com/businessList/%@/ratingAvg", firebaseArray[i]])];
                          [fRating observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *ratingAvg)
                           {
                               //create annotation//here
                               int rating;
                               if([ratingAvg.value intValue] >= 2.5)
                               {
                                   rating = 3;
                               }
                               else if([ratingAvg.value intValue] <= 1.5)
                               {
                                   rating = 1;
                               }
                               else
                                   rating = 2;
                               
                               currentAnnotation = [[MapViewAnnotation alloc] initWithCoordinate:(CLLocationCoordinate2DMake([latitudeSnap.value doubleValue], [longitudeSnap.value doubleValue])) withTitle:firebaseArray[i] withSubtitle:@"Old" withRating:rating];
                               NSLog(@"Old annotation Value changed!!");
                               [self.pinArray addObject:currentAnnotation];
                               [self updateAnnotations];
                           }];
                          [fRating observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *ratingSnap)
                           {
                               //add annotation to mapView
                               /*for (id<MKAnnotation> annotation in mapView.annotations)
                               {
                                   [mapView removeAnnotation:annotation];
                                   //update changed annotation
                                   [mapView addAnnotation:annotation];
                               }*/
                           }];
                      }];
                 }];
            }
        }];
                
    }
}

- (void)updateAnnotations
{
    
    
    //add new
    [mapView addAnnotations:pinArray];
    
    //set mapView view
    MKMapRect zoomRect = MKMapRectNull;
    for (id <MKAnnotation> annotation in mapView.annotations)
    {
        if(![annotation isKindOfClass:[MKUserLocation class]])
        {
            MKMapPoint annotationPoint = MKMapPointForCoordinate(annotation.coordinate);
            MKMapRect pointRect = MKMapRectMake(annotationPoint.x, annotationPoint.y, .1, .1);
            zoomRect = MKMapRectUnion(zoomRect, pointRect);
        }
    }
    [mapView setVisibleMapRect:zoomRect animated:YES];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    if(!dismissedAlert)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No Internet Connection" message:@"Many features of this app require an itnernet connection." delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil,nil];
        [alert show];
        dismissedAlert = YES;
    }
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [activityIndicator stopAnimating];
    [UIView animateWithDuration:.5 animations:^
     {
         [activityIndicator setCenter:CGPointMake(halfScreenWidth, refreshButton.bounds.size.height)];
     }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/************MAPKIT BUG****************/

//may not need this fix 

/*- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    // This is for a bug in MKMapView for iOS6
    [self purgeMapMemory];
}

// This is for a bug in MKMapView for iOS6
// Try to purge some of the memory being allocated by the map
- (void)purgeMapMemory
{
    // Switching map types causes cache purging, so switch to a different map type
    self.mapView.mapType = MKMapTypeStandard;
    [self.mapView removeFromSuperview];
    self.mapView = nil;
}*/
/************BUTTON ACTIONS****************/

- (IBAction)Unbearable:(id)sender
{
    if(clickedRow > -1)//did user click userLocation annotation?, //prevents adding method to stack if you don't even need it
    {
        [self ratedWifiWithRating:1 andLabel:@"This Wifi Sucks!"];
    }
}

- (IBAction)Meh:(id)sender
{

    if(clickedRow > -1)
    {
        [self ratedWifiWithRating:2 andLabel:@"Meh..."];
    }
}

- (IBAction)SoGood:(id)sender
{
   
    if(clickedRow > -1)
    {
        [self ratedWifiWithRating:3 andLabel:@"So Good!!"];
    }
    
}

-(void)ratedWifiWithRating:(int)rating andLabel:(NSString *)label
{
    Firebase *fRatingCount = [[Firebase alloc] initWithUrl:[NSString stringWithFormat:@"https://thiswifisucks.firebaseio.com/businessList/%@/ratingCount", [firebaseArray objectAtIndex:(uint)clickedRow]]];
    Firebase *fRatingAvg = [[Firebase alloc] initWithUrl:[NSString stringWithFormat:@"https://thiswifisucks.firebaseio.com/businessList/%@/ratingAvg", [firebaseArray objectAtIndex:(uint)clickedRow]]];
    Firebase *fUserRating = [[Firebase alloc] initWithUrl:[NSString stringWithFormat:@"https://thiswifisucks.firebaseio.com/businessList/%@/userRatings/%d", [firebaseArray objectAtIndex:(uint)clickedRow], userID]];
    Firebase* fBusinessName = [[Firebase alloc] initWithUrl:[NSString stringWithFormat:@"https://thiswifisucks.firebaseio.com/businessList/%@", [firebaseArray objectAtIndex:(uint)clickedRow]]];


    
    [fRatingCount observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *ratingCount)
     {
        [fRatingAvg observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *ratingAvg)
         {

                  [fUserRating observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *userRating)
                   {
                       if([ratingCount.value intValue] != 0)//don't want to divide by 0, the universe might implode or something :'(
                       {
                           float ratingSum = [ratingAvg.value floatValue] * [ratingCount.value intValue];//sum of all ratings

                           //int addCount = 0;
                           
                           if(userRating.value != [NSNull null])
                           {
                               ratingSum += rating - [userRating.value intValue];//subtract old rating, add new
                               [fUserRating setValue:@(rating)];
                           }
                           else//your first time voting here
                           {
                               [fBusinessName updateChildValues:@{@"userRatings": @{[NSString stringWithFormat:@"%d", userID]: @(rating)}}];
                               [fRatingCount setValue:@([ratingCount.value intValue] + 1)];
                           }
                           
                           if([ratingCount.value intValue] == 1)//there is a vote but it belongs to you
                           {
                               [fRatingAvg setValue:@(rating)];
                           }
                           else
                           {
                               [fRatingAvg setValue:@(ratingSum / (float)([ratingCount.value intValue]))];//the new average
                               NSLog(@"divide by: %@", @(([ratingCount.value intValue])));
                           }
                       }
                       else //you are the first to rate, therefor your rating is the new average
                       {
                           [fRatingCount setValue:@([ratingCount.value intValue] + 1)];
                           [fRatingAvg setValue:@(rating)];
                       }
                       
                   }];
         }];
     }];

    
    shareRatingImageView.image = [UIImage imageWithPDFNamed:@"buttonSoGood.pdf" atHeight:shareRatingImageView.bounds.size.height];//pass in your image value!!!!!
    shareRatingLabel.text = label;
    shareBusinessTitle.text = clickedTitle;
    
    [UIView animateWithDuration:.4 animations:^
     {
         [rateMiddleView setCenter:CGPointMake(halfScreenWidth*3, rateMiddleView.center.y)];
         [shareMiddleView setCenter:CGPointMake(halfScreenWidth, shareMiddleView.center.y)];
         [rateBottomView setCenter:CGPointMake(-halfScreenWidth, rateBottomView.center.y)];
         [shareBottomView setCenter:CGPointMake(halfScreenWidth, shareBottomView.center.y)];
     }completion:^(BOOL finished)
     {
         isOnShareView = YES;
     }];
}

- (IBAction)backPgOne:(id)sender
{
    if(isOnShareView)
    {
        [UIView animateWithDuration:.4 animations:^
         {
             [shareMiddleView setCenter:CGPointMake(-halfScreenWidth, shareMiddleView.center.y)];
             [rateNavBarView setCenter:CGPointMake(rateNavBarView.center.x, -rateNavBarView.bounds.size.height*.5)];
             [shareBottomView setCenter:CGPointMake(halfScreenWidth*3, shareBottomView.center.y)];
         }completion:^(BOOL finished)
         {
             isOnShareView = NO;
         }];
        [UIView animateWithDuration:.5 delay:.2 options:UIViewAnimationOptionCurveLinear animations:^
         {
             [blurView setAlpha:0];
             [mainTableView setCenter:CGPointMake(mainTableView.center.x, halfScreenHeight*2-mainTableView.bounds.size.height*.5)];
             [searchFilter setCenter:CGPointMake(halfScreenWidth, refreshButton.bounds.size.height+searchFilter.bounds.size.height*.5)];
             [activityIndicator setCenter:CGPointMake(halfScreenWidth, refreshButton.bounds.size.height-activityIndicator.bounds.size.height*.5)];
         }completion:^(BOOL finished){}];
    }
    else
    {
        [UIView animateWithDuration:.4 animations:^
         {
             [rateBottomView setCenter:CGPointMake(halfScreenWidth*3, rateBottomView.center.y)];
             [rateMiddleView setCenter:CGPointMake(-halfScreenWidth, rateMiddleView.center.y)];
             [rateNavBarView setCenter:CGPointMake(rateNavBarView.center.x, -rateNavBarView.bounds.size.height*.5)];
         }];
        [UIView animateWithDuration:.5 delay:.2 options:UIViewAnimationOptionCurveLinear animations:^
         {
             [blurView setAlpha:0];
             [mainTableView setCenter:CGPointMake(mainTableView.center.x, halfScreenHeight*2-mainTableView.bounds.size.height*.5)];
             [searchFilter setCenter:CGPointMake(halfScreenWidth, refreshButton.bounds.size.height+searchFilter.bounds.size.height*.5)];
         }completion:^(BOOL finished){}];
    }
}

- (IBAction)refresh:(id)sender
{
    dismissedAlert = NO;//?
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [activityIndicator startAnimating];
    [UIView animateWithDuration:.5 animations:^
     {
         [activityIndicator setCenter:CGPointMake(halfScreenWidth, refreshButton.bounds.size.height+searchFilter.bounds.size.height+activityIndicator.bounds.size.height*.5)];
     }];
    
    [self searchBarSearchButtonClicked:searchBar];
}

- (IBAction)searchToggleButton:(id)sender
{
    [UIView animateWithDuration:.3 animations:^
     {
         [searchBar setAlpha:1];
         [searchBar becomeFirstResponder];
     }];
    
    
    //[self presentModalViewController:infoViewController animated:YES];
    
    /*
    if(isTitledName)
    {
        searchAddressString = searchBar.text;
        searchBar.text = @"";
        //[searchToggleButton setTitle:@"Address" forState:UIControlStateNormal];
        [searchBar setPlaceholder:@"Business Lookup"];
        isTitledName = NO;
    }
    else
    {
        searchBusinessNameString = searchBar.text;
        searchBar.text = @"";
        //[searchToggleButton setTitle:@"Name" forState:UIControlStateNormal];
        [searchBar setPlaceholder:@"Address Lookup"];
        isTitledName = YES;
    }*/
}


- (IBAction)activateGPS:(id)sender
{
    [self centerMapView];
    /*
    if(gpsWasClicked)
    {
        arrowGPS.backgroundColor = [UIColor colorWithWhite:1 alpha:0];
        gpsWasClicked = NO;
    }
    else
    {
        arrowGPS.backgroundColor = [UIColor colorWithRed:.2784 green:.7451 blue:.686 alpha:1];
        gpsWasClicked = YES;
    }*/
}

- (IBAction)share:(id)sender
{
}

- (IBAction)locationButton:(id)sender
{
    [[self navigationController]presentModalViewController:modalTableViewController animated:YES];
}

- (IBAction)infoButtonClicked:(id)sender
{
    [[self navigationController]pushViewController:infoViewController animated:YES];
}

-(NSString *)readFileNamed:(NSString *)fileName
{
    NSError *error;
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    NSString *content = [[NSString alloc] initWithContentsOfFile:[documentsDirectory stringByAppendingPathComponent:fileName] encoding:NSUTF8StringEncoding error:&error];
    
    
    NSLog(@"the file reads: %@ and error: %@", content, error);
    
    return content;
}


-(void)writeFileNamed:(NSString *)fileName andFileData:(NSString *)stringData
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    NSError *error;
    
    NSLog(@"writing to path %@", [documentsDirectory stringByAppendingPathComponent:fileName]);
    BOOL didSucceed = [stringData writeToFile:[documentsDirectory stringByAppendingPathComponent:fileName] atomically:YES encoding:NSUTF8StringEncoding error:&error];
    NSLog(@"did the file write succeed?: %@", didSucceed ? @"YES" : @"NO");//condition ? result_if_true : result_if_false
    if(!didSucceed)
    {
        NSLog(@"file write error: %@", error);
    }
}




@end
