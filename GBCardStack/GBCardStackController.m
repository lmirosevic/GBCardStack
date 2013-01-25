//
//  GBCardStackController.m
//  Goonbee Cardstack
//
//  Created by Luka Mirošević on 15/01/2012.
//  Copyright (c) 2012 Goonbee. All rights reserved.
//

#import "GBCardStackController.h"

#import "GBCardViewController.h"
#import "QuartzCore/QuartzCore.h"

const double GBHorizontalCardOverlapDistance = 56;
const double GBHorizontalMinimumAutoSlideSpeed = 500;
const double GBHorizontalMaximumAutoSlideSpeed = 1200;
const double GBHorizontalAutoSlideSpeed = 800;

const double GBVerticalCardOverlapDistance = 52+20;//+20 here to compensate for status bar
const double GBVerticalMinimumAutoSlideSpeed = 700;
const double GBVerticalMaximumAutoSlideSpeed = 1700;
const double GBVerticalAutoSlideSpeed = 950;

@interface GBCardStackController() {
    NSMutableArray              *_cards;
    BOOL                        _mainCardUserInteraction;
    UIPanGestureRecognizer      *_panGestureRecognizer;
    UITapGestureRecognizer      *_tapGestureRecognizer;
}

@property (assign, nonatomic) GBCardViewCardIdentifier              currentCardId;
@property (strong, nonatomic) UIPanGestureRecognizer                *panGestureRecognizer;
@property (strong, nonatomic) UITapGestureRecognizer                *tapGestureRecognizer;
@property (assign, nonatomic) BOOL                                  mainCardUserInteraction;
@property (assign, nonatomic) GBGesturePanDirection                 panDirection;
@property (assign, nonatomic) BOOL                                  busy;
@property (assign, nonatomic) CGPoint                               originCopy;
@property (strong, nonatomic) UIView                                *maskView;

@end


@implementation GBCardStackController

#pragma mark - Card Stack interactions

-(void)slideCard:(GBCardViewCardIdentifier)targetCardId animated:(BOOL)animated {
    if (!self.busy && !self.lock) {
        if ((self.currentCardId == GBCardViewMainCard) && ([self cardWithIdentifier:targetCardId])) {
            
            //Flurry
            NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:[GBCardStackController stringForCardId:self.currentCardId], @"source", [GBCardStackController stringForCardId:targetCardId], @"destination", @"programmatic", @"type", nil];
            FLogP(@"GBCardStack: Slide card", dict);
            
            
            self.busy = YES;
            
            CGPoint topCardDestinationOrigin = CGPointMake(0, 0);//initialising here to make clang happy
            switch (targetCardId) {
                case GBCardViewLeftCard:
                    topCardDestinationOrigin = CGPointMake(self.currentCard.view.frame.size.width-GBHorizontalCardOverlapDistance, self.currentCard.view.frame.origin.y);
                    break;
                case GBCardViewRightCard:
                    topCardDestinationOrigin = CGPointMake(-self.currentCard.view.frame.size.width+GBHorizontalCardOverlapDistance, self.currentCard.view.frame.origin.y);
                    break;
                case GBCardViewTopCard:
                    topCardDestinationOrigin = CGPointMake(self.currentCard.view.frame.origin.x, self.currentCard.view.frame.size.height-GBVerticalCardOverlapDistance);
                    break;
                case GBCardViewBottomCard:
                    topCardDestinationOrigin = CGPointMake(self.currentCard.view.frame.origin.x, -self.currentCard.view.frame.size.height+GBVerticalCardOverlapDistance);
                    break;
                case GBCardViewMainCard:
                    NSLog(@"Shouldn't animate to oneself.");
                    break;
            }
            
            if (animated) {
                //insert bottom card as subview
                [self loadCard:targetCardId];
            
                //calculate animation duration
                NSTimeInterval animationDuration;
                            
                if ((targetCardId == GBCardViewTopCard) || (targetCardId == GBCardViewBottomCard)) {
                    animationDuration = (self.currentCard.view.frame.size.height-GBVerticalCardOverlapDistance)/GBVerticalAutoSlideSpeed;
                }
                else {
                    animationDuration = (self.currentCard.view.frame.size.width-GBHorizontalCardOverlapDistance)/GBHorizontalAutoSlideSpeed;
                }
                
                self.mainCardUserInteraction = NO;
                
                [UIView animateWithDuration:animationDuration delay:0 options:UIViewAnimationCurveEaseInOut animations:^{
                    //animate top card sliding over
                    self.mainCard.view.frame = CGRectMake(topCardDestinationOrigin.x, topCardDestinationOrigin.y, self.mainCard.view.frame.size.width, self.mainCard.view.frame.size.height);
                } completion:^(BOOL finished) {
                    //set currentcard as new card
                    self.currentCardId = targetCardId;
                    self.tapGestureRecognizer.enabled = YES;
                    
                    self.busy = NO;
                }];
            }
            else {
                [self loadCard:targetCardId];
                
                self.mainCardUserInteraction = NO;
                
                self.mainCard.view.frame = CGRectMake(topCardDestinationOrigin.x, topCardDestinationOrigin.y, self.mainCard.view.frame.size.width, self.mainCard.view.frame.size.height);
                self.currentCardId = targetCardId;
                self.tapGestureRecognizer.enabled = YES;
                
                self.busy = NO;
            }
        }
        else {
            NSLog(@"Main card is not the current card, or target card doesn't exist.");
        }
    }
}

