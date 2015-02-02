//
//  GBCardStackController.m
//  Goonbee Cardstack
//
//  Created by Luka Mirošević on 15/01/2012.
//  Copyright (c) 2012 Goonbee. All rights reserved.
//

#import "GBCardStackController.h"

#import <QuartzCore/QuartzCore.h>

#import <GBToolbox/GBToolbox.h>

static double const CardOverlapDistanceHorizontal =                 56;// the distance that the main card covers the card below in case of left and right cards
static double const CardOverlapDistanceVertical =                   52;// the distance that the main card covers the card below in case of top and bottom cards

// magic numbers for the animations
static double const HorizontalMinimumAutoSlideSpeed =               500;
static double const HorizontalMaximumAutoSlideSpeed =               1400;
static double const HorizontalAutoSlideSpeed =                      1000;
static double const VerticalMinimumAutoSlideSpeed =                 700;
static double const VerticalMaximumAutoSlideSpeed =                 1800;
static double const VerticalAutoSlideSpeed =                        1700;

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
@property (assign, nonatomic) CGVector                              lastOffset;
@property (strong, nonatomic) UIView                                *maskView;
@property (assign, nonatomic, readwrite) BOOL                       isPanning;

@property (assign, nonatomic) CGVector                              mainCardOffset;
@property (strong, nonatomic) NSLayoutConstraint                    *horizontalConstraint;
@property (strong, nonatomic) NSLayoutConstraint                    *verticalConstraint;

@end

@implementation GBCardStackController

#pragma mark - Card Stack interactions

- (void)_notifyDelegateWithDestination:(GBCardStackCardType)destination source:(GBCardStackCardType)source transitionType:(GBCardStackCardTransitionType)transitionType {
    if ([self.delegate respondsToSelector:@selector(GBCardStackController:didShowCard:fromPreviouslyShownCard:type:)]) {
        [self.delegate GBCardStackController:self didShowCard:destination fromPreviouslyShownCard:source type:transitionType];
    }
}

