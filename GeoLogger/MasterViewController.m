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
@property (strong, nonatomic) NSMutableArray *locations;
@property (strong, nonatomic) Firebase *ownerLocationsRef;
@end

@implementation MasterViewController

- (void)viewDidLoad {

    [super viewDidLoad];

    self.navigationItem.leftBarButtonItem = self.editButtonItem;

    self.detailViewController = (LocationVC *)[[self.splitViewController.viewControllers lastObject] topViewController];

    if (! [[NSUserDefaults standardUserDefaults] valueForKey:@"uid"]) {

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadLocations) name:@"gotAuthenticatedUID" object:nil];

    } else {

        [self loadLocations];
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

    Firebase *newLocationRef = [self.ownerLocationsRef childByAutoId];

    [newLocationRef setValue:locationDictionary];
}

- (IBAction)editLocation:(UIStoryboardSegue *)segue {

    LocationVC *vc = (LocationVC*)segue.sourceViewController;

    NSDictionary *locationDictionary = vc.locationDictionary;
    NSString *locationKey = vc.locationKey;
    NSInteger index = vc.locationIndex;

    Firebase *editedLocationRef = [self.ownerLocationsRef childByAppendingPath:locationKey];

    [editedLocationRef updateChildValues:locationDictionary];
    [[self.locations objectAtIndex:index] setValue:locationDictionary forKey:locationKey];

    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
    [self performSelector:@selector(delayReloadForIndex:) withObject:indexPath afterDelay:.5];
}

- (void)delayReloadForIndex:(NSIndexPath*)indexPath {

    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
}

- (void)loadLocations {

    self.locations = [NSMutableArray array];

    NSString *referencePath = [NSString stringWithFormat:@"locations/%@", [[NSUserDefaults standardUserDefaults] valueForKey:@"uid"]];
    self.ownerLocationsRef = [APPDELEGATE.firebase childByAppendingPath:referencePath];

    [[self.ownerLocationsRef queryOrderedByKey] observeEventType:FEventTypeChildAdded withBlock:^(FDataSnapshot *snapshot) {

        if (snapshot.value != [NSNull null]) {

            NSMutableDictionary *locationDictionary = [@{snapshot.key : snapshot.value} mutableCopy];

            [self.locations addObject:locationDictionary];

            [self.tableView reloadData];
        }
    }];
}

#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {

    if ([[segue identifier] isEqualToString:@"showLocation"]) {

        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        NSDictionary *locationObject = self.locations[indexPath.row];
        NSString *locationKey = [[locationObject allKeys] objectAtIndex:0];
        NSMutableDictionary *locationDictionary = locationObject[locationKey];

        NSLog(@"dictionary for edit: %@", locationDictionary);

        LocationVC *controller = (LocationVC *)[segue destinationViewController];
        [controller setLocationForEditting:locationDictionary locationKey:locationKey index:indexPath.row];

        controller.navigationItem.leftBarButtonItem = self.splitViewController.displayModeButtonItem;
        controller.navigationItem.leftItemsSupplementBackButton = YES;

    } else {


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

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"localCellIdentifier" forIndexPath:indexPath];

	NSDictionary *locationDictionary = self.locations[indexPath.row];
    NSString *key = [[locationDictionary allKeys] objectAtIndex:0];

    NSDictionary *addressDictionary = locationDictionary[key][@"address"];

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

        NSDictionary *locationObject = [self.locations objectAtIndex:indexPath.row];
        NSString *locationKey = [[locationObject allKeys] objectAtIndex:0];
        Firebase *locationRef = [self.ownerLocationsRef childByAppendingPath:locationKey];
        [locationRef removeValue];

        [self.locations removeObjectAtIndex:indexPath.row];

        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } 
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
