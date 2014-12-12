//
//  UIViewController+GBCardStack.m
//  Goonbee Cardstack
//
//  Created by Luka Mirošević on 15/01/2012.
//  Copyright (c) 2012 Goonbee. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <objc/runtime.h>

#import "GBCardStackController.h"

@implementation UIViewController (GBCardStack)

#pragma mark - Associated objects

static char const gbSlideableViewsKey;

- (void)setSlideableViews:(NSMutableArray *)slideableViews {
    objc_setAssociatedObject(self, &gbSlideableViewsKey, slideableViews, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSMutableArray *)slideableViews {
    if (!objc_getAssociatedObject(self, &gbSlideableViewsKey)) {
        objc_setAssociatedObject(self, &gbSlideableViewsKey, [[NSMutableArray alloc] init], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    return objc_getAssociatedObject(self, &gbSlideableViewsKey);
}

static char const gbCardStackControllerKey;

- (void)setCardStackController:(GBCardStackController *)cardStackController {
    objc_setAssociatedObject(self, &gbCardStackControllerKey, cardStackController, OBJC_ASSOCIATION_ASSIGN);
}

- (GBCardStackController *)cardStackController {
    return objc_getAssociatedObject(self, &gbCardStackControllerKey);
}

@end