-(void)restoreMainCardWithAnimation:(BOOL)animation {
    if ((self.currentCardId == GBCardViewMainCard) && !self.isPanning) {
//        NSLog(@"Already showing main card.");
    }
    else if (!self.lock && self.isPanning) {
        
        //restore main card
        self.busy = YES;
        
        //find which card is underneath
        GBCardViewCardIdentifier bottomCardId;
        
        //find out distance to home base
        CGFloat distanceToHome;
        
        //if its horizontal
        if (self.panDirection == GBGestureHorizontalPan) {
            //find out if its left or right
            CGFloat x = self.originCopy.x;
            if (x >= 0) {
                bottomCardId = GBCardViewLeftCard;
            }
            else {
                bottomCardId = GBCardViewRightCard;
            }
            
            distanceToHome = fabs(x);
        }
        else if (self.panDirection == GBGestureVerticalPan) {
            CGFloat y = self.originCopy.y;
            if (y >= 0) {
                bottomCardId = GBCardViewTopCard;
            }
            else {
                bottomCardId = GBCardViewBottomCard;
            }
            
            distanceToHome = fabs(y);
        }
        else {
            return;
        }
        
        
        //Flurry
        NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:[GBCardStackController stringForCardId:bottomCardId], @"source", [GBCardStackController stringForCardId:GBCardViewMainCard], @"destination", @"programmatic2", @"type", nil];
        FLogP(@"GBCardStack: Slide card", dict);
        
        
        if (animation) {
            //calculate animation duration
            NSTimeInterval animationDuration;
            if (self.panDirection == GBGestureHorizontalPan) {
                animationDuration = distanceToHome/GBHorizontalMinimumAutoSlideSpeed;
            }
            else {
                animationDuration = distanceToHome/GBVerticalMinimumAutoSlideSpeed;
            }
            
            [UIView animateWithDuration:animationDuration delay:0 options:UIViewAnimationCurveEaseInOut animations:^{
                self.mainCard.view.frame = CGRectMake(0, 0, self.mainCard.view.frame.size.width, self.mainCard.view.frame.size.height);
            } completion:^(BOOL finished) {
                [[self cardWithIdentifier:bottomCardId].view removeFromSuperview];
                self.currentCardId = GBCardViewMainCard;
                self.tapGestureRecognizer.enabled = NO;
                self.mainCardUserInteraction = YES;
                
                self.busy = NO;
                
                //restart gesturerecognizer
                self.panGestureRecognizer.enabled = NO;
                self.panGestureRecognizer.enabled = YES;
            }];
        }
        else {
            self.mainCard.view.frame = CGRectMake(0, 0, self.mainCard.view.frame.size.width, self.mainCard.view.frame.size.height);
            [[self cardWithIdentifier:bottomCardId].view removeFromSuperview];
            self.currentCardId = GBCardViewMainCard;
            self.tapGestureRecognizer.enabled = NO;
            self.mainCardUserInteraction = YES;
            
            self.busy = NO;
            self.panGestureRecognizer.enabled = NO;
            self.panGestureRecognizer.enabled = YES;
        }   
    }
    else if (!self.lock && !self.busy) {
        //restore main card
        self.busy = YES;
        
        if (animation) {
            //calculate animation duration
            NSTimeInterval animationDuration;
            if ((self.currentCardId == GBCardViewTopCard) || (self.currentCardId == GBCardViewBottomCard)) {
                animationDuration = (self.currentCard.view.frame.size.height-GBVerticalCardOverlapDistance)/GBVerticalAutoSlideSpeed;
            }
            else {
                animationDuration = (self.currentCard.view.frame.size.width-GBHorizontalCardOverlapDistance)/GBHorizontalAutoSlideSpeed;
            }
            
            [UIView animateWithDuration:animationDuration delay:0 options:UIViewAnimationCurveEaseInOut animations:^{
                self.mainCard.view.frame = CGRectMake(0, 0, self.mainCard.view.frame.size.width, self.mainCard.view.frame.size.height);
            } completion:^(BOOL finished) {
                [self.currentCard.view removeFromSuperview];
                self.currentCardId = GBCardViewMainCard;
                self.tapGestureRecognizer.enabled = NO;
                self.mainCardUserInteraction = YES;
                
                self.busy = NO;
            }];
        }
        else {
            self.mainCard.view.frame = CGRectMake(0, 0, self.mainCard.view.frame.size.width, self.mainCard.view.frame.size.height);
            
            [self.currentCard.view removeFromSuperview];
            self.currentCardId = GBCardViewMainCard;
            self.tapGestureRecognizer.enabled = NO;
            self.mainCardUserInteraction = YES;
                        
            self.busy = NO;
        }
    }
}

