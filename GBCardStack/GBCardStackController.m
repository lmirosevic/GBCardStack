//
//  GBCardStackController.m
//  Goonbee Cardstack
//
//  Created by Luka Mirošević on 15/01/2012.
//  Copyright (c) 2012 Goonbee. All rights reserved.
//

#import "GBCardStackController.h"

#import <QuartzCore/QuartzCore.h>

#import "GBToolbox.h"
#import "GBAnalytics.h"

static double const GBHorizontalCardOverlapDistance =               56;
static double const GBHorizontalMinimumAutoSlideSpeed =             500;
static double const GBHorizontalMaximumAutoSlideSpeed =             1200;
static double const GBHorizontalAutoSlideSpeed =                    800;

static double const GBVerticalCardOverlapDistance =                 52+20;//+20 here to compensate for status bar
static double const GBVerticalMinimumAutoSlideSpeed =               700;
static double const GBVerticalMaximumAutoSlideSpeed =               1700;
static double const GBVerticalAutoSlideSpeed =                      950;

#define kDefaultShadowColor                                         [UIColor blackColor]
static CGFloat const kDefaultShadowRadius =                         16;
static CGFloat const kDefaultShadowOpacity =                        1;

typedef NS_ENUM(NSUInteger, GBGesturePanDirection) {
    GBGestureHorizontalPan = 0,
    GBGestureVerticalPan,
};

@interface GBCardStackController() {
    NSMutableArray                                                  *_cards;
}

@property (assign, nonatomic) GBCardStackCardType                   currentCardId;
@property (strong, nonatomic) UIPanGestureRecognizer                *panGestureRecognizer;
@property (strong, nonatomic) UITapGestureRecognizer                *tapGestureRecognizer;
@property (assign, nonatomic) BOOL                                  mainCardUserInteraction;
@property (assign, nonatomic) GBGesturePanDirection                 panDirection;
@property (assign, nonatomic) BOOL                                  busy;
@property (assign, nonatomic) CGPoint                               originCopy;
@property (strong, nonatomic) UIView                                *maskView;
@property (assign, nonatomic, readwrite) BOOL                       isPanning;

@end

@implementation GBCardStackController

#pragma mark - Card Stack interactions

