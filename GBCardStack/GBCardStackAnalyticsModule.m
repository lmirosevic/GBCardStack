//
//  GBCardStackAnalyticsModule.m
//  Goonbee Cardstack
//
//  Created by Luka Mirošević on 12/12/2014.
//  Copyright (c) 2012 Goonbee. All rights reserved.
//

static NSString * const kEventName =            @"GBCardStack: Slide card";
static NSString * const kSourceKey =            @"source";
static NSString * const kDestinationKey =       @"destination";
static NSString * const kTypeKey =              @"type";

#import "GBCardStackAnalyticsModule.h"

#import <GBAnalytics/GBAnalytics.h>

@interface GBCardStackAnalyticsModule ()

@property (strong, nonatomic) NSString          *GBAnalyticsRoute;

@end

@implementation GBCardStackAnalyticsModule

#pragma mark - Life

- (instancetype)initWithGBAnalyticsRoute:(NSString *)route {
    if (self = [super init]) {
        self.GBAnalyticsRoute = route ?: kGBAnalyticsDefaultEventRoute;
    }
    
    return self;
}

- (instancetype)init {
    return [self initWithGBAnalyticsRoute:nil];
}

#pragma mark - GBCardStackDelegate

- (void)GBCardStackController:(GBCardStackController *)cardStackController didShowCard:(GBCardStackCardType)targetCard fromPreviouslyShownCard:(GBCardStackCardType)previousCard type:(GBCardStackCardTransitionType)transitionType {
    // send the event to GBAnalytics
    [GBAnalytics[self.GBAnalyticsRoute] trackEvent:kEventName withParameters:@{
        kDestinationKey: [self.class _stringForCardId:targetCard],
        kSourceKey: [self.class _stringForCardId:previousCard],
        kTypeKey: [self.class _stringForTransitionType:transitionType],
    }];

}

#pragma mark - Private

+ (NSString *)_stringForCardId:(GBCardStackCardType)cardId {
    switch (cardId) {
        case GBCardStackCardTypeMain: {
            return @"GBCardStackCardTypeMain";
        } break;
            
        case GBCardStackCardTypeLeft: {
            return @"GBCardStackCardTypeLeft";
        } break;
            
        case GBCardStackCardTypeRight: {
            return @"GBCardStackCardTypeRight";
        } break;
            
        case GBCardStackCardTypeTop: {
            return @"GBCardStackCardTypeTop";
        } break;
            
        case GBCardStackCardTypeBottom: {
            return @"GBCardStackCardTypeBottom";
        } break;
    }
}

+ (NSString *)_stringForTransitionType:(GBCardStackCardTransitionType)transitionType {
    switch (transitionType) {
        case GBCardStackCardTransitionTypeProgrammatic: {
            return @"programmatic";
        } break;
            
        case GBCardStackCardTransitionTypePan: {
            return @"pan";
        } break;
            
        case GBCardStackCardTransitionTypeTapOnEdge: {
            return @"tap on edge";
        } break;
    }
}

@end