- (void)showCard:(GBCardStackCardType)targetCardId animated:(BOOL)animated {
    if (targetCardId == GBCardStackCardTypeMain) {
        [self restoreMainCardAnimated:animated];
    }
    else if (!self.busy && !self.lock) {
        if ((self.currentCardId == GBCardStackCardTypeMain) && ([self _cardWithIdentifier:targetCardId])) {
            self.busy = YES;
            
            // notify delegate
            [self _notifyDelegateWithDestination:targetCardId source:self.currentCardId transitionType:GBCardStackCardTransitionTypeProgrammatic];

            CGVector offset = [self _targetOffsetForMainCardToShowCard:targetCardId];
            
            if (animated) {
                // insert bottom card into view hierarchy
                [self _loadCard:targetCardId];
            
                // calculate animation duration
                NSTimeInterval animationDuration;
                            
                if ((targetCardId == GBCardStackCardTypeTop) || (targetCardId == GBCardStackCardTypeBottom)) {
                    animationDuration = (self.view.frame.size.height-CardOverlapDistanceVertical)/VerticalAutoSlideSpeed;
                }
                else {
                    animationDuration = (self.view.frame.size.width-CardOverlapDistanceHorizontal)/HorizontalAutoSlideSpeed;
                }
                
                self.mainCardUserInteraction = NO;
                
                [self.view layoutIfNeeded];
                [UIView animateWithDuration:animationDuration delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                    // animate top card sliding over
                    self.mainCardOffset = offset;
                    [self.mainCard.view layoutIfNeeded];
                } completion:^(BOOL finished) {
                    // set current card as new card
                    self.currentCardId = targetCardId;
                    self.tapGestureRecognizer.enabled = YES;
                    
                    self.busy = NO;
                }];
            }
            else {
                [self _loadCard:targetCardId];
                
                self.mainCardUserInteraction = NO;
                
                // update the constraints
                self.mainCardOffset = offset;
                
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
        self.busy = YES;
        
        //find which card is underneath
        GBCardStackCardType lowerCardId;
        
        //find out distance to home base
        CGFloat distanceToHome;
        
        //if its horizontal
        if (self.panDirection == GBGestureHorizontalPan) {
            // find out if its left or right
            CGFloat x = self.lastOffset.dx;
            if (x >= 0) {
                lowerCardId = GBCardStackCardTypeLeft;
            }
            else {
                lowerCardId = GBCardStackCardTypeRight;
            }
            
            distanceToHome = fabs(x);
        }
        else if (self.panDirection == GBGestureVerticalPan) {
            // find out it its up or down
            CGFloat y = self.lastOffset.dy;
            if (y >= 0) {
                lowerCardId = GBCardStackCardTypeTop;
            }
            else {
                lowerCardId = GBCardStackCardTypeBottom;
            }
            
            distanceToHome = fabs(y);
        }
        else {
            return;
        }
        
        // notify delegate
        [self _notifyDelegateWithDestination:GBCardStackCardTypeMain source:lowerCardId transitionType:GBCardStackCardTransitionTypeProgrammatic];
        
        if (animated) {
            //calculate animation duration
            NSTimeInterval animationDuration;
            if (self.panDirection == GBGestureHorizontalPan) {
                animationDuration = distanceToHome/HorizontalMinimumAutoSlideSpeed;
            }
            else {
                animationDuration = distanceToHome/VerticalMinimumAutoSlideSpeed;
            }
            
            [self.view layoutIfNeeded];
            [UIView animateWithDuration:animationDuration delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                // animate top card sliding over
                self.mainCardOffset = CGVectorMake(0., 0.);
                [self.mainCard.view layoutIfNeeded];
            } completion:^(BOOL finished) {
                RemoveChildViewController([self _cardWithIdentifier:lowerCardId]);
                self.currentCardId = GBCardStackCardTypeMain;
                self.tapGestureRecognizer.enabled = NO;
                self.mainCardUserInteraction = YES;
                self.panGestureRecognizer.enabled = NO;
                self.panGestureRecognizer.enabled = YES;
                self.busy = NO;
            }];
        }
        else {
            // update the constraints
            self.mainCardOffset = CGVectorMake(0., 0.);
            
            RemoveChildViewController([self _cardWithIdentifier:lowerCardId]);
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
            // calculate animation duration
            NSTimeInterval animationDuration;
            if ((self.currentCardId == GBCardStackCardTypeTop) || (self.currentCardId == GBCardStackCardTypeBottom)) {
                animationDuration = (self.view.frame.size.height-CardOverlapDistanceVertical)/VerticalAutoSlideSpeed;
            }
            else {
                animationDuration = (self.view.frame.size.width-CardOverlapDistanceHorizontal)/HorizontalAutoSlideSpeed;
            }
            
            [self.view layoutIfNeeded];
            [UIView animateWithDuration:animationDuration delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                // animate top card sliding over
                self.mainCardOffset = CGVectorMake(0., 0.);
                [self.mainCard.view layoutIfNeeded];
            } completion:^(BOOL finished) {
                RemoveChildViewController(self.currentCard);
                self.currentCardId = GBCardStackCardTypeMain;
                self.tapGestureRecognizer.enabled = NO;
                self.mainCardUserInteraction = YES;
                self.busy = NO;
            }];
        }
        else {
            // update the constraints
            self.mainCardOffset = CGVectorMake(0., 0.);
            
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
        // manage panning state
        if ((sender.state == UIGestureRecognizerStateBegan) || (sender.state == UIGestureRecognizerStateChanged)) {
            self.isPanning = YES;
        }
        else {
            self.isPanning = NO;
        }
        
        CGPoint velocity = [sender velocityInView:self.view];
        CGPoint translation = [sender translationInView:self.view];
        
        // find out which dimension
        if (sender.state == UIGestureRecognizerStateBegan) {
            // horizontal
            if (fabs(velocity.x) > fabs(velocity.y)) {
                self.panDirection = GBGestureHorizontalPan;
            }
            // vertical
            else {            
                self.panDirection = GBGestureVerticalPan;
            }
        }
        
        // calculate potential newFrame for mainCard
        CGVector currentOffset = self.mainCardOffset;
        CGVector newOffset = currentOffset;
        if (self.panDirection == GBGestureHorizontalPan) {
            newOffset.dx += translation.x;
        }
        else if (self.panDirection == GBGestureVerticalPan) {
            newOffset.dy += translation.y;
        }
        [sender setTranslation:CGPointMake(0, 0) inView:self.view];
        
        // based on position work out target, then based on velocity work out whether to go forward or backward
        CGVector targetOffset;
        CGFloat distanceRemaining;
        CGFloat targetSpeed;
        GBCardStackCardType targetCardId;
        BOOL forward = YES;
        
        if (self.panDirection == GBGestureVerticalPan) {
            // top card domain
            if (newOffset.dy >= 0) {
                targetOffset = [self _targetOffsetForMainCardToShowCard:GBCardStackCardTypeTop];
                distanceRemaining = fabs(targetOffset.dy - currentOffset.dy);
                targetSpeed = fabs(velocity.y);
                targetCardId = GBCardStackCardTypeTop;
                if (velocity.y < 0) {
                    forward = NO;
                }
            }
            // bottom card domain
            else {
                targetOffset = [self _targetOffsetForMainCardToShowCard:GBCardStackCardTypeBottom];
                distanceRemaining = fabs(targetOffset.dy - currentOffset.dy);
                targetSpeed = fabs(velocity.y);
                targetCardId = GBCardStackCardTypeBottom;
                if (velocity.y > 0) {
                    forward = NO;
                }
            }
        }
        else {
            // left card domain
            if (newOffset.dx >= 0) {
                targetOffset = [self _targetOffsetForMainCardToShowCard:GBCardStackCardTypeLeft];
                distanceRemaining = fabs(targetOffset.dx - currentOffset.dx);
                targetSpeed = fabs(velocity.x);
                targetCardId = GBCardStackCardTypeLeft;
                if (velocity.x < 0) {
                    forward = NO;
                }
            }
            // right card domain
            else {
                targetOffset = [self _targetOffsetForMainCardToShowCard:GBCardStackCardTypeRight];
                distanceRemaining = fabs(targetOffset.dx - currentOffset.dx);
                targetSpeed = fabs(velocity.x);
                targetCardId = GBCardStackCardTypeRight;
                if (velocity.x > 0) {
                    forward = NO;
                }
            }
        }
            
        // check to see if that movement is valid, movements can't be "diagonal" and target can't be nil
        BOOL isValidMove = NO;
        
        switch (self.currentCardId) {
            case GBCardStackCardTypeMain: {
                isValidMove = YES;
            } break;
                
            case GBCardStackCardTypeLeft: {
                if (self.panDirection == GBGestureHorizontalPan) {
                    isValidMove = YES;
                }
            } break;
                
            case GBCardStackCardTypeRight: {
                if (self.panDirection == GBGestureHorizontalPan) {
                    isValidMove = YES;
                }
            } break;
                
            case GBCardStackCardTypeTop: {
                if (self.panDirection == GBGestureVerticalPan) {
                    isValidMove = YES;
                }
            } break;
                
            case GBCardStackCardTypeBottom: {
                if (self.panDirection == GBGestureVerticalPan) {
                    isValidMove = YES;
                }
            } break;
        }

        // check if targetcard is not nil
        if (![self _cardWithIdentifier:targetCardId]) {
            isValidMove = NO;
            //cancel the gesture
            self.panGestureRecognizer.enabled = NO;
            self.panGestureRecognizer.enabled = YES;
        }
        
        // if move isnt valid, return early
        if (!isValidMove) return;
        
        
        /* Following section moves the card and changes state, shud only go here if haven't returned early yet ie if move is valid */
            
        // make sure target card is loaded
        if (sender.state != UIGestureRecognizerStateCancelled) {
            [self _loadCard:targetCardId];
        }
        // if the gesture is cancelled, reset the main card to top where it should be
        else {
            // force default frame
            self.mainCardOffset = CGVectorMake(0., 0.);
            [self _loadCard:GBCardStackCardTypeMain];
        }
        
        // dragging: commit the change
        if (sender.state == UIGestureRecognizerStateChanged) {
            self.mainCardOffset = newOffset;
            self.lastOffset = newOffset;
        }
        // finished dragging: finish gesture
        else if ((sender.state == UIGestureRecognizerStateEnded) || (sender.state == UIGestureRecognizerStateFailed)) {
            //adjust slide speed
            if (self.panDirection == GBGestureHorizontalPan) {
                targetSpeed = ThresholdCGFloat(targetSpeed, HorizontalMinimumAutoSlideSpeed, HorizontalMaximumAutoSlideSpeed);
            }
            else {
                targetSpeed = ThresholdCGFloat(targetSpeed, VerticalMinimumAutoSlideSpeed, VerticalMaximumAutoSlideSpeed);
            }
            
            //calculate animation duration
            NSTimeInterval animationDuration = distanceRemaining/targetSpeed;
                    
            //commit animations
            [self.view layoutIfNeeded];
            [UIView animateWithDuration:animationDuration delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                self.panGestureRecognizer.enabled = NO;
                self.busy = YES;
                
                // animate
                if (forward) {
                    self.mainCardOffset = targetOffset;
                }
                else {
                    self.mainCardOffset = CGVectorMake(0., 0.);
                }
                
                [self.view layoutIfNeeded];
            } completion:^(BOOL finished) {
                // set current card id at end of animation
                if (forward) {
                    // notify delegate
                    [self _notifyDelegateWithDestination:targetCardId source:self.currentCardId transitionType:GBCardStackCardTransitionTypePan];
                    
                    self.currentCardId = targetCardId;
                    self.tapGestureRecognizer.enabled = YES;
                    self.mainCardUserInteraction = NO;
                }
                else {
                    // notify delegate
                    [self _notifyDelegateWithDestination:GBCardStackCardTypeMain source:self.currentCardId transitionType:GBCardStackCardTransitionTypePan];
                    
                    
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
                // notify delegate
                [self _notifyDelegateWithDestination:GBCardStackCardTypeMain source:self.currentCardId transitionType:GBCardStackCardTransitionTypeTapOnEdge];
                
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

#pragma mark - Private

- (CGVector)_targetOffsetForMainCardToShowCard:(GBCardStackCardType)card {
    return [self _targetOffsetForMainCardToShowCard:card swappingWidthHeight:NO];
}

- (CGVector)_targetOffsetForMainCardToShowCard:(GBCardStackCardType)card swappingWidthHeight:(BOOL)shouldSwap {
    CGFloat width = !shouldSwap ? self.view.bounds.size.width : self.view.bounds.size.height;
    CGFloat height = !shouldSwap ? self.view.bounds.size.height : self.view.bounds.size.width;
    
    switch (card) {
        case GBCardStackCardTypeLeft: {
            return CGVectorMake((width - CardOverlapDistanceHorizontal),
                                0.);
        } break;
            
        case GBCardStackCardTypeRight: {
            return CGVectorMake(-(width - CardOverlapDistanceHorizontal),
                                0.);
        } break;
            
        case GBCardStackCardTypeTop: {
            return CGVectorMake(0.,
                                (height - CardOverlapDistanceVertical));
        } break;
            
        case GBCardStackCardTypeBottom: {
            return CGVectorMake(0.,
                                -(height - CardOverlapDistanceVertical));
        } break;
            
        case GBCardStackCardTypeMain: {
            return CGVectorMake(0.,
                                0.);
        } break;
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
    UIViewController *newCard = [self _cardWithIdentifier:cardIdentifier];
    if (!newCard.view.superview) {
        AddChildViewController(self, newCard);// adds the child viewcontroller
        AutoLayout(newCard.view);// turn on auto layout for the child VC
        [self.view bringSubviewToFront:self.mainCard.view];// ensures that the main one is on top
        
        // if it's the main card
        if (cardIdentifier == GBCardStackCardTypeMain) {
            // create our offset constraints
            self.horizontalConstraint = [NSLayoutConstraint constraintWithItem:newCard.view attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterX multiplier:1. constant:0.];
            self.verticalConstraint = [NSLayoutConstraint constraintWithItem:newCard.view attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterY multiplier:1. constant:0.];

            // add the constraints to the view
            [self.view addConstraints:@[
                self.horizontalConstraint,// horizontal offset
                self.verticalConstraint,// vertical offset
                [NSLayoutConstraint constraintWithItem:self.view attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:newCard.view attribute:NSLayoutAttributeWidth multiplier:1. constant:0.],// equal width
                [NSLayoutConstraint constraintWithItem:self.view attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:newCard.view attribute:NSLayoutAttributeHeight multiplier:1. constant:0.],// equal height
            ]];
        }
        // all other cards
        else {
            // add the full width and height constraints
            [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[newCard]|" options:0 metrics:nil views:@{@"newCard": newCard.view}]]; // full width
            [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[newCard]|" options:0 metrics:nil views:@{@"newCard": newCard.view}]]; // full height
        }
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

- (void)_updateMainCardShadow {
    UIViewController *mainCard = self.mainCard;
    mainCard.view.layer.masksToBounds = NO;
    mainCard.view.layer.shadowColor = [kDefaultShadowColor CGColor];
    mainCard.view.layer.shadowRadius = kDefaultShadowRadius;
    mainCard.view.layer.shadowOpacity = kDefaultShadowOpacity;
    mainCard.view.layer.shadowPath = [UIBezierPath bezierPathWithRect:mainCard.view.bounds].CGPath;
    mainCard.view.layer.rasterizationScale = [[UIScreen mainScreen] scale];
    mainCard.view.layer.shouldRasterize = YES;
}

#pragma mark - Accessors

- (void)setMainCardOffset:(CGVector)offset {
    self.horizontalConstraint.constant = offset.dx;
    self.verticalConstraint.constant = offset.dy;
}

- (CGVector)mainCardOffset {
    return CGVectorMake(self.horizontalConstraint.constant, self.verticalConstraint.constant);
}

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
    
    // load the card, this attaches the constraints to it and makes sure it's in the view hierarchy
    [self _loadCard:GBCardStackCardTypeMain];
    
    // gesture recognisers
    self.panGestureRecognizer.delegate = self;
    self.tapGestureRecognizer.delegate = self;
    [self _attachGestureRecognizersToView:card.view];
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
            [self _loadCard:GBCardStackCardTypeMain];
            self.currentCardId = GBCardStackCardTypeMain;
            self.tapGestureRecognizer.enabled = NO;
        }
    }
}

- (void)viewDidLayoutSubviews {
    [self _updateMainCardShadow];
    
    [super viewDidLayoutSubviews];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    // if we are staying in portrait -> portrait, or landscape -> landscape, then we should not swap, other we should.
    BOOL shouldSwap = UIInterfaceOrientationIsPortrait(self.interfaceOrientation) != UIInterfaceOrientationIsPortrait(toInterfaceOrientation);
    
    // this one adds support for rotations, but we need to calculate the target offset for the destination orientation, so we manage the swapping here
    self.mainCardOffset = [self _targetOffsetForMainCardToShowCard:self.currentCardId swappingWidthHeight:shouldSwap];
}

@end
