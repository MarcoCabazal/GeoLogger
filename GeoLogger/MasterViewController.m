//
//  MasterViewController.m
//  GeoLogger
//
//  Created by Marco Cabazal on 02/21/2016.
//  Copyright © 2016 The Chill Mill, Inc. All rights reserved.
//

#import "MasterViewController.h"
#import "LocationVC.h"

@interface MasterViewController () <GMSMapViewDelegate>
@property (strong, nonatomic) IBOutlet GMSMapView *mapView;
@property (strong, nonatomic) NSMutableArray *locations;
@property (strong, nonatomic) NSMutableSet *locationKeys;
@property (strong, nonatomic) NSMutableArray *markers;
@property (strong, nonatomic) Firebase *ownerLocationsRef;

- (IBAction)buttonTapped:(id)sender;
@end

@implementation MasterViewController

- (void)viewDidLoad {

    [super viewDidLoad];

    self.navigationItem.leftBarButtonItem = self.editButtonItem;

    self.detailViewController = (LocationVC *)[[self.splitViewController.viewControllers lastObject] topViewController];

    self.locations = [NSMutableArray array];
    self.locationKeys = [NSMutableSet set];
}

- (void)viewWillAppear:(BOOL)animated {

    [super viewWillAppear:animated];

    self.clearsSelectionOnViewWillAppear = self.splitViewController.isCollapsed;

    if (! [[NSUserDefaults standardUserDefaults] valueForKey:@"uid"]) {

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadLocations) name:@"gotAuthenticatedUID" object:nil];

    } else {

        [self loadLocations];
    }

    [self configureMap];
}

- (void)viewDidDisappear:(BOOL)animated {

    [super viewDidDisappear:animated];

    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)configureMap {

    self.mapView = [[GMSMapView alloc] initWithFrame:self.view.bounds];
    [self.mapView setHidden:YES];
    [self.mapView.settings setMyLocationButton:YES];
    [self.mapView.settings setCompassButton:YES];

    [self.mapView addObserver:self
                   forKeyPath:@"myLocation"
                      options:NSKeyValueObservingOptionNew
                      context:NULL];

    GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:14.569405
                                         longitude:121.020238
                                              zoom:12];

    [self.mapView setMyLocationEnabled:YES];


    [self.mapView setCamera:camera];
    [self.view addSubview:self.mapView];
}

- (void)configureMarkers {

    if (! self.markers) {

        for (GMSMarker *marker in self.markers) {

            [marker setMap:nil];
        }

        [self.markers removeAllObjects];

    } else {

        self.markers = [NSMutableArray array];
    }

    for (NSDictionary *locationDictionaryWithKey in self.locations) {

        NSString *locationKey = [[locationDictionaryWithKey allKeys] objectAtIndex:0];
        NSDictionary *locationDictionary = locationDictionaryWithKey[locationKey];

        NSString *markerTitle = locationDictionary[@"formattedAddress"];
        CLLocationCoordinate2D position = CLLocationCoordinate2DMake([locationDictionary[@"latitude"] doubleValue],
                                                                     [locationDictionary[@"longitude"] doubleValue]);

        GMSMarker *marker = [[GMSMarker alloc] init];
        [marker setIcon:[GMSMarker markerImageWithColor:[UIColor colorWithRed:0.369 green:0.639 blue:0.718 alpha:1]]];
        [marker setTitle:markerTitle];
        [marker setPosition:position];
        [marker setMap:self.mapView];

        [self.markers addObject:marker];
    }
}

- (IBAction)buttonTapped:(UISegmentedControl*)sender {

    if (sender.selectedSegmentIndex == 0) {

        [self.mapView setHidden:YES];

    } else {

        [self.mapView setHidden:NO];

        [self configureMarkers];
    }
}

- (IBAction)revertToMasterVC:(UIStoryboardSegue *)segue {

}

