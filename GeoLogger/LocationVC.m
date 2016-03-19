//
//  LocationVC.m
//  GeoLogger
//
//  Created by Marco Cabazal on 02/23/2016.
//  Copyright © 2016 The Chill Mill, Inc. All rights reserved.
//

#import "LocationVC.h"

@interface LocationVC () <GMSMapViewDelegate>

@property (strong, nonatomic) IBOutlet GMSMapView *mapView;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *saveButton;
@property (strong, nonatomic) GMSMarker *marker;

@property (strong,nonatomic) NSMutableDictionary *locationDictionary;
@property (nonatomic) NSInteger locationIndex;
@property (nonatomic) NSString *locationKey;

@property (nonatomic) BOOL firstLocationUpdate;
@property (nonatomic, getter=isInEditMode) BOOL editMode;

- (IBAction)saveButtonTapped:(id)sender;

@end

@implementation LocationVC

- (void)setLocationForEditting:(NSMutableDictionary*)locationDictionary
                   locationKey:(NSString*)locationKey
                         index:(NSInteger)index {

    [self setEditMode:YES];

    [self setLocationDictionary:locationDictionary];
    [self setLocationKey:locationKey];
    [self setLocationIndex:index];

    NSString *title = self.locationDictionary[@"address"][@"route"];

    [self setTitle:title];
}

- (void)configureMapAndMarker {

    [self.mapView.settings setMyLocationButton:YES];
    [self.mapView.settings setCompassButton:YES];

    [self.mapView addObserver:self
                   forKeyPath:@"myLocation"
                      options:NSKeyValueObservingOptionNew
                      context:NULL];

    self.marker = [[GMSMarker alloc] init];
    [self.marker setIcon:[GMSMarker markerImageWithColor:[UIColor colorWithRed:0.369 green:0.639 blue:0.718 alpha:1]]];
    [self.marker setDraggable:YES];
    [self.marker setMap:self.mapView];

    GMSCameraPosition *camera;

    if (! self.isInEditMode) {


        camera = [GMSCameraPosition cameraWithLatitude:14.569405
                                             longitude:121.020238
                                                  zoom:16];

        [self.mapView setMyLocationEnabled:YES];
        [self.marker setTitle:@"Hello"];

    } else {

        camera = [GMSCameraPosition cameraWithLatitude:[self.locationDictionary[@"latitude"] floatValue]
                                             longitude:[self.locationDictionary[@"longitude"] floatValue]
                                                  zoom:16];
        [self.mapView setMyLocationEnabled:YES];
        [self.marker setTitle:[self.locationDictionary valueForKey:@"address"][@"route"]];
    }
    
    [self.mapView setCamera:camera];
}

- (void)viewDidLoad {

    [super viewDidLoad];

    [self configureMapAndMarker];
}

- (void)viewDidAppear:(BOOL)animated {

    [super viewDidAppear:animated];

    if (self.isInEditMode) {

        float latitude = [self.locationDictionary[@"latitude"] floatValue];
        float longitude = [self.locationDictionary[@"longitude"] floatValue];

        CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(latitude, longitude);

        [self centerMapAndMarkerOn:coordinate];
    }
}

- (void)viewDidDisappear:(BOOL)animated {

    [super viewDidDisappear:animated];

    [self setTitle:nil];
    [self.mapView removeObserver:self forKeyPath:@"myLocation"];
}

