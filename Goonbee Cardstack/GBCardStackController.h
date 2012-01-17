//
//  GBCardStackController.h
//  Goonbee Cardstack
//
//  Created by Luka Mirošević on 15/01/2012.
//  Copyright (c) 2012 Goonbee. All rights reserved.
//

#import <UIKit/UIKit.h>

@class GBCardViewController;

extern const double GBCardOverlapDistance;
extern const double GBHorizontalMinimumAutoSlideSpeed;
extern const double GBHorizontalMaximumAutoSlideSpeed;
extern const double GBHorizontalAutoSlideSpeed;
extern const double GBVerticalMinimumAutoSlideSpeed;
extern const double GBVerticalMaximumAutoSlideSpeed;
extern const double GBVerticalAutoSlideSpeed;

typedef enum {
    GBCardViewMainCard = 0,
    GBCardViewLeftCard,
    GBCardViewRightCard,
    GBCardViewTopCard,
} GBCardViewCardIdentifier;

typedef enum {
    GBGestureHorizontalPan = 0,
    GBGestureVerticalPan,
} GBGesturePanDirection;

@interface GBCardStackController : UIViewController

@property (nonatomic, strong, readonly) NSMutableArray              *cards;
@property (nonatomic, strong, readonly) GBCardViewController        *currentCard;
@property (nonatomic, weak) GBCardViewController                    *mainCard;
@property (nonatomic, weak) GBCardViewController                    *leftCard;
@property (nonatomic, weak) GBCardViewController                    *rightCard;
@property (nonatomic, weak) GBCardViewController                    *topCard;

-(void)slideCard:(GBCardViewCardIdentifier)card animated:(BOOL)animated;
-(void)restoreMainCardWithAnimation:(BOOL)animation;

@end