- (void)showCard:(GBCardStackCardType)targetCardId animated:(BOOL)animated {
    if (!self.busy && !self.lock) {
        if ((self.currentCardId == GBCardStackCardTypeMain) && ([self _cardWithIdentifier:targetCardId])) {
            self.busy = YES;
            
            //Flurry
            NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:[GBCardStackController _stringForCardId:self.currentCardId], @"source", [GBCardStackController _stringForCardId:targetCardId], @"destination", @"programmatic", @"type", nil];
            _tp(@"GBCardStack: Slide card", dict);
            
            
            CGPoint topCardDestinationOrigin = CGPointMake(0, 0);//initialising here to make clang happy
            switch (targetCardId) {
                case GBCardStackCardTypeLeft:
                    topCardDestinationOrigin = CGPointMake(self.currentCard.view.frame.size.width-GBHorizontalCardOverlapDistance, self.currentCard.view.frame.origin.y);
                    break;
                case GBCardStackCardTypeRight:
                    topCardDestinationOrigin = CGPointMake(-self.currentCard.view.frame.size.width+GBHorizontalCardOverlapDistance, self.currentCard.view.frame.origin.y);
                    break;
                case GBCardStackCardTypeTop:
                    topCardDestinationOrigin = CGPointMake(self.currentCard.view.frame.origin.x, self.currentCard.view.frame.size.height-GBVerticalCardOverlapDistance);
                    break;
                case GBCardStackCardTypeBottom:
                    topCardDestinationOrigin = CGPointMake(self.currentCard.view.frame.origin.x, -self.currentCard.view.frame.size.height+GBVerticalCardOverlapDistance);
                    break;
                case GBCardStackCardTypeMain:
                    NSLog(@"Shouldn't animate to oneself.");
                    break;
            }
            
            if (animated) {
                //insert bottom card as subview
                [self _loadCard:targetCardId];
            
                //calculate animation duration
                NSTimeInterval animationDuration;
                            
                if ((targetCardId == GBCardStackCardTypeTop) || (targetCardId == GBCardStackCardTypeBottom)) {
                    animationDuration = (self.currentCard.view.frame.size.height-GBVerticalCardOverlapDistance)/GBVerticalAutoSlideSpeed;
                }
                else {
                    animationDuration = (self.currentCard.view.frame.size.width-GBHorizontalCardOverlapDistance)/GBHorizontalAutoSlideSpeed;
                }
                
                self.mainCardUserInteraction = NO;
                
                [UIView animateWithDuration:animationDuration delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
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
                [self _loadCard:targetCardId];
                
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

- (void)restoreMainCardAnimated:(BOOL)animated {
    if ((self.currentCardId == GBCardStackCardTypeMain) && !self.isPanning) {
//        NSLog(@"Already showing main card.");
    }
    else if (!self.lock && self.isPanning) {
        
        //restore main card
        self.busy = YES;
        
        //find which card is underneath
        GBCardStackCardType bottomCardId;
        
        //find out distance to home base
        CGFloat distanceToHome;
        
        //if its horizontal
        if (self.panDirection == GBGestureHorizontalPan) {
            //find out if its left or right
            CGFloat x = self.originCopy.x;
            if (x >= 0) {
                bottomCardId = GBCardStackCardTypeLeft;
            }
            else {
                bottomCardId = GBCardStackCardTypeRight;
            }
            
            distanceToHome = fabs(x);
        }
        else if (self.panDirection == GBGestureVerticalPan) {
            CGFloat y = self.originCopy.y;
            if (y >= 0) {
                bottomCardId = GBCardStackCardTypeTop;
            }
            else {
                bottomCardId = GBCardStackCardTypeBottom;
            }
            
            distanceToHome = fabs(y);
        }
        else {
            return;
        }
        
        
        //Flurry
        NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:[GBCardStackController _stringForCardId:bottomCardId], @"source", [GBCardStackController _stringForCardId:GBCardStackCardTypeMain], @"destination", @"programmatic2", @"type", nil];
        _tp(@"GBCardStack: Slide card", dict);
        
        
        if (animated) {
            //calculate animation duration
            NSTimeInterval animationDuration;
            if (self.panDirection == GBGestureHorizontalPan) {
                animationDuration = distanceToHome/GBHorizontalMinimumAutoSlideSpeed;
            }
            else {
                animationDuration = distanceToHome/GBVerticalMinimumAutoSlideSpeed;
            }
            
            [UIView animateWithDuration:animationDuration delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                self.mainCard.view.frame = CGRectMake(0, 0, self.mainCard.view.frame.size.width, self.mainCard.view.frame.size.height);
            } completion:^(BOOL finished) {
                RemoveChildViewController([self _cardWithIdentifier:bottomCardId]);
                self.currentCardId = GBCardStackCardTypeMain;
                self.tapGestureRecognizer.enabled = NO;
                self.mainCardUserInteraction = YES;
                self.panGestureRecognizer.enabled = NO;
                self.panGestureRecognizer.enabled = YES;
                self.busy = NO;
            }];
        }
        else {
            self.mainCard.view.frame = CGRectMake(0, 0, self.mainCard.view.frame.size.width, self.mainCard.view.frame.size.height);
            
            RemoveChildViewController([self _cardWithIdentifier:bottomCardId]);
            self.currentCardId = GBCardStackCardTypeMain;
            self.tapGestureRecognizer.enabled = NO;
            self.mainCardUserInteraction = YES;
            self.panGestureRecognizer.enabled = NO;
            self.panGestureRecognizer.enabled = YES;
            self.busy = NO;
        }   
    }
    else if (!self.lock && !self.busy) {
        //restore main card
        self.busy = YES;
        
        if (animated) {
            //calculate animation duration
            NSTimeInterval animationDuration;
            if ((self.currentCardId == GBCardStackCardTypeTop) || (self.currentCardId == GBCardStackCardTypeBottom)) {
                animationDuration = (self.currentCard.view.frame.size.height-GBVerticalCardOverlapDistance)/GBVerticalAutoSlideSpeed;
            }
            else {
                animationDuration = (self.currentCard.view.frame.size.width-GBHorizontalCardOverlapDistance)/GBHorizontalAutoSlideSpeed;
            }
            
            [UIView animateWithDuration:animationDuration delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                self.mainCard.view.frame = CGRectMake(0, 0, self.mainCard.view.frame.size.width, self.mainCard.view.frame.size.height);
            } completion:^(BOOL finished) {
                RemoveChildViewController(self.currentCard);
                self.currentCardId = GBCardStackCardTypeMain;
                self.tapGestureRecognizer.enabled = NO;
                self.mainCardUserInteraction = YES;
                self.busy = NO;
            }];
        }
        else {
            self.mainCard.view.frame = CGRectMake(0, 0, self.mainCard.view.frame.size.width, self.mainCard.view.frame.size.height);
            
            RemoveChildViewController(self.currentCard);
            self.currentCardId = GBCardStackCardTypeMain;
            self.tapGestureRecognizer.enabled = NO;
            self.mainCardUserInteraction = YES;
            self.busy = NO;
        }
    }
}

- (void)handlePan:(UIPanGestureRecognizer *)sender {
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
        GBCardStackCardType targetCardId;
        BOOL forward = YES;
        
        if (self.panDirection == GBGestureVerticalPan) {
            //topcard domain
            if (newFrame.origin.y >= 0) {
                targetOrigin = CGPointMake(self.currentCard.view.frame.origin.x, self.currentCard.view.frame.size.height-GBVerticalCardOverlapDistance);
                distanceRemaining = fabs(targetOrigin.y - self.currentCard.view.frame.origin.y);
                targetSpeed = fabs(velocity.y);
                targetCardId = GBCardStackCardTypeTop;
                if (velocity.y < 0) {
                    forward = NO;
                }
            }
            //bottomcard domain
            else {
                targetOrigin = CGPointMake(self.currentCard.view.frame.origin.x, -self.currentCard.view.frame.size.height+GBVerticalCardOverlapDistance);
                distanceRemaining = fabs(targetOrigin.y - self.currentCard.view.frame.origin.y);
                targetSpeed = fabs(velocity.y);
                targetCardId = GBCardStackCardTypeBottom;
                if (velocity.y > 0) {
                    forward = NO;
                }
            }
        }
        else {
            //leftcard domain
            if (newFrame.origin.x >= 0) {
                targetOrigin = CGPointMake(self.currentCard.view.frame.size.width-GBHorizontalCardOverlapDistance, self.currentCard.view.frame.origin.y);
                distanceRemaining = fabs(targetOrigin.x - self.currentCard.view.frame.origin.x);
                targetSpeed = fabs(velocity.x);
                targetCardId = GBCardStackCardTypeLeft;
                if (velocity.x < 0) {
                    forward = NO;
                }
            }
            //rightcard domain
            else {
                targetOrigin = CGPointMake(-self.currentCard.view.frame.size.width+GBHorizontalCardOverlapDistance, self.currentCard.view.frame.origin.y);
                distanceRemaining = fabs(targetOrigin.x - self.currentCard.view.frame.origin.x);
                targetSpeed = fabs(velocity.x);
                targetCardId = GBCardStackCardTypeRight;
                if (velocity.x > 0) {
                    forward = NO;
                }
            }
        }
            
        //check to see if that movement is valid, movements can't be "diagonal" and target cant be nil
        BOOL isValidMove = NO;
        
        switch (self.currentCardId) {
            case GBCardStackCardTypeMain:
                isValidMove = YES;
                break;
                
            case GBCardStackCardTypeLeft:
                if (self.panDirection == GBGestureHorizontalPan) {
                    isValidMove = YES;
                }
                break;
                
            case GBCardStackCardTypeRight:
                if (self.panDirection == GBGestureHorizontalPan) {
                    isValidMove = YES;
                }
                break;
                
            case GBCardStackCardTypeTop:
                if (self.panDirection == GBGestureVerticalPan) {
                    isValidMove = YES;
                }
                break;
                
            case GBCardStackCardTypeBottom:
                if (self.panDirection == GBGestureVerticalPan) {
                    isValidMove = YES;
                }
                break;
        }

        //check if targetcard is not nil
        if (![self _cardWithIdentifier:targetCardId]) {
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
            [self _loadCard:targetCardId];
        }
        //if the gesture is cancelled, reset the main card to top where it should be
        else {
            //force default frame
            self.mainCard.view.frame = CGRectMake(0, 0, self.mainCard.view.frame.size.width, self.mainCard.view.frame.size.height);
            [self _loadCard:GBCardStackCardTypeMain];
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
            [UIView animateWithDuration:animationDuration delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
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
                    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:[GBCardStackController _stringForCardId:self.currentCardId], @"source", [GBCardStackController _stringForCardId:targetCardId], @"destination", @"pan", @"type", nil];
                    _tp(@"GBCardStack: Slide card", dict);
                    
                    self.currentCardId = targetCardId;
                    self.tapGestureRecognizer.enabled = YES;
                    self.mainCardUserInteraction = NO;
                }
                else {
                    
                    //Flurry
                    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:[GBCardStackController _stringForCardId:self.currentCardId], @"source", [GBCardStackController _stringForCardId:GBCardStackCardTypeMain], @"destination", @"pan", @"type", nil];
                    _tp(@"GBCardStack: Slide card", dict);
                    
                    
                    // unload existing card
                    if (self.currentCardId != GBCardStackCardTypeMain) {
                        RemoveChildViewController(self.currentCard);
                    }
                    else {
                        RemoveChildViewController([self _cardWithIdentifier:targetCardId]);
                    }
                    
                    // change state
                    self.currentCardId = GBCardStackCardTypeMain;
                    self.tapGestureRecognizer.enabled = NO;
                    self.mainCardUserInteraction = YES;
                }
                
                self.panGestureRecognizer.enabled = YES;
                self.busy = NO;
            }];
        }
    }
}

