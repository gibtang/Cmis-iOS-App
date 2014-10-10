//
//  AppDelegate.m
//  ODS
//
//  Created by bdt on 9/18/14.
//  Copyright (c) 2014 Open Data Space. All rights reserved.
//

#import "AppDelegate.h"
#import "TVOutManager.h"
#import "UIDeviceHardware.h"
#import "Flurry.h"

#import "DetailNavigationController.h"

/* TVOut unsupported Devices */
static NSArray *unsupportedDevices;

@interface AppDelegate (private)
- (BOOL)isTVOutUnsupported;
@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    NSString *buildTime = [NSString stringWithFormat:NSLocalizedString(@"about.build.date.time", @"Build: %s %s (%@.%@)"), __DATE__, __TIME__,
                           [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"],
                           [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]];
    ODSLogInfo(@"%@ %@", [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"], buildTime);
    
    //Initial UI from storyboard
    UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:IS_IPAD?kMainStoryboardNameiPad:kMainStoryboardNameiPhone bundle:nil];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = [mainStoryboard instantiateInitialViewController];
    
    if (IS_IPAD) {
        UISplitViewController *splitController = (UISplitViewController*)self.window.rootViewController;
        DetailNavigationController *detailController = nil;
        for (UIViewController *controller in [splitController viewControllers]) {
            if ([controller isKindOfClass:[DetailNavigationController class]]) {
                detailController = (DetailNavigationController*)controller;
                break;
            }
        }
        
        if (detailController) {
            detailController.splitViewController = splitController;
            splitController.delegate = detailController;
            [IpadSupport registerGlobalDetail:detailController];
        }
        
    }

    
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
    // If native TV out is unsupported we want to use TVOutManager
    if ([self isTVOutUnsupported])
    {
        // But we need to initialize the sharedInstance.
        // When we call the sharedInstance for the first time, the TVOutManager starts to listen to the
        // Screen notifications (screen connect/disconnect mode change) and will activate the TVOutManager
        // when a screen connects and stop it when it disconnects
        [[TVOutManager sharedInstance] setImplementation:kTVOutImplementationCADisplayLink];
        
        // We don't need to start the TVOutManager when there's only one screen
        if ([UIScreen screens].count > 1)
        {
            [[TVOutManager sharedInstance] startTVOut];
        }
    }

    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    // We should not call the method for the devices that support native TV out mirroring
    if ([self isTVOutUnsupported])
    {
        [[TVOutManager sharedInstance] stopTVOut];
    }
    
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    // If native TV out is unsupported we want to use TVOutManager
    if ([self isTVOutUnsupported])
    {
        [[TVOutManager sharedInstance] setImplementation:kTVOutImplementationCADisplayLink];
        if ([UIScreen screens].count > 1)
        {
            [[TVOutManager sharedInstance] startTVOut];
        }
    }
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark -
#pragma mark Private Method
- (BOOL)isTVOutUnsupported {
    UIDeviceHardware *device = [[UIDeviceHardware alloc] init];
    
    BOOL unsupported = [unsupportedDevices containsObject:[device platform]];
    
    return unsupported;
}

#pragma mark -
#pragma mark Class Initialize
+ (void)initialize
{
    // We use a whitelist rather than a blacklist to include the devices that do not support native TV mirroring since it is more likely
    // that new devices support native TV out mirroring
    unsupportedDevices = [NSArray arrayWithObjects:@"iPhone1,1",@"iPhone1,2",@"iPhone2,1",@"iPhone3,1",@"iPhone3,3"
                          @"iPod1,1",@"iPod2,1",@"iPod3,1",@"iPod4,1",@"iPad1,1",@"i386",@"x86_64", nil];
}

#pragma mark -
#pragma mark UI Helpers
- (void)presentModalViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    [self.window.rootViewController presentViewController:viewController animated:animated completion:NULL];
}

@end