- (IBAction)insertNewLocation:(UIStoryboardSegue *)segue {

    LocationVC *vc = (LocationVC*)segue.sourceViewController;

    NSDictionary *locationDictionary = vc.locationDictionary;

    Firebase *newLocationRef = [self.ownerLocationsRef childByAutoId];

    [newLocationRef setValue:locationDictionary];

    NSString *locationKey = newLocationRef.key;

    NSDictionary *tempDictionary = @{ locationKey: locationDictionary };

    [self.locationKeys addObject:locationKey];
    [self.locations addObject:tempDictionary];
    [self.tableView reloadData];
}

- (IBAction)editLocation:(UIStoryboardSegue *)segue {

    LocationVC *vc = (LocationVC*)segue.sourceViewController;

    NSDictionary *locationDictionary = vc.locationDictionary;
    NSString *locationKey = vc.locationKey;
    NSInteger index = vc.locationIndex;

    [self updateFirebaseWithLocationDictionary:locationDictionary locationKey:locationKey];

    self.locations[index][locationKey] = locationDictionary;

    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
    [self performSelector:@selector(delayReloadForIndex:) withObject:indexPath afterDelay:.5];
}

- (void)updateFirebaseWithLocationDictionary:(NSDictionary*)locationDictionary locationKey:(NSString*)locationKey{

    Firebase *editedLocationRef = [self.ownerLocationsRef childByAppendingPath:locationKey];
    [editedLocationRef updateChildValues:locationDictionary];
}

- (void)delayReloadForIndex:(NSIndexPath*)indexPath {

    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
}

- (void)loadLocations {

    NSString *referencePath = [NSString stringWithFormat:@"locations/%@", [[NSUserDefaults standardUserDefaults] valueForKey:@"uid"]];
    self.ownerLocationsRef = [APPDELEGATE.firebase childByAppendingPath:referencePath];

    [self.ownerLocationsRef observeEventType:FEventTypeChildAdded withBlock:^(FDataSnapshot *snapshot) {

        if (snapshot.value != [NSNull null]) {

            NSMutableDictionary *locationDictionary = [@{snapshot.key : snapshot.value} mutableCopy];

            if (! [self.locationKeys containsObject:snapshot.key]) {

                [self.locationKeys addObject:snapshot.key];
                [self.locations addObject:locationDictionary];
                [self.tableView reloadData];
            }
        }
    }];

    [self.ownerLocationsRef observeEventType:FEventTypeChildRemoved withBlock:^(FDataSnapshot *snapshot) {

        if (snapshot.value != [NSNull null]) {

            NSMutableDictionary *locationDictionary = [@{snapshot.key : snapshot.value} mutableCopy];

            [self.locations removeObject:locationDictionary];
            [self.tableView reloadData];
            [self configureMarkers];
        }
    }];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
}

#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {

    if ([[segue identifier] isEqualToString:@"showLocation"]) {

        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        NSDictionary *locationObject = self.locations[indexPath.row];
        NSString *locationKey = [[locationObject allKeys] objectAtIndex:0];
        NSMutableDictionary *locationDictionary = locationObject[locationKey];

        LocationVC *controller = (LocationVC *)[segue destinationViewController];
        [controller setLocationForEditting:locationDictionary locationKey:locationKey index:indexPath.row];

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

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"localCellIdentifier" forIndexPath:indexPath];

	NSDictionary *locationDictionaryWithKey = self.locations[indexPath.row];
    NSString *locationKey = [[locationDictionaryWithKey allKeys] objectAtIndex:0];
    NSDictionary *locationDictionary = locationDictionaryWithKey[locationKey];

    NSString *title = locationDictionary[@"formattedAddress"];

    [cell.textLabel setText:title];

    return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {

    if (editingStyle == UITableViewCellEditingStyleDelete) {

        NSDictionary *locationDictionaryWithKey = [self.locations objectAtIndex:indexPath.row];
        NSString *locationKey = [[locationDictionaryWithKey allKeys] objectAtIndex:0];

        Firebase *locationRef = [self.ownerLocationsRef childByAppendingPath:locationKey];
        [locationRef removeValue];

        [self.locations removeObjectAtIndex:indexPath.row];

        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {

    return YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
