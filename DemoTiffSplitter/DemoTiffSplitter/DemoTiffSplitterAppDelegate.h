//
//  DemoTiffSplitterAppDelegate.h
//  DemoTiffSplitter
//
//  Created by Sharrp on 21.05.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DemoTiffSplitterViewController;

@interface DemoTiffSplitterAppDelegate : NSObject <UIApplicationDelegate> {

}

@property (nonatomic, retain) IBOutlet UIWindow *window;

@property (nonatomic, retain) IBOutlet DemoTiffSplitterViewController *viewController;

@end
