# GBCardStack ![Version](https://img.shields.io/cocoapods/v/GBCardStack.svg?style=flat)&nbsp;![License](https://img.shields.io/badge/license-Apache_2-green.svg?style=flat)

Sliding card UI paradigm for iOS. Currently used by [VLC iRemote](http://www.goonbee.com/apps/vlc-remote) on the [App Store](http://itunes.apple.com/us/app/vlc-remote-hd/id507404442?ls=1&mt=8).

[![Left view](http://luka.s3.amazonaws.com/GBCardStackLeftThumb.png)](http://luka.s3.amazonaws.com/GBCardStackLeft.png)
[![Main view](http://luka.s3.amazonaws.com/GBCardStackMainThumb.png)](http://luka.s3.amazonaws.com/GBCardStackMain.png)
[![Right view](http://luka.s3.amazonaws.com/GBCardStackRightThumb.png)](http://luka.s3.amazonaws.com/GBCardStackRight.png)

Similar to the "sliding main view" in the Facebook and Path apps, except it supports all 4 directions, manages autohiding properly, supports sliding by: pan gesture, tap gesture and programatically.

Usage
------------

First import header:

```objective-c
#import <GBCardStack/GBCardStack.h>"
```

Create a `GBCardStackController` instance and add the *cards* to it (here we add all cards except for on the bottom): 

```objective-c
GBCardStackController *cardStackController = [[GBCardStackController alloc] init];

self.cardStackController.leftCard = [LeftViewController new];
self.cardStackController.mainCard = [MainViewController new];
self.cardStackController.topCard = [TopViewController new];
self.cardStackController.rightCard = [RightViewController new];
```

Present your GBCardStackController instance like you would any other view controller (shown here as the rootViewController of the window):

```objective-c
self.window.rootViewController = cardStackController;
```

In your view controllers which you place in the card stack, define which views are *slideable*. You should add any `UIView` subclass which responds to `UITouch` events (i.e. has `userInteractionEnabled` set to YES) which you want to still trigger a card slide. If you don't do this then only that `UIView` subclass will receive touch events and it will not cause the underlying card to slide as the user pans. You would normally put any `UIButton`'s in here, but not a `UISlider` because you wouldn't want a pan inside a pan. You might need to include `UIViewController+GBCardStack.h` in your UIViewController subclass.

```objective-c
[self.slideableView addObject:self.someButton];
```

Demo project
------------

See: [github.com/lmirosevic/GBCardStackDemo](https://github.com/lmirosevic/GBCardStackDemo)

Dependencies
------------

* [GBToolbox](https://github.com/lmirosevic/GBToolbox)
* [GBAnalytics](https:/github.com/lmirosevic/GBAnalytics)

Copyright & License
------------

Copyright 2015 Luka Mirosevic

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this work except in compliance with the License. You may obtain a copy of the License in the LICENSE file, or at:

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.

[![Bitdeli Badge](https://d2weczhvl823v0.cloudfront.net/lmirosevic/gbcardstack/trend.png)](https://bitdeli.com/free "Bitdeli Badge")