- (void)handleTap:(UITapGestureRecognizer *)sender {
    if (!self.lock) {
        if (sender.state == UIGestureRecognizerStateRecognized) {
            if ((self.currentCardId != GBCardStackCardTypeMain) && (!self.busy)) {
                //Flurry
                NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:[GBCardStackController _stringForCardId:self.currentCardId], @"source", [GBCardStackController _stringForCardId:GBCardStackCardTypeMain], @"destination", @"tap on edge", @"type", nil];
                _tp(@"GBCardStack: Slide card", dict);
                
                
                [self restoreMainCardAnimated:YES];
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

+ (NSString *)_stringForCardId:(GBCardStackCardType)cardId {
    switch (cardId) {
        case GBCardStackCardTypeMain:
            return @"GBCardStackCardTypeMain";
            
        case GBCardStackCardTypeLeft:
            return @"GBCardStackCardTypeLeft";
            
        case GBCardStackCardTypeRight:
            return @"GBCardStackCardTypeRight";
            
        case GBCardStackCardTypeTop:
            return @"GBCardStackCardTypeTop";
            
        case GBCardStackCardTypeBottom:
            return @"GBCardStackCardTypeBottom";
    }
}

- (void)_loadCard:(GBCardStackCardType)cardIdentifier {
    // remove any other cards from the view hierarchy except for mainCard in case they are visible
    for (NSUInteger i=1; i<5; i++) {
        if (i != cardIdentifier) {
            if ([self _cardWithIdentifier:i]) {
                RemoveChildViewController([self _cardWithIdentifier:i]);
            }
        }
    }
    
    // add card to view hierarchy
    if (![self _cardWithIdentifier:cardIdentifier].view.superview) {
        AddChildViewController(self, [self _cardWithIdentifier:cardIdentifier]);// adds the child viewcontroller
        [self.view bringSubviewToFront:self.mainCard.view];// ensures that the main one is on top
    }
}

- (UIViewController *)_cardWithIdentifier:(GBCardStackCardType)cardIdentifier {
    if ([[self.cards objectAtIndex:cardIdentifier] isKindOfClass:[NSNull class]]) {
        return nil;
    }
    else {
        return [self.cards objectAtIndex:cardIdentifier];
    }
}

- (void)_attachGestureRecognizersToView:(UIView *)view {
    [self.panGestureRecognizer.view removeGestureRecognizer:self.panGestureRecognizer];
    [self.tapGestureRecognizer.view removeGestureRecognizer:self.tapGestureRecognizer];

    [view addGestureRecognizer:self.panGestureRecognizer];
    [view addGestureRecognizer:self.tapGestureRecognizer];
}

#pragma mark - Accessors

- (UIView *)maskView {
    if (!_maskView) {
        _maskView = AutoLayout([[UIView alloc] initWithFrame:self.mainCard.view.bounds]);
        _maskView.userInteractionEnabled = YES;
    }
    
    return _maskView;
}

- (UIPanGestureRecognizer *)panGestureRecognizer {
    if (!_panGestureRecognizer) {
        _panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    }
    
    return _panGestureRecognizer;
}

- (UITapGestureRecognizer *)tapGestureRecognizer {
    if (!_tapGestureRecognizer) {
        _tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    }
    
    return _tapGestureRecognizer;
}

- (void)setMainCardUserInteraction:(BOOL)enabled {
    // remove mask view
    if (enabled) {
        [self.maskView removeFromSuperview];
        [self _attachGestureRecognizersToView:self.mainCard.view];
    }
    // add mask view
    else {
        [self.mainCard.view addSubview:self.maskView];
        [self.mainCard.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[maskView]|" options:0 metrics:nil views:@{@"maskView": self.maskView}]];// full width
        [self.mainCard.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[maskView]|" options:0 metrics:nil views:@{@"maskView": self.maskView}]];// full height
        [self _attachGestureRecognizersToView:self.maskView];
    }
    
    _mainCardUserInteraction = enabled;
}

- (UIViewController *)currentCard {
    return [self.cards objectAtIndex:self.currentCardId];
}

- (NSMutableArray *)cards {
    //alloc/init an array first if its nil
    if (!_cards) {
        NSNull *myNull = [NSNull null];
        _cards = [[NSMutableArray alloc] initWithObjects:myNull, myNull, myNull, myNull, myNull, nil];
    }
    
    return _cards;
}

- (void)setMainCard:(UIViewController *)card {
    // standard setter
    [self.cards replaceObjectAtIndex:GBCardStackCardTypeMain withObject:card];
    card.cardStackController = self;
    
    // gesture recognisers
    self.panGestureRecognizer.delegate = self;
    self.tapGestureRecognizer.delegate = self;
    [self _attachGestureRecognizersToView:card.view];
    
    // shadow
    [self _updateMainCardShadow];
}

- (void)_updateMainCardShadow {
    UIViewController *mainCard = self.mainCard;
    mainCard.view.layer.masksToBounds = NO;
    mainCard.view.layer.shadowColor = [kDefaultShadowColor CGColor];
    mainCard.view.layer.shadowRadius = kDefaultShadowRadius;
    mainCard.view.layer.shadowOpacity = kDefaultShadowOpacity;
    mainCard.view.layer.shadowPath = [UIBezierPath bezierPathWithRect:mainCard.view.bounds].CGPath;
}

- (GBCardStackController *)mainCard {
    return [self.cards objectAtIndex:GBCardStackCardTypeMain];
}

- (void)setLeftCard:(UIViewController *)card {
    [self.cards replaceObjectAtIndex:GBCardStackCardTypeLeft withObject:card];
    card.cardStackController = self;
}

- (GBCardStackController *)leftCard {
    return [self.cards objectAtIndex:GBCardStackCardTypeLeft];
}

- (void)setRightCard:(UIViewController *)card {
    [self.cards replaceObjectAtIndex:GBCardStackCardTypeRight withObject:card];
    card.cardStackController = self;
}

- (GBCardStackController *)rightCard {
    return [self.cards objectAtIndex:GBCardStackCardTypeRight];
}

- (void)setTopCard:(UIViewController *)card {
    [self.cards replaceObjectAtIndex:GBCardStackCardTypeTop withObject:card];
    card.cardStackController = self;
}

- (GBCardStackController *)topCard {
    return [self.cards objectAtIndex:GBCardStackCardTypeTop];
}

- (void)setBottomCard:(UIViewController *)card {
    [self.cards replaceObjectAtIndex:GBCardStackCardTypeBottom withObject:card];
    card.cardStackController = self;
}

- (GBCardStackController *)bottomCard {
    return [self.cards objectAtIndex:GBCardStackCardTypeBottom];
}

#pragma mark - View lifecycle

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    // if we have a main card
    if ([self _cardWithIdentifier:GBCardStackCardTypeMain]) {
        // and it's not in our view hierarchy when we appear
        if (!self.mainCard.view.superview) {
            // then add the card
            AddChildViewController(self, self.mainCard);
            self.currentCardId = GBCardStackCardTypeMain;
            self.tapGestureRecognizer.enabled = NO;
        }
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
