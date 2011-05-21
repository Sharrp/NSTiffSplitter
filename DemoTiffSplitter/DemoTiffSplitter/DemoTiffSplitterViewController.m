//
//  DemoTiffSplitterViewController.m
//  DemoTiffSplitter
//
//  Created by Sharrp on 21.05.11.
//  Copyright 2011 Anton Furin. All rights reserved.
//

#import "DemoTiffSplitterViewController.h"

@implementation DemoTiffSplitterViewController

@synthesize tiffPageView, pageIndicatorLabel, nextPageButton, previousPageButton;

- (void)dealloc
{
    [splitter release];
    [tiffPageView release];
    [pageIndicatorLabel release];
    [nextPageButton release];
    [previousPageButton release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void) awakeFromNib
{
    NSString *pathToImage = [[NSBundle mainBundle] pathForResource:@"Example" ofType:@"tiff"];
    splitter = [[NSTiffSplitter alloc] initWithPathToImage:pathToImage];
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (splitter != nil)
    {
        currentImage = 0;
        UIImage *page = [[UIImage alloc] initWithData:[splitter dataForImage:currentImage]];
        tiffPageView.image = page;
        [page release];
        
        pageIndicatorLabel.text = [NSString stringWithFormat:@"%d / %d", currentImage + 1, splitter.countOfImages];
        previousPageButton.enabled = NO;
        if (splitter.countOfImages < 2)
        {
            nextPageButton.enabled = NO;
        }
    }
}

- (void)viewDidUnload
{
    [self setTiffPageView:nil];
    [self setPageIndicatorLabel:nil];
    [self setNextPageButton:nil];
    [self setPreviousPageButton:nil];

    [super viewDidUnload];
}


#pragma mark - Page managing

- (IBAction)showPreviousPage:(id)sender 
{
    if (currentImage > 0)
    {
        --currentImage;
        UIImage *page = [[UIImage alloc] initWithData:[splitter dataForImage:currentImage]];
        tiffPageView.image = page;
        [page release];
        
        pageIndicatorLabel.text = [NSString stringWithFormat:@"%d / %d", currentImage + 1, splitter.countOfImages];
        nextPageButton.enabled = YES;
        if (currentImage == 0)
        {
            previousPageButton.enabled = NO;
        }
    }
}

- (IBAction)showNextPage:(id)sender 
{
    if (currentImage < splitter.countOfImages - 1)
    {
        ++currentImage;
        UIImage *page = [[UIImage alloc] initWithData:[splitter dataForImage:currentImage]];
        tiffPageView.image = page;
        [page release];
        
        pageIndicatorLabel.text = [NSString stringWithFormat:@"%d / %d", currentImage + 1, splitter.countOfImages];
        previousPageButton.enabled = YES;
        if (currentImage == splitter.countOfImages - 1)
        {
            nextPageButton.enabled = NO;
        }
    }
}
@end
