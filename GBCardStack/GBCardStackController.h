//
//  GBCardStackController.h
//  Goonbee Cardstack
//
//  Created by Luka Mirošević on 15/01/2012.
//  Copyright (c) 2012 Goonbee. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "UIViewController+GBCardStack.h"

#pragma mark - Main Class

typedef NS_ENUM(NSUInteger, GBCardStackCardType) {
    GBCardStackCardTypeMain = 0,
    GBCardStackCardTypeLeft,
    GBCardStackCardTypeRight,
    GBCardStackCardTypeTop,
    GBCardStackCardTypeBottom,
};

@protocol GBCardStackDelegate;

@interface GBCardStackController : UIViewController <UIGestureRecognizerDelegate>

@property (weak, nonatomic) id<GBCardStackDelegate>                 delegate;

@property (strong, nonatomic) UIViewController                      *mainCard;
@property (strong, nonatomic) UIViewController                      *leftCard;
@property (strong, nonatomic) UIViewController                      *rightCard;
@property (strong, nonatomic) UIViewController                      *topCard;
@property (strong, nonatomic) UIViewController                      *bottomCard;
@property (assign, nonatomic) BOOL                                  lock;

@property (strong, nonatomic, readonly) NSMutableArray              *cards;
@property (strong, nonatomic, readonly) UIViewController            *currentCard;
@property (assign, nonatomic, readonly) BOOL                        isPanning;

/**
 Shows the desired card.
 */
- (void)showCard:(GBCardStackCardType)targetCardId animated:(BOOL)animated;

/**
 Shows the main card.
 */
- (void)restoreMainCardAnimated:(BOOL)animated;

@end

#pragma mark - Delegate

typedef NS_ENUM(NSUInteger, GBCardStackCardTransitionType) {
    GBCardStackCardTransitionTypeProgrammatic = 0,
    GBCardStackCardTransitionTypeTapOnEdge,
    GBCardStackCardTransitionTypePan,
};

@protocol GBCardStackDelegate <NSObject>
@optional

/**
 Called when the controller transitions from showing one card to showing another.
 */
- (void)GBCardStackController:(GBCardStackController *)cardStackController didShowCard:(GBCardStackCardType)targetCard fromPreviouslyShownCard:(GBCardStackCardType)previousCard type:(GBCardStackCardTransitionType)transitionType;

@end
