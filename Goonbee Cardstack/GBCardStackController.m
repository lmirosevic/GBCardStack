//
//  GBCardStackController.m
//  Goonbee Cardstack
//
//  Created by Luka Mirošević on 15/01/2012.
//  Copyright (c) 2012 Goonbee. All rights reserved.
//

#import "GBCardStackController.h"

#import "GBCardViewController.h"

const double GBCardOverlapDistance = 60;
const double GBHorizontalMinimumAutoSlideSpeed = 500;
const double GBHorizontalMaximumAutoSlideSpeed = 1200;
const double GBHorizontalAutoSlideSpeed = 800;

const double GBVerticalMinimumAutoSlideSpeed = 700;
const double GBVerticalMaximumAutoSlideSpeed = 1700;
const double GBVerticalAutoSlideSpeed = 950;

@interface GBCardStackController() {
    NSMutableArray              *_cards;
    BOOL                        _mainCardUserInteraction;
    UIPanGestureRecognizer      *_panGestureRecognizer;
}

@property (nonatomic) GBCardViewCardIdentifier              currentCardId;
@property (nonatomic, strong) UIPanGestureRecognizer        *panGestureRecognizer;
@property (nonatomic) BOOL                                  mainCardUserInteraction;
@property (nonatomic, strong) NSMutableArray                *mainCardUserInteractionEnabledElements;
@property (nonatomic) GBGesturePanDirection                 panDirection;

-(GBCardViewController *)cardWithIdentifier:(GBCardViewCardIdentifier)cardIdentifier;
-(void)loadCard:(GBCardViewCardIdentifier)cardIdentifier;
-(void)handlePan:(UIPanGestureRecognizer *)sender;
-(void)setUserInteractionForObjects:(NSArray *)uiElements toEnabled:(BOOL)enabled;
-(void)collectEnabledUserInteractionObjectsInView:(UIView *)view inArray:(NSMutableArray *)collection;
-(NSMutableArray *)findEnabledUserInteractionObjectsInView:(UIView *)view;

@end


@implementation GBCardStackController

@synthesize panDirection = _panDirection;
@synthesize currentCardId = _currentCardId;
@synthesize mainCardUserInteractionEnabledElements = _mainCardUserInteractionEnabledElements;

#pragma mark - Card Stack interactions

-(void)slideCard:(GBCardViewCardIdentifier)bottomCardId animated:(BOOL)animated {
    if (self.currentCardId == GBCardViewMainCard) {
        
        CGPoint topCardDestinationOrigin;
        switch (bottomCardId) {
            case GBCardViewLeftCard:
                topCardDestinationOrigin = CGPointMake(self.currentCard.view.frame.size.width-GBCardOverlapDistance, self.currentCard.view.frame.origin.y);
                break;
            case GBCardViewRightCard:
                topCardDestinationOrigin = CGPointMake(-self.currentCard.view.frame.size.width+GBCardOverlapDistance, self.currentCard.view.frame.origin.y);
                break;
            case GBCardViewTopCard:
                topCardDestinationOrigin = CGPointMake(self.currentCard.view.frame.origin.x, self.currentCard.view.frame.size.height-GBCardOverlapDistance);
                break;
            case GBCardViewMainCard:
                NSLog(@"Shouldn't animate to oneself");
                break;
        }
        
        if (animated) {
            //insert bottom card as subview
            [self.view insertSubview:[self cardWithIdentifier:bottomCardId].view belowSubview:self.mainCard.view];
        
            //calculate animation duration
            NSTimeInterval animationDuration;
                        
            if (bottomCardId == GBCardViewTopCard) {
                animationDuration = (self.currentCard.view.frame.size.height-GBCardOverlapDistance)/GBVerticalAutoSlideSpeed;
            }
            else {
                animationDuration = (self.currentCard.view.frame.size.width-GBCardOverlapDistance)/GBHorizontalAutoSlideSpeed;
            }
            
            [UIView animateWithDuration:animationDuration delay:0 options:UIViewAnimationCurveEaseInOut animations:^{
                //animate top card sliding over
                self.mainCard.view.frame = CGRectMake(topCardDestinationOrigin.x, topCardDestinationOrigin.y, self.mainCard.view.frame.size.width, self.mainCard.view.frame.size.height);
            } completion:^(BOOL finished) {
                //set currentcard as new card
                self.currentCardId = bottomCardId;
                self.mainCardUserInteraction = NO;
            }];
        }
        else {
            [self.view insertSubview:[self cardWithIdentifier:bottomCardId].view belowSubview:self.mainCard.view];
            
            self.mainCard.view.frame = CGRectMake(topCardDestinationOrigin.x, topCardDestinationOrigin.y, self.mainCard.view.frame.size.width, self.mainCard.view.frame.size.height);
            self.currentCardId = bottomCardId;
            self.mainCardUserInteraction = NO;
        }
    }
    else {
        //foo make sure this works even when setting the card for the first time
        NSLog(@"Main card is not the current card.");
    }
}

