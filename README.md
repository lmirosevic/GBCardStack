GBCardStack
============

Sliding card UI paradigm for iOS. Currently used by "VLC iRemote" on the App Store.

Similar to the "sliding main view" in the Facebook and Path apps, except it supports all 4 directions, manages autohiding properly, supports sliding by: pan gesture, tap gesture and programatically.

https://itunes.apple.com/us/app/vlc-iremote-lite-remote-control/id509476881?ls=1&mt=8

Usage
------------

First import header:

```objective-c
#import "GBCardStackController.h"
```

Get your view controllers (shown here when initialised from a nib, could also create them programatically or from a storyboard):

```objective-c
LeftViewController *leftViewController = [[LeftViewController alloc] initWithNibName:@"LeftViewController" bundle:nil];
MainViewController *mainViewController = [[MainViewController alloc] initWithNibName:@"MainViewController" bundle:nil];
TopViewController *topViewController = [[TopViewController alloc] initWithNibName:@"TopViewController" bundle:nil];
RightViewController *rightViewController = [[RightViewController alloc] initWithNibName:@"RightViewController" bundle:nil];
```

Create a GBCardStackController instance and add the *cards* to it:

```objective-c
GBCardStackController *cardStackController = [[GBCardStackController alloc] init];

cardStackController.leftCard = leftViewController;
cardStackController.mainCard = mainViewController;
cardStackController.topCard = topViewController;
cardStackController.rightCard = rightViewController; 
cardStackController.bottomCard = leftViewController;
```

Present your GBCardStackController instance like you would any other view controller (shown here as the rootViewController of the window):

```objective-c
self.window.rootViewController = cardStackController;
```

In your view controllers which you place in the card stack, define which views are *slideable*. You should add any `UIView` subclass which responds to `UITouch` events (i.e. has `userInteractionEnabled` set to YES) which you want to still trigger a card slide. If you don't do this then only that `UIView` subclass will receive touch events and it will not cause the underlying card to slide as the user pans. You would normally put any `UIButton`'s in here, but not a `UISlider`. You might need to include `UIViewController+GBCardStack.h` in your UIViewController subclass.

```objective-c
[self.slideableView addObject:self.someButton];
```

Demo project
------------

See: www.github.com/lmirosevic/GBCardStackDemo

Dependencies
------------

Static libraries (Add dependency, link, -ObjC linker flag, header search path in superproject):

* GBToolbox
* GBAnalytics

System Frameworks (link them in):

* CoreGraphics
* QuartzCore
* SystemConfiguration
* CoreData
* libz.dylib

Copyright & License
------------

Copyright 2013 Luka Mirosevic

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this work except in compliance with the License. You may obtain a copy of the License in the LICENSE file, or at:

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.


    