-(void)handlePan:(UIPanGestureRecognizer *)sender {
    if (!self.lock) {
        
        //manage panning state
        if ((sender.state == UIGestureRecognizerStateBegan) || (sender.state == UIGestureRecognizerStateChanged)) {
            self.isPanning = YES;
        }
        else {
            self.isPanning = NO;
        }
        
        
        CGPoint velocity = [sender velocityInView:self.view];
        CGPoint translation = [sender translationInView:self.view];
        
        //find out which dimension
        if (sender.state == UIGestureRecognizerStateBegan) {
            //horizontal
            if (fabs(velocity.x) > fabs(velocity.y)) {
                self.panDirection = GBGestureHorizontalPan;
            }
            //vertical
            else {            
                self.panDirection = GBGestureVerticalPan;
            }
        }
        
        //calculate potential newFrame for mainCard
        CGRect newFrame = self.mainCard.view.frame;
        
        if (self.panDirection == GBGestureHorizontalPan) {
            newFrame.origin.x += translation.x;
        }
        else if (self.panDirection == GBGestureVerticalPan) {
            newFrame.origin.y += translation.y;
        }
        [sender setTranslation:CGPointMake(0, 0) inView:self.view];
        
        //based on position work out target, then based on velocity work out whether to go forward or backward
        CGPoint targetOrigin;
        CGFloat distanceRemaining;
        CGFloat targetSpeed;
        GBCardViewCardIdentifier targetCardId;
        BOOL forward = YES;
        
        if (self.panDirection == GBGestureVerticalPan) {
            //topcard domain
            if (newFrame.origin.y >= 0) {
                targetOrigin = CGPointMake(self.currentCard.view.frame.origin.x, self.currentCard.view.frame.size.height-GBVerticalCardOverlapDistance);
                distanceRemaining = fabs(targetOrigin.y - self.currentCard.view.frame.origin.y);
                targetSpeed = fabs(velocity.y);
                targetCardId = GBCardViewTopCard;
                if (velocity.y < 0) {
                    forward = NO;
                }
            }
            //bottomcard domain
            else {
                targetOrigin = CGPointMake(self.currentCard.view.frame.origin.x, -self.currentCard.view.frame.size.height+GBVerticalCardOverlapDistance);
                distanceRemaining = fabs(targetOrigin.y - self.currentCard.view.frame.origin.y);
                targetSpeed = fabs(velocity.y);
                targetCardId = GBCardViewBottomCard;
                if (velocity.y > 0) {
                    forward = NO;
                }
            }
        }
        else if (self.panDirection == GBGestureHorizontalPan) {
            //leftcard domain
            if (newFrame.origin.x >= 0) {
                targetOrigin = CGPointMake(self.currentCard.view.frame.size.width-GBHorizontalCardOverlapDistance, self.currentCard.view.frame.origin.y);
                distanceRemaining = fabs(targetOrigin.x - self.currentCard.view.frame.origin.x);
                targetSpeed = fabs(velocity.x);
                targetCardId = GBCardViewLeftCard;
                if (velocity.x < 0) {
                    forward = NO;
                }
            }
            //rightcard domain
            else {
                targetOrigin = CGPointMake(-self.currentCard.view.frame.size.width+GBHorizontalCardOverlapDistance, self.currentCard.view.frame.origin.y);
                distanceRemaining = fabs(targetOrigin.x - self.currentCard.view.frame.origin.x);
                targetSpeed = fabs(velocity.x);
                targetCardId = GBCardViewRightCard;
                if (velocity.x > 0) {
                    forward = NO;
                }
            }
        }
            
        //check to see if that movement is valid, movements can't be "diagonal" and target cant be nil
        BOOL isValidMove = NO;
        
        switch (self.currentCardId) {
            case GBCardViewMainCard:
                isValidMove = YES;
                break;
                
            case GBCardViewLeftCard:
                if (self.panDirection == GBGestureHorizontalPan) {
                    isValidMove = YES;
                }
                break;
                
            case GBCardViewRightCard:
                if (self.panDirection == GBGestureHorizontalPan) {
                    isValidMove = YES;
                }
                break;
                
            case GBCardViewTopCard:
                if (self.panDirection == GBGestureVerticalPan) {
                    isValidMove = YES;
                }
                break;
                
            case GBCardViewBottomCard:
                if (self.panDirection == GBGestureVerticalPan) {
                    isValidMove = YES;
                }
                break;
        }

        //check if targetcard is not nil
        if (![self cardWithIdentifier:targetCardId]) {
            isValidMove = NO;
            //cancel the gesture
            self.panGestureRecognizer.enabled = NO;
            self.panGestureRecognizer.enabled = YES;
        }
        
        //if move isnt valid, return early
        if (!isValidMove) return;
        
        
        /* Following section moves the card and changes state, shud only go here if haven't returned early yet ie if move is valid */
            
        //make sure target card is loaded
        if (sender.state != UIGestureRecognizerStateCancelled) {
            [self loadCard:targetCardId];
        }
        //if the gesture is cancelled, reset the main card to top where it should be
        else {
            //force default frame
            self.mainCard.view.frame = CGRectMake(0, 0, self.mainCard.view.frame.size.width, self.mainCard.view.frame.size.height);
            [self loadCard:GBCardViewMainCard];
        }
        
        //commit the change
        if ((sender.state == UIGestureRecognizerStateChanged) || (sender.state == UIGestureRecognizerStateEnded)) {
            self.mainCard.view.frame = newFrame;
            self.originCopy = newFrame.origin;
        }
        
        //finish gesture
        if ((sender.state == UIGestureRecognizerStateEnded) || (sender.state == UIGestureRecognizerStateFailed)) {
            //adjust slide speed
            if (self.panDirection == GBGestureHorizontalPan) {
                if (targetSpeed < GBHorizontalMinimumAutoSlideSpeed) {
                    targetSpeed = GBHorizontalMinimumAutoSlideSpeed;
                }
                else if (targetSpeed > GBHorizontalMaximumAutoSlideSpeed) {
                    targetSpeed = GBHorizontalMaximumAutoSlideSpeed;
                }
            }
            else {
                if (targetSpeed < GBVerticalMinimumAutoSlideSpeed) {
                    targetSpeed = GBVerticalMinimumAutoSlideSpeed;
                }
                else if (targetSpeed > GBVerticalMaximumAutoSlideSpeed) {
                    targetSpeed = GBVerticalMaximumAutoSlideSpeed;
                }
            }
            
            //calculate animation duration
            NSTimeInterval animationDuration = distanceRemaining/targetSpeed;
                    
            //commit animations
            [UIView animateWithDuration:animationDuration delay:0 options:UIViewAnimationCurveEaseOut animations:^{
                self.panGestureRecognizer.enabled = NO;
                self.busy = YES;
                
                //animate
                if (forward) {
                    self.mainCard.view.frame = CGRectMake(targetOrigin.x, targetOrigin.y, self.mainCard.view.frame.size.width, self.mainCard.view.frame.size.height);
                }
                else {
                    self.mainCard.view.frame = CGRectMake(0, 0, self.mainCard.view.frame.size.width, self.mainCard.view.frame.size.height);
                }
            } completion:^(BOOL finished) {
                
                //set currentcardid at end of animation
                if (forward) {
                    
                    //Flurry
                    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:[GBCardStackController stringForCardId:self.currentCardId], @"source", [GBCardStackController stringForCardId:targetCardId], @"destination", @"pan", @"type", nil];
                    FLogP(@"GBCardStack: Slide card", dict);
                    
                    self.currentCardId = targetCardId;
                    self.tapGestureRecognizer.enabled = YES;
                    self.mainCardUserInteraction = NO;
                }
                else {
                    
                    //Flurry
                    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:[GBCardStackController stringForCardId:self.currentCardId], @"source", [GBCardStackController stringForCardId:GBCardViewMainCard], @"destination", @"pan", @"type", nil];
                    FLogP(@"GBCardStack: Slide card", dict);
                    
                    
                    //unload existing card
                    if (self.currentCardId != GBCardViewMainCard) {
                        [self.currentCard.view removeFromSuperview];   
                    }
                    else {
                        [[self cardWithIdentifier:targetCardId].view removeFromSuperview];
                    }
                    
                    //change state
                    self.currentCardId = GBCardViewMainCard;
                    self.tapGestureRecognizer.enabled = NO;
                    self.mainCardUserInteraction = YES;
                }
                
                self.panGestureRecognizer.enabled = YES;
                self.busy = NO;
            }];
        }
    }
}