-(void)restoreMainCardWithAnimation:(BOOL)animation {
    if (self.currentCardId == GBCardViewMainCard) {
        NSLog(@"Already showing main card.");
    }
    else {
        //restore main card
        if (animation) {
            //calculate animation duration
            NSTimeInterval animationDuration;
            if (self.currentCardId == GBCardViewTopCard) {
                animationDuration = (self.currentCard.view.frame.size.height-GBCardOverlapDistance)/GBVerticalAutoSlideSpeed;
            }
            else {
                animationDuration = (self.currentCard.view.frame.size.width-GBCardOverlapDistance)/GBHorizontalAutoSlideSpeed;
            }
            
            [UIView animateWithDuration:animationDuration delay:0 options:UIViewAnimationCurveEaseInOut animations:^{
                self.mainCard.view.frame = CGRectMake(0, 0, self.mainCard.view.frame.size.width, self.mainCard.view.frame.size.height);
            } completion:^(BOOL finished) {
                [self.currentCard.view removeFromSuperview];
                self.currentCardId = GBCardViewMainCard;
                self.mainCardUserInteraction = YES;
            }];
        }
        else {
            self.mainCard.view.frame = CGRectMake(0, 0, self.mainCard.view.frame.size.width, self.mainCard.view.frame.size.height);
            
            [self.currentCard.view removeFromSuperview];
            self.currentCardId = GBCardViewMainCard;
            self.mainCardUserInteraction = YES;
        }
    }
}

-(void)handlePan:(UIPanGestureRecognizer *)sender {
//    NSLog(@"pan %d", sender.state);
    
    BOOL allGood = YES;
    
    CGPoint velocity = [sender velocityInView:self.view];
    CGPoint translation = [sender translationInView:self.view];
    
    //find out which dimension
    if (sender.state == UIGestureRecognizerStateBegan) {
        CGFloat velX = velocity.x;
        CGFloat velY = velocity.y;
        
        //horizontal
        if (fabs(velX) > fabs(velY)) {
            self.panDirection = GBGestureHorizontalPan;
        }
        //vertical
        else {            
            self.panDirection = GBGestureVerticalPan;
        }
    }
    
    //foo what if someone moves the view exactly onto x=0
    
    //calculate newFrame for mainCard
    CGRect newFrame = self.mainCard.view.frame;
    
    //manage bottom view
    if (self.panDirection == GBGestureHorizontalPan) {
        newFrame.origin.x += translation.x;
        
        //panning to the right
        if (newFrame.origin.x > 0) {
            [self loadCard:GBCardViewLeftCard];
        }
        //panning to the left
        else {
            [self loadCard:GBCardViewRightCard];
        }
    }
    else if (self.panDirection == GBGestureVerticalPan) {
        newFrame.origin.y += translation.y;
        
        //panning down
        if (newFrame.origin.y > 0) {
            [self loadCard:GBCardViewTopCard];
        }
        //panning up
        else {
            allGood = NO;
        }
    }
    
    //if allgood commit the move
    if (allGood) {
        self.mainCard.view.frame = newFrame;
    }

    //finish gesture
    if ((sender.state == UIGestureRecognizerStateEnded) || (sender.state == UIGestureRecognizerStateFailed)) {
        CGPoint targetOrigin;
        CGFloat distanceRemaining;
        CGFloat targetSpeed;
        GBCardViewCardIdentifier targetCardId;
        BOOL forward = YES;
        
        //based on position work out target, then based on velocity work out whether to go forward or backward
        
        //topcard domain
        if ((self.mainCard.view.frame.origin.x == 0) && (self.mainCard.view.frame.origin.y >= 0)) {
            targetOrigin = CGPointMake(self.currentCard.view.frame.origin.x, self.currentCard.view.frame.size.height-GBCardOverlapDistance);
            distanceRemaining = fabs(targetOrigin.y - self.currentCard.view.frame.origin.y);
            targetSpeed = fabs(velocity.y);
            targetCardId = GBCardViewTopCard;
            if (velocity.y < 0) {
                forward = NO;
            }
        }
        //leftcard domain
        else if ((self.mainCard.view.frame.origin.y == 0) && (self.mainCard.view.frame.origin.x >= 0)) {
            targetOrigin = CGPointMake(self.currentCard.view.frame.size.width-GBCardOverlapDistance, self.currentCard.view.frame.origin.y);
            distanceRemaining = fabs(targetOrigin.x - self.currentCard.view.frame.origin.x);
            targetSpeed = fabs(velocity.x);
            targetCardId = GBCardViewLeftCard;
            if (velocity.x < 0) {
                forward = NO;
            }
        }
        //rightcard domain
        else if ((self.mainCard.view.frame.origin.y == 0) && (self.mainCard.view.frame.origin.x < 0)) {
            targetOrigin = CGPointMake(-self.currentCard.view.frame.size.width+GBCardOverlapDistance, self.currentCard.view.frame.origin.y);
            distanceRemaining = fabs(targetOrigin.x - self.currentCard.view.frame.origin.x);
            targetSpeed = fabs(velocity.x);
            targetCardId = GBCardViewRightCard;
            if (velocity.x > 0) {
                forward = NO;
            }
        }
        
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
                self.currentCardId = targetCardId;
                self.mainCardUserInteraction = NO;
            }
            else {
                self.currentCardId = GBCardViewMainCard;
                self.mainCardUserInteraction = YES;
            }
            
            self.panGestureRecognizer.enabled = YES;
        }];
    }
    
    [sender setTranslation:CGPointMake(0, 0) inView:self.view];
}

