//
//  NSTiffSplitter
//
//  Created by Sharrp on 09.05.11.
//  Copyright 2011 Anton Furin http://twitter.com/thesharrp All rights reserved.
//

#import <Foundation/Foundation.h>

#define MAX_DEFINED_TYPE 6 // Max allowed to copying field's tag's type. For now, 1-6 tags supported

@interface NSTiffSplitter : NSObject 
{
    NSData *data; // data from tiff file
    
    Byte *sizeOfTypes; // array with sizes of tags types (from TIFF 6.0 specification)
    
    BOOL isBigEndian; // in little-endian we used inverted order of bytes
    int countOfImages;
    int *sizeOfImage; // array with calculated in init method sizes of images
    int *IFDOffsets; // array with IFDs offsets (for every image in tiff file)
}

@property (nonatomic, readonly) int countOfImages; // count of images in tiff file

// initWithPathToImage: always using [NSData initWithContentsOfMappedFile:] for better memory consumption
- (id) initWithPathToImage:(NSString *)imgPath;

// if you use initWithData:usingMapping: with usingMapping = NO entire tiff file will be stored in memory. 
// I recommend to use it with this parameter only for files with size < 3-4 Mb
- (id) initWithData:(NSData *)imgData usingMapping:(BOOL)usingMapping;

- (int) sizeOfImage:(NSUInteger)imageIndex; // size of image in tiff file. Index started from 0
- (NSData *) dataForImage:(NSUInteger)imageIndex; // index also started from 0

@end
