//
//  GBCardStackController.h
//  Goonbee Cardstack
//
//  Created by Luka Mirošević on 15/01/2012.
//  Copyright (c) 2012 Goonbee. All rights reserved.
//

#import <UIKit/UIKit.h>

@class GBCardViewController;

extern const double GBHorizontalCardOverlapDistance;
extern const double GBHorizontalMinimumAutoSlideSpeed;
extern const double GBHorizontalMaximumAutoSlideSpeed;
extern const double GBHorizontalAutoSlideSpeed;
extern const double GBVerticalCardOverlapDistance;
extern const double GBVerticalMinimumAutoSlideSpeed;
extern const double GBVerticalMaximumAutoSlideSpeed;
extern const double GBVerticalAutoSlideSpeed;

typedef enum {
    GBCardViewMainCard = 0,
    GBCardViewLeftCard,
    GBCardViewRightCard,
    GBCardViewTopCard,
    GBCardViewBottomCard,
} GBCardViewCardIdentifier;

typedef enum {
    GBGestureHorizontalPan = 0,
    GBGestureVerticalPan,
} GBGesturePanDirection;

@interface GBCardStackController : UIViewController <UIGestureRecognizerDelegate>

@property (strong, nonatomic) GBCardViewController                  *mainCard;
@property (strong, nonatomic) GBCardViewController                  *leftCard;
@property (strong, nonatomic) GBCardViewController                  *rightCard;
@property (strong, nonatomic) GBCardViewController                  *topCard;
@property (strong, nonatomic) GBCardViewController                  *bottomCard;
@property (assign, nonatomic) BOOL                                  lock;

@property (strong, nonatomic, readonly) NSMutableArray              *cards;
@property (strong, nonatomic, readonly) GBCardViewController        *currentCard;
@property (assign, nonatomic, readonly) BOOL                        isPanning;

-(void)slideCard:(GBCardViewCardIdentifier)targetCardId animated:(BOOL)animated;
-(void)restoreMainCardWithAnimation:(BOOL)animation;

@end