#pragma mark - Convenience

-(void)loadCard:(GBCardViewCardIdentifier)cardIdentifier {
    if (![self cardWithIdentifier:cardIdentifier].view.superview) {
        //show card
        [self.view insertSubview:[self cardWithIdentifier:cardIdentifier].view belowSubview:self.mainCard.view];
        
        //hide any other cards except for mainCard in case they are visible
        for (int i=1; i<4; i++) {
            if (i != cardIdentifier) {
                [[self cardWithIdentifier:i].view removeFromSuperview];
            }
        }
    }
}

-(GBCardViewController *)cardWithIdentifier:(GBCardViewCardIdentifier)cardIdentifier {
    return [self.cards objectAtIndex:cardIdentifier];
}

-(void)setUserInteractionForObjects:(NSArray *)uiElements toEnabled:(BOOL)enabled {
    //loop through all views
    for (UIView *view in uiElements) {
        //set its state
        view.userInteractionEnabled = enabled;
    }
}

-(void)collectEnabledUserInteractionObjectsInView:(UIView *)view inArray:(NSMutableArray *)collection {
    for (UIView *subview in view.subviews) {
        if (subview.userInteractionEnabled) {
            [collection addObject:subview];
        }
        
        [self collectEnabledUserInteractionObjectsInView:subview inArray:collection];
    }
}

-(NSMutableArray *)findEnabledUserInteractionObjectsInView:(UIView *)view {
    NSMutableArray *enabledViews = [[NSMutableArray alloc] init];
    
    [self collectEnabledUserInteractionObjectsInView:view inArray:enabledViews];
    
    return enabledViews;
}

#pragma mark - Accessors

-(UIPanGestureRecognizer *)panGestureRecognizer {
    if (!_panGestureRecognizer) {
        _panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    }
    
    return _panGestureRecognizer;
}

-(void)setPanGestureRecognizer:(UIPanGestureRecognizer *)panGestureRecognizer {
    _panGestureRecognizer = panGestureRecognizer;
}

-(NSMutableArray *)mainCardUserInteractionEnabledElements {
    if (!_mainCardUserInteractionEnabledElements) {
        _mainCardUserInteractionEnabledElements = [[NSMutableArray alloc] init];
    }
    
    return _mainCardUserInteractionEnabledElements;
}

-(BOOL)mainCardUserInteraction {
    return _mainCardUserInteraction;
}

-(void)setMainCardUserInteraction:(BOOL)enabled {
    //if already set then return early to prevent overriding the stored ones
    if (enabled == _mainCardUserInteraction) return;
    
    //if true, restore
    if (enabled) {
        [self setUserInteractionForObjects:self.mainCardUserInteractionEnabledElements toEnabled:enabled];
    }
    //if false, find the enabled ones, store them, disable them
    else {
        self.mainCardUserInteractionEnabledElements = [self findEnabledUserInteractionObjectsInView:self.mainCard.view];
        [self setUserInteractionForObjects:self.mainCardUserInteractionEnabledElements toEnabled:enabled];
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
        _cards = [[NSMutableArray alloc] initWithObjects:myNull, myNull, myNull, myNull, nil];
    }
    
    return _cards;
}

-(void)setMainCard:(GBCardViewController *)card {
    [self.cards replaceObjectAtIndex:GBCardViewMainCard withObject:card];
    card.cardStackController = self;
    [card.view addGestureRecognizer:self.panGestureRecognizer];
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

#pragma mark - Memory management

//- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
//{
//    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
//    if (self) {
//        // Custom initialization
//    }
//    return self;
//}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
    self.view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 480)];
    self.view.backgroundColor = [UIColor redColor];
}*/

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self.view addSubview:self.mainCard.view];
    self.currentCardId = GBCardViewMainCard;
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

-(void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

-(void)viewDidLoad {
    [super viewDidLoad];
}

-(void)viewDidUnload {
    [super viewDidUnload];
    
    _cards = nil;
    self.panGestureRecognizer = nil;
    self.mainCardUserInteractionEnabledElements = nil;
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
