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

@property (weak, nonatomic) GBCardStackController   *cardStackController;
@property (strong, nonatomic) NSMutableArray        *slideableViews;

@end
