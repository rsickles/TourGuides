//
//  HomeViewController.m
//  TourGuides
//
//  Created by Ryan Sickles on 11/1/14.
//  Copyright (c) 2014 sickles.ryan. All rights reserved.
//

#import "HomeViewController.h"
#import <Parse/Parse.h>
#import <ParseFacebookUtils/PFFacebookUtils.h>
#import <FacebookSDK/FacebookSDK.h>
#import "ViewController.h"
#import "MapViewController.h"


@interface HomeViewController ()
{
    BOOL upvoted;
}

@end

@implementation HomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    // Check for iOS 8. Without this guard the code will crash with "unknown selector" on iOS 7.
  
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)startStandardUpdates
{
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    // Check for iOS 8. Without this guard the code will crash with "unknown selector" on iOS 7.
    if ([self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        [self.locationManager requestWhenInUseAuthorization];
    }
    [self.locationManager startUpdatingLocation];
        
        //<<PUT YOUR CODE HERE AFTER LOCATION IS UPDATING>>
}

- (void)startDropItUpdates
{
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    // Check for iOS 8. Without this guard the code will crash with "unknown selector" on iOS 7.
    if ([self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        [self.locationManager requestWhenInUseAuthorization];
    }
    [self.locationManager startUpdatingLocation];
    
    //<<PUT YOUR CODE HERE AFTER LOCATION IS UPDATING>>
}



// Delegate method from the CLLocationManagerDelegate protocol.

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
        //if upvoted = YES, add 1 otherwise minus 1
        //stop aquiring new updates
        [self.locationManager stopUpdatingLocation];
        //gets last location
        CLLocation *location = locations.lastObject;
        CLLocationCoordinate2D coordinate = [location coordinate];
        PFGeoPoint *geoPoint = [PFGeoPoint geoPointWithLatitude:coordinate.latitude longitude:coordinate.longitude];
    
        //check if it is an unique location
        PFQuery *query = [PFQuery queryWithClassName:@"Location"];
        // Interested in locations near user.
        [query whereKey:@"location" nearGeoPoint:geoPoint withinMiles:0.1];
        [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            if(!error)
            {
                if([objects count] > 0)
                {
                    
                    PFQuery *queryNext = [PFQuery queryWithClassName:@"Location"];
                    [queryNext whereKey:@"objectId" equalTo:[[objects objectAtIndex:0] objectId]];
                    NSLog(@" %s", upvoted ? "true" : "false");
                    [queryNext getFirstObjectInBackgroundWithBlock:^(PFObject *objectName, NSError *error) {
                        NSLog(@"ERRRRO %@",error);
                        NSLog(@"HWHHEH %@",objectName);
                        if(!error)
                        {
                        if(upvoted)
                        {
                            NSNumber *num = [[NSNumber alloc] initWithDouble:1.0];
                            [objectName incrementKey:@"score" byAmount:num];
                        }
                        else{
                            NSNumber *num = [[NSNumber alloc] initWithDouble:-1.0];
                            [objectName incrementKey:@"score" byAmount:num];
                        }
                        
                        PFObject *pinTime = [PFObject objectWithClassName:@"PinTime"];
                        [objectName saveEventually:^(BOOL succeeded, NSError *error) {
                            [pinTime setObject:objectName.objectId forKey:@"loc_fk"];
                            [pinTime setObject:[NSNumber numberWithBool:YES] forKey:@"bumped"];
                            [pinTime saveEventually];
                        }];
                        }
                    }];
                    
                }
                //new entry
                else
                {
                    PFObject *object = [PFObject objectWithClassName:@"Location"];
                    NSNumber *myFloat;
                    if(upvoted)
                    {
                        myFloat = [NSNumber numberWithFloat: 1.00];
                    }
                    else{
                        myFloat = [NSNumber numberWithFloat: 0.00];
                    }
                    [object setObject:geoPoint forKey:@"location"];
                    [object setObject:myFloat forKey:@"score"];
                    //get name of location
                    CLGeocoder *ceo = [[CLGeocoder alloc]init];
                    CLLocation *loc = [[CLLocation alloc]initWithLatitude:geoPoint.latitude longitude:geoPoint.longitude]; //insert your coordinates
                    [ceo reverseGeocodeLocation:loc completionHandler:^(NSArray *placemarks, NSError *error) {
                        CLPlacemark *placemark = [placemarks objectAtIndex:0];
                        NSLog(@"placemark %@",placemark);
                        //String to hold address
                        NSString *locatedAt = [[placemark.addressDictionary valueForKey:@"FormattedAddressLines"] componentsJoinedByString:@", "];
                        [object setObject:locatedAt forKey:@"address"];
                        PFObject *pinTime = [PFObject objectWithClassName:@"PinTime"];
                        [object saveEventually:^(BOOL succeeded, NSError *error) {
                            [pinTime setObject:object.objectId forKey:@"loc_fk"];
                            [pinTime setObject:[NSNumber numberWithBool:YES] forKey:@"bumped"];
                            [pinTime saveEventually];
                        }];
                    }];
   
                }
            }
        }];
}

-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error{
    
    UIAlertView *errorAlert = [[UIAlertView alloc]initWithTitle:@"Error" message:@"There was an error retrieving your location" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
    
    [errorAlert show];
    
    NSLog(@"Error: %@",error.description);
    
}

- (IBAction)dropPin:(id)sender {
    upvoted = YES;
    [self startStandardUpdates];
}

- (IBAction)checkTheMap:(id)sender {
    MapViewController *map = [[MapViewController alloc] initWithNibName:@"MapViewController" bundle:[NSBundle mainBundle]];
    [self presentViewController:map animated:YES completion:nil];
}

- (IBAction)dropIt:(id)sender {
    upvoted = NO;
    [self startDropItUpdates];
}
@end
