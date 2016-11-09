# NSTiffSplitter
by Anton Sharrp Furin - http://sharrp.blogspot.com


## How to use it

NSTiffSplitter is an Objective-C class which allow you to show multipage TIFF files on iPad / iPhone / iPod Touch. Use it in two steps:

1. Create NSTiffSplitter instance:
```objc
- (id) initWithData:(NSData *)imgData;
```
or
```objc
- (id) initWithImageUrl:(NSURL *)imgUrl usingMapping:(BOOL)usingMapping;
```
Second method always use mapping.
2. Get any page of tiff file with next method:
```
- (NSData *) dataForImage:(NSUInteger)imageIndex;
```
It returns monopage tiff file for every page of multipage tiff file.

You can get count of images in file with countOfImages property.

## Installation

### CocoaPods

[CocoaPods](http://cocoapods.org) is a dependency manager for Cocoa projects. You can install it with the following command:

```bash
$ gem install cocoapods
```

To integrate NSTiffSplitter into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '10.0'
use_frameworks!

target '<Your Target Name>' do
    pod 'NSTiffSplitter', '~> 1.0'
end
```

Then, run the following command:

```bash
$ pod install
```

Anton Sharrp Furin  
Web: http://sharrp.blogspot.com  
Twitter: http://twitter.com/5hr
