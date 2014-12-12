//
//  GBCardStackAnalyticsModule.h
//  Goonbee Cardstack
//
//  Created by Luka Mirošević on 12/12/2014.
//  Copyright (c) 2012 Goonbee. All rights reserved.
//

#import "GBCardStackController.h"

@interface GBCardStackAnalyticsModule : NSObject <GBCardStackDelegate>

/**
 Creates a new instance which will name and send all events to GBAnalytics, on the specified route. If you pass nil for route, then the defaul route will be used.
 */
- (instancetype)initWithGBAnalyticsRoute:(NSString *)route;

@end