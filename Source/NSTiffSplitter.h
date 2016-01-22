//
//  NSTiffSplitter
//
//  Created by Sharrp on 09.05.11.
//  Copyright 2011 Anton Furin http://twitter.com/thesharrp All rights reserved.
//

#import <Foundation/Foundation.h>

#define MAX_DEFINED_TYPE 11 // Max allowed to copying field's tag's type. 1-12 tags supported

@interface NSTiffSplitter : NSObject 

@property (nonatomic) int countOfImages; // count of images in tiff file

// with usingMapping = NO entire tiff file will be stored in memory.
// I recommend to use it with this parameter only for files with size < 3-4 Mb
- (id) initWithImageUrl:(NSURL *)imgUrl usingMapping:(BOOL)usingMapping;

- (id) initWithData:(NSData *)imgData;

- (int) sizeOfImage:(NSUInteger)imageIndex; // size of image in tiff file. Index started from 0
- (NSData *) dataForImage:(NSUInteger)imageIndex; // index also started from 0

@end