- (IBAction)saveButtonTapped:(id)sender {

    if (! self.isInEditMode) {

        [self performSegueWithIdentifier:@"insertNewLocation" sender:self];

    } else {

        [self performSegueWithIdentifier:@"editLocation" sender:self];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {

    if (!self.firstLocationUpdate) {

        [self.saveButton setEnabled:YES];

        [self setFirstLocationUpdate:YES];

        CLLocation *location = [change objectForKey:NSKeyValueChangeNewKey];

        if (! self.isInEditMode) {
            
            [self centerMapAndMarkerOn:location.coordinate];
        }
    }
}

- (void)centerMapAndMarkerOn:(CLLocationCoordinate2D)coordinate {

    GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:coordinate.latitude
                                                            longitude:coordinate.longitude
                                                                 zoom:self.mapView.camera.zoom];

    [self.mapView animateToCameraPosition:camera];
    [self.marker setPosition:coordinate];

    self.locationDictionary = [@{
                                @"latitude": [NSNumber numberWithFloat:coordinate.latitude],
                                @"longitude": [NSNumber numberWithFloat:coordinate.longitude]
                                } mutableCopy];

    [self reverseGeocode:coordinate];
}

- (void)reverseGeocode:(CLLocationCoordinate2D)coordinate {

    NSString *urlBase = @"https://maps.googleapis.com/maps/api/geocode/json";
    NSString *urlPath = [NSString stringWithFormat:@"%@?latlng=%f,%f&key=%@",
                         urlBase, coordinate.latitude, coordinate.longitude,
                         [GOOGLEGEOKEY stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLQueryAllowedCharacterSet]];

    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];

    manager.requestSerializer = [AFJSONRequestSerializer serializer];

    [manager GET:urlPath parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {

        NSArray *results = [responseObject valueForKey:@"results"];

        if ([results count] > 0) {

            NSString *resultsPath = [DOCDIR stringByAppendingPathComponent:@"full.plist"];
            [results writeToFile:resultsPath atomically:YES];


            NSArray *addressComponents = results[0][@"address_components"];
            NSString *reverseDumpPath = [DOCDIR stringByAppendingPathComponent:@"condensed.plist"];
            [addressComponents writeToFile:reverseDumpPath atomically:YES];

            for (NSDictionary *addressComponentDictionary in addressComponents) {

                NSArray *typesArray = addressComponentDictionary[@"types"];

                if ( [typesArray[0] isEqualToString:@"route"]) {

                    self.locationDictionary[@"route"] = addressComponentDictionary[@"long_name"];
                }

                if ( [typesArray[0] isEqualToString:@"locality"] && [typesArray[1] isEqualToString:@"political"]) {

                    self.locationDictionary[@"locality"] = addressComponentDictionary[@"long_name"];
                }

                if ( [typesArray[0] isEqualToString:@"neighborhood"] && [typesArray[1] isEqualToString:@"political"]) {

                    self.locationDictionary[@"neighborhood"] = addressComponentDictionary[@"long_name"];
                }

                if ( [typesArray[0] isEqualToString:@"administrative_area_level_1"] && [typesArray[1] isEqualToString:@"political"]) {

                    self.locationDictionary[@"administrative_area_level_1"] = addressComponentDictionary[@"long_name"];
                }

                if ( [typesArray[0] isEqualToString:@"country"] && [typesArray[1] isEqualToString:@"political"]) {
                    
                    self.locationDictionary[@"country"] = addressComponentDictionary[@"long_name"];
                }
            }
            
            NSString *formattedAddress = results[0][@"formatted_address"];
            self.locationDictionary[@"formattedAddress"] = formattedAddress;
        }

        self.locationDictionary[@"geofenced"] = [NSNumber numberWithBool:NO];

        [self performSelectorOnMainThread:@selector(updateMarkerTitle) withObject:nil waitUntilDone:NO];

    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {

        NSLog(@"error in reverse geocode request : %@", [error description]);
    }];
}

- (void)updateMarkerTitle {

    NSString *detail = [NSString stringWithFormat:@"%@, %@", self.locationDictionary[@"neighborhood"], self.locationDictionary[@"locality"]];

    [self.marker setTitle:self.locationDictionary[@"route"]];
    [self.marker setSnippet:detail];
    [self setTitle:self.locationDictionary[@"route"]];
}

#pragma mark - GMSMapViewDelegate methods

- (BOOL)didTapMyLocationButtonForMapView:(GMSMapView *)mapView {

    [self.mapView setMyLocationEnabled:YES];
    [self centerMapAndMarkerOn:mapView.myLocation.coordinate];

    return NO;
}

- (void)mapView:(GMSMapView *)mapView didTapAtCoordinate:(CLLocationCoordinate2D)coordinate {

    [self.saveButton setEnabled:YES];
    [self centerMapAndMarkerOn:coordinate];
}

- (void)mapView:(GMSMapView *)mapView didEndDraggingMarker:(GMSMarker *)marker {

    [self.saveButton setEnabled:YES];
    [self centerMapAndMarkerOn:marker.position];
}

- (void)didReceiveMemoryWarning {

    [super didReceiveMemoryWarning];
}

@end
