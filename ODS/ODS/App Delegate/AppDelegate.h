//
//  AppDelegate.h
//  ODS
//
//  Created by bdt on 9/18/14.
//  Copyright (c) 2014 Open Data Space. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

- (void)presentModalViewController:(UIViewController *)viewController animated:(BOOL)animated;

@end
