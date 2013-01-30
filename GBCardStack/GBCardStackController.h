//
//  GBCardStackController.h
//  Goonbee Cardstack
//
//  Created by Luka Mirošević on 15/01/2012.
//  Copyright (c) 2012 Goonbee. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "UIViewController+GBCardStack.h"

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

@property (strong, nonatomic) UIViewController                      *mainCard;
@property (strong, nonatomic) UIViewController                      *leftCard;
@property (strong, nonatomic) UIViewController                      *rightCard;
@property (strong, nonatomic) UIViewController                      *topCard;
@property (strong, nonatomic) UIViewController                      *bottomCard;
@property (assign, nonatomic) BOOL                                  lock;

@property (strong, nonatomic, readonly) NSMutableArray              *cards;
@property (strong, nonatomic, readonly) UIViewController            *currentCard;
@property (assign, nonatomic, readonly) BOOL                        isPanning;

-(void)slideCard:(GBCardViewCardIdentifier)targetCardId animated:(BOOL)animated;
-(void)restoreMainCardWithAnimation:(BOOL)animation;

@end