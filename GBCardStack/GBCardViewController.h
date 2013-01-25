//
//  GBCardViewController.h
//  Goonbee Cardstack
//
//  Created by Luka Mirošević on 15/01/2012.
//  Copyright (c) 2012 Goonbee. All rights reserved.
//

#import <UIKit/UIKit.h>

@class GBCardStackController;

@interface GBCardViewController : UIViewController

@property (nonatomic, weak) GBCardStackController *cardStackController;
@property (nonatomic, strong) NSMutableArray *slideableViews;

@end
