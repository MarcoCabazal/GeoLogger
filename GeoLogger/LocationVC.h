//
//  LocationVC.h
//  GeoLogger
//
//  Created by Marco Cabazal on 02/23/2016.
//  Copyright © 2016 The Chill Mill, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@interface LocationVC : UIViewController

@property (readonly, nonatomic) NSMutableDictionary *locationDictionary;
@property (readonly, nonatomic) NSInteger locationIndex;

- (void)setLocationForEditting:(NSMutableDictionary*)locationDictionary index:(NSInteger)index;

@end
