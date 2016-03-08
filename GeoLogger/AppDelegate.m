//
//  AppDelegate.m
//  GeoLogger
//
//  Created by Marco Cabazal on 02/21/2016.
//  Copyright © 2016 The Chill Mill, Inc. All rights reserved.
//

#import "AppDelegate.h"
#import "LocationVC.h"

@interface AppDelegate () <UISplitViewControllerDelegate>

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    [GMSServices provideAPIKey:GOOGLEMAPSKEY];

    UISplitViewController *splitViewController = (UISplitViewController *)self.window.rootViewController;
    UINavigationController *navigationController = [splitViewController.viewControllers lastObject];
    navigationController.topViewController.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem;
    splitViewController.delegate = self;

    [[Firebase defaultConfig] setPersistenceEnabled:YES];

    self.firebase = [[Firebase alloc] initWithUrl:FIREBASE_URL];

    [self.firebase authUser:FIREBASE_USER password:FIREBASE_PASSWORD withCompletionBlock:^(NSError *error, FAuthData *authData) {

        if (error) {

            NSLog(@"error: %@", [[error userInfo] valueForKey:@"NSLocalizedDescription"]);

        } else {

            self.uid = [authData.uid copy];

            [[NSUserDefaults standardUserDefaults] setObject:self.uid forKey:@"uid"];

            [[NSNotificationCenter defaultCenter] postNotificationName:@"gotAuthenticatedUID" object:nil];
        }
    }];

    [self.firebase keepSynced:YES];

    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {

}

- (void)applicationDidEnterBackground:(UIApplication *)application {

}

- (void)applicationWillEnterForeground:(UIApplication *)application {

}

- (void)applicationDidBecomeActive:(UIApplication *)application {

}

- (void)applicationWillTerminate:(UIApplication *)application {

}

#pragma mark - Split view

- (BOOL)splitViewController:(UISplitViewController *)splitViewController collapseSecondaryViewController:(UIViewController *)secondaryViewController ontoPrimaryViewController:(UIViewController *)primaryViewController {

    if ([secondaryViewController isKindOfClass:[UINavigationController class]] &&
        [[(UINavigationController *)secondaryViewController topViewController] isKindOfClass:[LocationVC class]] &&
        ([(LocationVC *)[(UINavigationController *)secondaryViewController topViewController] locationDictionary] == nil)) {

        // Return YES to indicate that we have handled the collapse by doing nothing; the secondary controller will be discarded.
        return YES;

    } else {

        return NO;
    }
}

@end