-(void)handleTap:(UITapGestureRecognizer *)sender {
    if (!self.lock) {
        if (sender.state == UIGestureRecognizerStateRecognized) {
            if ((self.currentCardId != GBCardViewMainCard) && (!self.busy)) {
                //Flurry
                NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:[GBCardStackController stringForCardId:self.currentCardId], @"source", [GBCardStackController stringForCardId:GBCardViewMainCard], @"destination", @"tap on edge", @"type", nil];
                FLogP(@"GBCardStack: Slide card", dict);
                
                
                [self restoreMainCardWithAnimation:YES];
            }
        }
    }
}

#pragma mark - Gesture recogniser delegates

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if (gestureRecognizer == self.panGestureRecognizer) {
        if ((touch.view == self.mainCard.view) || ([self.mainCard.slideableViews containsObject:touch.view] || (touch.view == self.maskView))) {
            return YES;
        }
        else {
            return NO;
        }
    }
    else {
        return YES;
    }
}

#pragma mark - Convenience

+(NSString *)stringForCardId:(GBCardViewCardIdentifier)cardId {
    switch (cardId) {
        case GBCardViewMainCard:
            return @"GBCardViewMainCard";
            
        case GBCardViewLeftCard:
            return @"GBCardViewLeftCard";
            
        case GBCardViewRightCard:
            return @"GBCardViewRightCard";
            
        case GBCardViewTopCard:
            return @"GBCardViewTopCard";
            
        case GBCardViewBottomCard:
            return @"GBCardViewBottomCard";
    }
}

