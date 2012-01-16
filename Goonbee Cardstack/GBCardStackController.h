//
//  GBCardStackController.h
//  Goonbee Cardstack
//
//  Created by Luka Mirošević on 15/01/2012.
//  Copyright (c) 2012 Goonbee. All rights reserved.
//

#import <UIKit/UIKit.h>

@class GBCardViewController;

extern const double cardOverlapDistance;
extern const double minimumAutoSlideSpeed;
extern const double autoSlideSpeed;

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

@property (nonatomic, strong, readonly) NSMutableArray *cards;
@property (nonatomic, weak) GBCardViewController *mainCard;
@property (nonatomic, weak) GBCardViewController *leftCard;
@property (nonatomic, weak) GBCardViewController *rightCard;
@property (nonatomic, weak) GBCardViewController *topCard;
@property (nonatomic, strong, readonly) GBCardViewController *currentCard;

-(void)slideCard:(GBCardViewCardIdentifier)card animated:(BOOL)animated;
-(void)restoreMainCardWithAnimation:(BOOL)animation;

@end











//    GBCardViewController *newCard = (GBCardViewController *)[self.cards objectAtIndex:cardIdentifier];
//    
//    NSAssert([self cardWithIdentifier:cardIdentifier] && self.currentCard, @"Current and destination cards must not be nil.");
//    
//    if (animated) {
//        CGPoint destinationPoint;
//        if (self.currentCardId == GBCardViewMainCard) {
//            //forward animations (showing lower cards)
//            switch (cardIdentifier) {
//                case GBCardViewLeftCard:
//                    destinationPoint = CGPointMake(self.currentCard.view.frame.size.width-cardOverlapDistance, self.currentCard.view.frame.origin.y);
//                    break;
//                case GBCardViewRightCard:
//                    destinationPoint = CGPointMake(-self.currentCard.view.frame.size.width+cardOverlapDistance, self.currentCard.view.frame.origin.y);
//                    break;
//                case GBCardViewTopCard:
//                    destinationPoint = CGPointMake(self.currentCard.view.frame.origin.x, self.currentCard.view.frame.size.height-cardOverlapDistance);
//                    break;
//                case GBCardViewMainCard:
//                    NSLog(@"Shouldn't animate to oneself");
//                    break;
//            }
//        }
//        else {
//            //reverse animations (restoring main card)
//            if (cardIdentifier == GBCardViewMainCard) {
//                destinationPoint = CGPointMake(0, 0);
//            }
//            else {
//                NSAssert(false, @"Can't animate that way.");
//            }
//        }        
//        
//        [self.view insertSubview:newCard.view belowSubview:self.currentCard.view];
//        
//        [UIView animateWithDuration:1.0 delay:0 options:UIViewAnimationCurveEaseOut animations:^{
//            self.currentCard.view.frame = CGRectMake(destinationPoint.x, destinationPoint.y, self.currentCard.view.frame.size.width, self.currentCard.view.frame.size.height);
//        } completion:^(BOOL finished) {
////            [self.currentCard.view removeFromSuperview];
//
//            self.currentCardId = cardIdentifier;
//        }];
//    }
//    else {
//        //show main card
//        if (cardIdentifier == GBCardViewMainCard) {
//            [self.view addSubview:newCard.view];
//            
//            [self.currentCard.view removeFromSuperview];
//            self.currentCardId = cardIdentifier;
//        }
//        //show main card pulled to the side of some other card
//        else {
//            //show bottom card at 0,0
//            
//            //show top card moved off to the side
//        }
//    }