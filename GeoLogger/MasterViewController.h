//
//  MasterViewController.h
//  GeoLogger
//
//  Created by Marco Cabazal on 02/21/2016.
//  Copyright © 2016 The Chill Mill, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LocationVC;

@interface MasterViewController : UITableViewController

@property (strong, nonatomic) LocationVC *detailViewController;

@end

