//
//  DemoTiffSplitterViewController.h
//  DemoTiffSplitter
//
//  Created by Sharrp on 21.05.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "NSTiffSplitter.h"

@interface DemoTiffSplitterViewController : UIViewController 
{
    NSTiffSplitter *splitter;
    NSUInteger currentImage;
    
    UIImageView *tiffPageView;
    UILabel *pageIndicatorLabel;
    UIBarButtonItem *nextPageButton;
    UIBarButtonItem *previousPageButton;
}

@property (nonatomic, retain) IBOutlet UIImageView *tiffPageView;
@property (nonatomic, retain) IBOutlet UILabel *pageIndicatorLabel;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *nextPageButton;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *previousPageButton;

- (IBAction)showPreviousPage:(id)sender;
- (IBAction)showNextPage:(id)sender;

@end
