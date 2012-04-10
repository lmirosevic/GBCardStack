//
//  GBAppDelegate.m
//  Goonbee Cardstack
//
//  Created by Luka Mirošević on 15/01/2012.
//  Copyright (c) 2012 Goonbee. All rights reserved.
//

#import "GBAppDelegate.h"

#import "GBCardStackController.h"
#import "LeftViewController.h"
#import "MainViewController.h"
#import "TopViewController.h"
#import "RightViewController.h"

@implementation GBAppDelegate

@synthesize window = _window;

@synthesize cardStackController = _cardStackController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    
    LeftViewController *leftViewController = [[LeftViewController alloc] initWithNibName:@"LeftViewController" bundle:nil];
    MainViewController *mainViewController = [[MainViewController alloc] initWithNibName:@"MainViewController" bundle:nil];
    TopViewController *topViewController = [[TopViewController alloc] initWithNibName:@"TopViewController" bundle:nil];
    RightViewController *rightViewController = [[RightViewController alloc] initWithNibName:@"RightViewController" bundle:nil];
    
    self.cardStackController = [[GBCardStackController alloc] init];
    self.cardStackController.leftCard = leftViewController;
    self.cardStackController.mainCard = mainViewController;
    self.cardStackController.topCard = topViewController;
    self.cardStackController.rightCard = rightViewController; 
    self.cardStackController.bottomCard = leftViewController;
    
//    mainViewController.view.alpha = .3;
    
    self.window.rootViewController = self.cardStackController;
    
//    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    /*
     Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
     */
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    /*
     Called when the application is about to terminate.
     Save data if appropriate.
     See also applicationDidEnterBackground:.
     */
}

@end
