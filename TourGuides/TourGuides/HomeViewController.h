//
//  HomeViewController.h
//  TourGuides
//
//  Created by Ryan Sickles on 11/1/14.
//  Copyright (c) 2014 sickles.ryan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@interface HomeViewController : UIViewController <CLLocationManagerDelegate>
- (IBAction)dropPin:(id)sender;
- (IBAction)logOut:(id)sender;
@property(nonatomic, strong) CLLocationManager *locationManager;
@end