-(void)loadCard:(GBCardViewCardIdentifier)cardIdentifier {
    //hide any other cards except for mainCard in case they are visible
    for (int i=1; i<5; i++) {
        if (i != cardIdentifier) {
            if ([self cardWithIdentifier:i]) { 
                [[self cardWithIdentifier:i].view removeFromSuperview]; 
            }
        }
    }
    
    //show card
    if (![self cardWithIdentifier:cardIdentifier].view.superview) {
        [self.view insertSubview:[self cardWithIdentifier:cardIdentifier].view belowSubview:self.mainCard.view];
    }
}

-(GBCardViewController *)cardWithIdentifier:(GBCardViewCardIdentifier)cardIdentifier {
    if ([[self.cards objectAtIndex:cardIdentifier] isKindOfClass:[NSNull class]]) {
        return nil;
    }
    else {
        return [self.cards objectAtIndex:cardIdentifier];
    }
}

-(void)_attachGestureRecognizersToView:(UIView *)view {
    [self.panGestureRecognizer.view removeGestureRecognizer:self.panGestureRecognizer];
    [self.tapGestureRecognizer.view removeGestureRecognizer:self.tapGestureRecognizer];

    [view addGestureRecognizer:self.panGestureRecognizer];
    [view addGestureRecognizer:self.tapGestureRecognizer];
}

#pragma mark - Accessors

-(UIView *)maskView {
    if (!_maskView) {
        _maskView = [[UIView alloc] initWithFrame:self.mainCard.view.bounds];
        _maskView.userInteractionEnabled = YES;
    }
    
    return _maskView;
}

