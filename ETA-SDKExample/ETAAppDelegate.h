//
//  ETAAppDelegate.h
//  ETA-SDKExample
//
//  Created by Laurie Hufford on 7/8/13.
//  Copyright (c) 2013 eTilbudsAvis. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ETA;
@interface ETAAppDelegate : UIResponder <UIApplicationDelegate>

@property (nonatomic, readwrite, strong) ETA* eta;

@property (strong, nonatomic) UIWindow *window;

@end
