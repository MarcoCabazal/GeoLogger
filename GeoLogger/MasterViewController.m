//
//  MasterViewController.m
//  GeoLogger
//
//  Created by Marco Cabazal on 02/21/2016.
//  Copyright © 2016 The Chill Mill, Inc. All rights reserved.
//

#import "MasterViewController.h"
#import "LocationVC.h"

@interface MasterViewController ()
@property NSMutableArray *locations;
@end

@implementation MasterViewController

- (void)viewDidLoad {

    [super viewDidLoad];

    self.navigationItem.leftBarButtonItem = self.editButtonItem;

    self.detailViewController = (LocationVC *)[[self.splitViewController.viewControllers lastObject] topViewController];

    NSString *locationsPath = [DOCDIR stringByAppendingPathComponent:@"locations.plist"];

    self.locations = [NSMutableArray arrayWithContentsOfFile:locationsPath];

    if (!self.locations) {

        self.locations = [NSMutableArray array];
    }
}

- (void)viewWillAppear:(BOOL)animated {

    self.clearsSelectionOnViewWillAppear = self.splitViewController.isCollapsed;

    [super  viewWillAppear:animated];
}

- (IBAction)revertToMasterVC:(UIStoryboardSegue *)segue {

}

- (IBAction)insertNewLocation:(UIStoryboardSegue *)segue {

    LocationVC *vc = (LocationVC*)segue.sourceViewController;

    NSDictionary *locationDictionary = vc.locationDictionary;

    [self.locations insertObject:locationDictionary atIndex:0];

    [self archiveLocations];

    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (IBAction)editLocation:(UIStoryboardSegue *)segue {

    LocationVC *vc = (LocationVC*)segue.sourceViewController;

    NSDictionary *locationDictionary = vc.locationDictionary;
    NSInteger index = vc.locationIndex;

    [self.locations replaceObjectAtIndex:index withObject:locationDictionary];

    [self archiveLocations];

    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
    [self performSelector:@selector(delayReloadForIndex:) withObject:indexPath afterDelay:.5];
}

- (void)delayReloadForIndex:(NSIndexPath*)indexPath {

    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
}

- (void)archiveLocations {

    NSString *locationsPath = [DOCDIR stringByAppendingPathComponent:@"locations.plist"];
    [self.locations writeToFile:locationsPath atomically:YES];
}

#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {

    if ([[segue identifier] isEqualToString:@"showLocation"]) {

        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        NSMutableDictionary *locationDictionary = self.locations[indexPath.row];

        LocationVC *controller = (LocationVC *)[segue destinationViewController];
        [controller setLocationForEditting:locationDictionary index:indexPath.row];
        
        controller.navigationItem.leftBarButtonItem = self.splitViewController.displayModeButtonItem;
        controller.navigationItem.leftItemsSupplementBackButton = YES;
    }
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {

    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    return self.locations.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];

	NSDictionary *locationDictionary = self.locations[indexPath.row];
    NSDictionary *addressDictionary = locationDictionary[@"address"];

    NSString *title = addressDictionary[@"formattedAddress"];

    [cell.textLabel setText:title];
    [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];

    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {

    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {

    if (editingStyle == UITableViewCellEditingStyleDelete) {

        [self.locations removeObjectAtIndex:indexPath.row];

        [self archiveLocations];

        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } 
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
