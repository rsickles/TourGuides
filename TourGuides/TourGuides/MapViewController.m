//
//  MapViewController.m
//  TourGuides
//
//  Created by Ryan Sickles on 11/1/14.
//  Copyright (c) 2014 sickles.ryan. All rights reserved.
//

#import "MapViewController.h"
#import <CoreLocation/CoreLocation.h>
#import "MyLocation.h"
#import "HomeViewController.h"
#import <Parse/Parse.h>

@interface MapViewController ()

@end
#define METERS_PER_MILE 1609.344
@implementation MapViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.mapView.delegate = self;
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    self.locationManager = [[CLLocationManager alloc] init];
    [self.locationManager requestWhenInUseAuthorization];
    [self.locationManager requestAlwaysAuthorization];
    [self.locationManager startUpdatingLocation];
    self.searchBar = [[UISearchBar alloc] init];
    self.searchBar.delegate = self;
    self.searchBar.placeholder = @"Search For Location";
    self.searchBar.autocorrectionType = YES;
    self.mapView.showsUserLocation = YES;
    self.mapView.showsPointsOfInterest = YES;
}

- (void)viewDidAppear:(BOOL)animated {
    // 1
    // User's location
    [PFGeoPoint geoPointForCurrentLocationInBackground:^(PFGeoPoint *geoPoint, NSError *error) {
        if (!error) {
            // do something with the new geoPoint
            PFGeoPoint *userGeoPoint = geoPoint;
            // Create a query for places
            PFQuery *query = [PFQuery queryWithClassName:@"Location"];
            // Interested in locations near user.
            [query whereKey:@"location" nearGeoPoint:userGeoPoint withinMiles:10];
            // Limit what could be a lot of points.
            query.limit = 25;
            // Final list of objects
            [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                [self plotEventPositions:objects];
            }];
            MKPointAnnotation *currentLocation = [[MKPointAnnotation alloc] init];
            CLLocationCoordinate2D myCoordinate;
            myCoordinate.latitude=geoPoint.latitude;
            myCoordinate.longitude=geoPoint.longitude;
            currentLocation.coordinate = myCoordinate;
            MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(myCoordinate,
                                                                           800,
                                                                           800);
            MKCoordinateRegion adjusted_region = [self.mapView regionThatFits:region];
            [self.mapView setRegion:adjusted_region animated:YES];
        }
    }];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *) searchBar
{
    [searchBar resignFirstResponder];
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    [searchBar setShowsCancelButton:YES animated:YES];
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
    [searchBar setShowsCancelButton:NO animated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control {
    MyLocation *location = (MyLocation*)view.annotation;
    
    NSDictionary *launchOptions = @{MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving};
    [location.mapItem openInMapsWithLaunchOptions:launchOptions];
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation {
    static NSString *identifier = @"MyLocation";
    if ([annotation isKindOfClass:[MyLocation class]]) {
        
        MKAnnotationView *annotationView = (MKAnnotationView *) [self.mapView dequeueReusableAnnotationViewWithIdentifier:identifier];
        if (annotationView == nil) {
            annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:identifier];
            annotationView.enabled = YES;
            annotationView.canShowCallout = YES;
            annotationView.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
            //annotationView.image = [UIImage imageNamed:@"arrest.png"];//here we use a nice image instead of the default pins
        } else {
            annotationView.annotation = annotation;
        }
        // Because this is an iOS app, add the detail disclosure button to display details about the annotation in another view.
        
        UIButton *rightButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
        
        [rightButton addTarget:nil action:nil forControlEvents:UIControlEventTouchUpInside];
        
        annotationView.rightCalloutAccessoryView = rightButton;
        
        
        
        // Add a custom image to the left side of the callout.
        
        UIImageView *myCustomImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"MyCustomImage.png"]];
        
        annotationView.leftCalloutAccessoryView = myCustomImage;
        return annotationView;
    }
    
    return nil;
}

// Add new method above refreshTapped
- (void)plotEventPositions:(NSArray *)responseData {
    for (id<MKAnnotation> annotation in self.mapView.annotations) {
        [self.mapView removeAnnotation:annotation];
    }
    NSLog(@"RESPONSE DATA %@",responseData);
    for (PFObject *item in responseData) {
        PFGeoPoint *location = [item objectForKey:@"location"];
        CLLocationCoordinate2D coordinate;
        coordinate.latitude = location.latitude;
        coordinate.longitude = location.longitude;
        
        //MyLocation *ann = [[MyLocation alloc] initWithName:@"HotSpot" coordinate:coordinate address: ];
        MKPointAnnotation *ann = [[MKPointAnnotation alloc] init];
        PFQuery *query = [PFQuery queryWithClassName:@"Location"];
        ann.title = [item objectForKey:@"address"];
        
        NSMutableString *string1 = [NSMutableString stringWithString: @"Rating: "];
        [string1 appendString:[[item objectForKey:@"score"] stringValue]];
        ann.subtitle = string1;
        ann.coordinate = CLLocationCoordinate2DMake (coordinate.latitude, coordinate.longitude);
        [self.mapView addAnnotation:ann];
    }
    [self zoomToLocation];
}

- (void)zoomToLocation

{
    [PFGeoPoint geoPointForCurrentLocationInBackground:^(PFGeoPoint *geoPoint, NSError *error) {
    CLLocationCoordinate2D zoomLocation;
    
    zoomLocation.latitude = geoPoint.latitude;
    
    zoomLocation.longitude= geoPoint.longitude;
    
    MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(zoomLocation, 7.5*METERS_PER_MILE,7.5*METERS_PER_MILE);
    
    [self.mapView setRegion:viewRegion animated:YES];
    
    [self.mapView regionThatFits:viewRegion];
    }];
    
}

-(void)searchBarSearchButtonClicked:(UISearchBar *)theSearchBar
{
    [theSearchBar resignFirstResponder];
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    [geocoder geocodeAddressString:theSearchBar.text completionHandler:^(NSArray *placemarks, NSError *error) {
        //Error checking
        
        CLPlacemark *placemark = [placemarks objectAtIndex:0];
        MKCoordinateRegion region;
        region.center.latitude = placemark.region.center.latitude;
        region.center.longitude = placemark.region.center.longitude;
        MKCoordinateSpan span;
        double radius = placemark.region.radius / 1000; // convert to km
        
        NSLog(@"[searchBarSearchButtonClicked] Radius is %f", radius);
        span.latitudeDelta = radius / 112.0;
        
        region.span = span;
        //use latitude and longitude to drop more pins
        [self.mapView setRegion:region animated:YES];
    }];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)back:(id)sender {
    HomeViewController *home = [[HomeViewController alloc] initWithNibName:@"HomeViewController" bundle:[NSBundle mainBundle]];
    [self presentViewController:home animated:YES completion:nil];
}


@end