-(UIPanGestureRecognizer *)panGestureRecognizer {
    if (!_panGestureRecognizer) {
        _panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    }
    
    return _panGestureRecognizer;
}

-(void)setPanGestureRecognizer:(UIPanGestureRecognizer *)panGestureRecognizer {
    _panGestureRecognizer = panGestureRecognizer;
}

-(UITapGestureRecognizer *)tapGestureRecognizer {
    if (!_tapGestureRecognizer) {
        _tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    }
    
    return _tapGestureRecognizer;
}

-(void)setTapGestureRecognizer:(UITapGestureRecognizer *)tapGestureRecognizer {
    _tapGestureRecognizer = tapGestureRecognizer;
}

-(BOOL)mainCardUserInteraction {
    return _mainCardUserInteraction;
}

-(void)setMainCardUserInteraction:(BOOL)enabled {
    //remove mask view
    if (enabled) {
        [self.maskView removeFromSuperview];
        [self _attachGestureRecognizersToView:self.mainCard.view];
    }
    //add mask view
    else {
        [self.mainCard.view addSubview:self.maskView];
        self.maskView.frame = self.mainCard.view.bounds;
        [self _attachGestureRecognizersToView:self.maskView];
    }
    
    _mainCardUserInteraction = enabled;
}

-(GBCardViewController *)currentCard {
    return [self.cards objectAtIndex:self.currentCardId];
}

-(void)setCurrentCardId:(GBCardViewCardIdentifier)currentCardId {
    _currentCardId = currentCardId;
}

-(NSMutableArray *)cards {
    //alloc/init an array first if its nil
    if (!_cards) {
        NSNull *myNull = [NSNull null];
        _cards = [[NSMutableArray alloc] initWithObjects:myNull, myNull, myNull, myNull, myNull, nil];
    }
    
    return _cards;
}

-(void)setMainCard:(GBCardViewController *)card {
    //standard setter
    [self.cards replaceObjectAtIndex:GBCardViewMainCard withObject:card];
    card.cardStackController = self;
    
    //gesture recognisers
    self.panGestureRecognizer.delegate = self;
    self.tapGestureRecognizer.delegate = self;
    [self _attachGestureRecognizersToView:card.view];
    
    //shadow
    card.view.layer.masksToBounds = NO;
    card.view.layer.shadowColor = [[UIColor blackColor] CGColor];
    card.view.layer.shadowRadius = 16;
    card.view.layer.shadowOpacity = 1;
    card.view.layer.shadowPath = [UIBezierPath bezierPathWithRect:card.view.bounds].CGPath;
}

-(GBCardStackController *)mainCard {
    return [self.cards objectAtIndex:GBCardViewMainCard];
}

-(void)setLeftCard:(GBCardViewController *)card {
    [self.cards replaceObjectAtIndex:GBCardViewLeftCard withObject:card];
    card.cardStackController = self;
}

-(GBCardStackController *)leftCard {
    return [self.cards objectAtIndex:GBCardViewLeftCard];
}

-(void)setRightCard:(GBCardViewController *)card {
    [self.cards replaceObjectAtIndex:GBCardViewRightCard withObject:card];
    card.cardStackController = self;
}

-(GBCardStackController *)rightCard {
    return [self.cards objectAtIndex:GBCardViewRightCard];
}

-(void)setTopCard:(GBCardViewController *)card {
    [self.cards replaceObjectAtIndex:GBCardViewTopCard withObject:card];
    card.cardStackController = self;
}

-(GBCardStackController *)topCard {
    return [self.cards objectAtIndex:GBCardViewTopCard];
}

-(void)setBottomCard:(GBCardViewController *)card {
    [self.cards replaceObjectAtIndex:GBCardViewBottomCard withObject:card];
    card.cardStackController = self;
}

-(GBCardStackController *)bottomCard {
    return [self.cards objectAtIndex:GBCardViewBottomCard];
}

#pragma mark - View lifecycle

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    if ([self cardWithIdentifier:GBCardViewMainCard]) {
        if (!self.mainCard.view.superview) {
            [self.view addSubview:self.mainCard.view];
            self.currentCardId = GBCardViewMainCard;
            self.tapGestureRecognizer.enabled = NO;
        }
    }
}

-(void)viewDidUnload {
    [super viewDidUnload];
    
    _cards = nil;
    self.panGestureRecognizer = nil;
    self.tapGestureRecognizer = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
