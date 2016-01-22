//
//  NSTiffSplitter
//
//  Created by Sharrp on 09.05.11.
//  Copyright 2011 Anton Furin http://twitter.com/thesharrp All rights reserved.
//

#import "NSTiffSplitter.h"

@interface NSTiffSplitter()

- (int) valueForBytesAt:(int)offset count:(int)countOfBytes;

@property (nonatomic, strong) NSData *data; // data from tiff file
    
@property (nonatomic) NSMutableArray *sizeOfTypes; // array with sizes of tags types (from TIFF 6.0 specification)
    
@property (nonatomic) BOOL isBigEndian; // in little-endian we used inverted order of bytes
@property (nonatomic) NSMutableArray *sizeOfImage; // array with calculated in init method sizes of images
@property (nonatomic) NSMutableArray *IFDOffsets; // array with IFDs offsets (for every image in tiff file)

@end


@implementation NSTiffSplitter

- (id) initWithData:(NSData *)imgData
{
    if (imgData == nil)
    {
        return nil;
    }
    
    self.data = imgData;
    self.sizeOfTypes = [[NSMutableArray alloc] init];
    self.sizeOfImage = [[NSMutableArray alloc] init];
    self.IFDOffsets =[[NSMutableArray alloc] init];
    
    self = [super init];
    if (self)
    { 
        // Define order of bytes
        if ('M' == [self valueForBytesAt:0 count:1])
        {
            self.isBigEndian = YES;
        }
        else
        {
            self.isBigEndian = NO; // little-endian
        }
        
        // Check - is it a tiff file
        if (42 != [self valueForBytesAt:2 count:2])
        {
            return nil;
        }
        
        // Counting images
        self.countOfImages = 0;
        int ifdOffset = [self valueForBytesAt:4 count:4];
        while (ifdOffset != 0)
        {
            ++self.countOfImages;
            int countOfFields = [self valueForBytesAt:ifdOffset count:2];
            ifdOffset = [self valueForBytesAt:ifdOffset+2+12*countOfFields count:4];
        }
        
        // Calculate sizes of images and all IFD's offsets
        if (self.countOfImages > 0)
        {
            //self.sizeOfTypes = (Byte *)malloc(sizeof(Byte) * (MAX_DEFINED_TYPE + 1));
            self.sizeOfTypes[0] = @0; // just to be sure that all will be ok
            self.sizeOfTypes[1] = @1; // BYTE
            self.sizeOfTypes[2] = @1; // ASCII
            self.sizeOfTypes[3] = @2; // SHORT
            self.sizeOfTypes[4] = @4; // LONG
            self.sizeOfTypes[5] = @8; // RATIONAL
            self.sizeOfTypes[6] = @1; // SBYTE
            self.sizeOfTypes[7] = @1; // UNDEFINED
            self.sizeOfTypes[8] = @2; // SSHORT
            self.sizeOfTypes[9] = @4; // SLONG
            self.sizeOfTypes[10] = @8; // SRATIONAL
            self.sizeOfTypes[11] = @4; // SINGLE FLOAT
            self.sizeOfTypes[12] = @8; // DOUBLE FLOAT
            
            //self.sizeOfImage = (int *)malloc(self.countOfImages * sizeof(int));
            //self.IFDOffsets = (int *)malloc(self.countOfImages * sizeof(int));
            
            self.IFDOffsets[0] = [NSNumber numberWithInt:[self valueForBytesAt:4 count:4]];
            int countOfFields = [self valueForBytesAt:[self.IFDOffsets[0] intValue] count:2];
            for (int i = 0; i < self.countOfImages; ++i)
            {
                if (i > 0)
                {
                    self.IFDOffsets[i] = [NSNumber numberWithInt:[self valueForBytesAt:[self.IFDOffsets[i-1] intValue]+2+12*countOfFields count:4]];
                    countOfFields = [self valueForBytesAt:[self.IFDOffsets[i] intValue] count:2];
                }
                
                self.sizeOfImage[i] = [NSNumber numberWithInt:8 + 2 + 12 * countOfFields + 4]; // header + count of fields + fields + offset of next IFD (4 bytes of zeros)
                for (int j = 0; j < countOfFields; ++j)
                {
                    
                    int tag = [self valueForBytesAt:[self.IFDOffsets[i] intValue]+2+12*j count:2];
                    int tagType = [self valueForBytesAt:[self.IFDOffsets[i] intValue]+2+12*j+2 count:2];
                    int countOfElements = [self valueForBytesAt:[self.IFDOffsets[i] intValue]+2+12*j+4 count:4];
                    
                    int bytesInField = [self.sizeOfTypes[tagType] intValue] * countOfElements;
                    if (bytesInField > 4)
                    {
                        int newValue = [self.sizeOfImage[i] intValue] + bytesInField;
                        self.sizeOfImage[i] = [NSNumber numberWithInt:newValue];
                    }
                    
                    if (tag == 279) // strip byte counts
                    {
                        int stripBytesOffset = [self valueForBytesAt:[self.IFDOffsets[i] intValue]+2+12*j+8 count:4];
                        
                        if (bytesInField > 4)
                        {
                            for (int k = 0; k < countOfElements; ++k)
                            {
                                int newValue = [self.sizeOfImage[i] intValue] + [self valueForBytesAt:stripBytesOffset+[self.sizeOfTypes[tagType] intValue]*k count:[self.sizeOfTypes[tagType] intValue]];
                                self.sizeOfImage[i] = [NSNumber numberWithInt:newValue];
                            }
                        }
                        else
                        {
                            int newValue = [self.sizeOfImage[i] intValue] + stripBytesOffset;
                            self.sizeOfImage[i] = [NSNumber numberWithInt:newValue]; //in this case it's not offset - it's value
                        }
                    }
                }
            }
        }
    } 

    return self;
}

- (id) initWithImageUrl:(NSURL *)imgUrl usingMapping:(BOOL)usingMapping
{
    NSData *imgData;
    
    if (usingMapping) {
        NSString *tempPath = [NSTemporaryDirectory() stringByAppendingFormat:@"/tiff_splitter.tiff"];
        [imgData writeToFile:tempPath atomically:NO];
        NSError *exception = nil;
        imgData = [[NSData alloc] initWithContentsOfURL:imgUrl options:NSDataReadingMappedAlways error:&exception];
        if (exception != nil) {
            NSLog([NSString stringWithFormat:@"%@ exception: description %@, reason %@", NSStringFromSelector(_cmd), exception.localizedDescription, exception.localizedFailureReason]);
        }
    } else {
        imgData = [[NSData alloc] initWithContentsOfURL:imgUrl];
    }
    
    self = [self initWithData:imgData];
    return self;
}

- (void)dealloc 
{
    if (self.countOfImages > 0)
    {
        self.sizeOfTypes = nil;
        self.sizeOfImage = nil;
        self.IFDOffsets = nil;
    }
}


#pragma mark - Info methods

- (int) sizeOfImage:(NSUInteger)imageIndex
{
    if (imageIndex >= self.countOfImages)
    {
        return -1;
    }
    else
    {
        return [self.sizeOfImage[imageIndex] intValue];
    }
}


#pragma mark - Splitting methods

- (NSData *) dataForImage:(NSUInteger)imageIndex
{
    if (imageIndex >= self.countOfImages)
    {
        return nil;
    }
    
    NSMutableData *oneData = [[NSMutableData alloc] initWithLength:[self.sizeOfImage[imageIndex] intValue]];
 
    // Copy header
    Byte *buffer = (Byte *)malloc(4);
    [self.data getBytes:buffer length:4];
    [oneData replaceBytesInRange:NSMakeRange(0, 4) withBytes:buffer];
    free(buffer);
    
    // change offset of 1st IFD in header    
    int var = self.isBigEndian ? 134217728 : 8; // 134217728 = (as hex) 08 00 00 00
    [oneData replaceBytesInRange:NSMakeRange(4, 4) withBytes:&var];
	
	// How much fields we will transfer to new file
    int ifdOffset = [self.IFDOffsets[imageIndex] intValue];
	int fieldsCount = [self valueForBytesAt:ifdOffset count:2];    
    int properFields = 0;
    for (int i = 0; i < fieldsCount; ++i)
    {
        int fieldOffset = ifdOffset + 2 + 12 * i;
        if ([self valueForBytesAt:fieldOffset+2 count:2] < MAX_DEFINED_TYPE + 1)
        {
            ++properFields;
        }
    }   
    
    // write count of fields in IFD in new file
    buffer = (Byte *)malloc(2);
    buffer[self.isBigEndian ? 0 : 1] = (properFields >> 8) & 255;
    buffer[self.isBigEndian ? 1 : 0] = properFields & 255;
    [oneData replaceBytesInRange:NSMakeRange(8, 2) withBytes:buffer];
    free(buffer);
    
    // Offset of next IFD is 0
    var = 0;
    [oneData replaceBytesInRange:NSMakeRange(8 + 2 + properFields * 12, 4) withBytes:&var];
	
	int largeValueOffset = 14 + properFields * 12; // 8 + 2 + properFieldsCount * 12 + 4; place where we will store large data (> 4 bytes)
    
    int stripOffsetsTagOld = 0, stripOffsetsTagNew = 0;
    int stripByteCountsTagOld = 0;
    int newOneFieldNumber = 0;
    int sizeOf_countOfBytesInStrip_type = 0;
	for (int i = 0; i < fieldsCount; ++i)
	{
        int fieldOffset = ifdOffset + 2 + 12 * i;
		if ([self valueForBytesAt:fieldOffset+2 count:2] < MAX_DEFINED_TYPE + 1)
		{
			if ([self valueForBytesAt:fieldOffset count:2] == 273) // handle strip offsets
			{
                stripOffsetsTagOld = fieldOffset;
                stripOffsetsTagNew = 10 + newOneFieldNumber * 12;
            }
            else if ([self valueForBytesAt:fieldOffset count:2] == 279)
            {
                stripByteCountsTagOld = fieldOffset;
                sizeOf_countOfBytesInStrip_type = [self valueForBytesAt:fieldOffset+2 count:2];
            }
            
            int bytesToCopy = [self.sizeOfTypes[[self valueForBytesAt:fieldOffset+2 count:2]] intValue] * [self valueForBytesAt:fieldOffset+4 count:4];
            if (bytesToCopy > 4) // in field's value/offset we can store only 4 bytes or offset of real data
            {                    
                // Write tag, type and count of field without changes
                buffer = (Byte *)malloc(8);
                [self.data getBytes:buffer range:NSMakeRange(fieldOffset, 8)];
                [oneData replaceBytesInRange:NSMakeRange(10+12*newOneFieldNumber, 8) withBytes:buffer];
                free(buffer);
                
                // Write offset of field's value
                buffer = (Byte *)malloc(4);
                buffer[self.isBigEndian ? 0 : 3] = (largeValueOffset >> 24) & 255;
                buffer[self.isBigEndian ? 1 : 2] = (largeValueOffset >> 16) & 255;
                buffer[self.isBigEndian ? 2 : 1] = (largeValueOffset >> 8) & 255;
                buffer[self.isBigEndian ? 3 : 0] = largeValueOffset & 255;
                [oneData replaceBytesInRange:NSMakeRange(10+12*newOneFieldNumber + 8, 4) withBytes:buffer];
                free(buffer);
                
                // copy data to largeValueOffset (copy large value from old place to new)
                buffer = (Byte *)malloc(bytesToCopy);
                [self.data getBytes:buffer range:NSMakeRange([self valueForBytesAt:fieldOffset+8 count:4], bytesToCopy)];
                [oneData replaceBytesInRange:NSMakeRange(largeValueOffset, bytesToCopy) withBytes:buffer];
                free(buffer);
                
                largeValueOffset += bytesToCopy;
            }
            else
            {
                buffer = (Byte *)malloc(12);
                [self.data getBytes:buffer range:NSMakeRange(fieldOffset, 12)];
                [oneData replaceBytesInRange:NSMakeRange(10+12*newOneFieldNumber, 12) withBytes:buffer];
                free(buffer);
            }
            
            ++newOneFieldNumber;
		}
	}    
    
    // Rewrite all strip offsets    
    int countOfStripes = [self valueForBytesAt:stripOffsetsTagOld+4 count:4];
    int offsetOfStripsOffsets = [self valueForBytesAt:stripOffsetsTagOld+8 count:4];
    int stripBytesCountOffset = [self valueForBytesAt:stripByteCountsTagOld+8 count:4];
    
    // Write tag with strip offset (or offset of array with stripes's offsets)
    buffer = (Byte *)malloc(4);
    buffer[self.isBigEndian ? 0 : 3] = (largeValueOffset >> 24) & 255;
    buffer[self.isBigEndian ? 1 : 2] = (largeValueOffset >> 16) & 255;
    buffer[self.isBigEndian ? 2 : 1] = (largeValueOffset >> 8) & 255;
    buffer[self.isBigEndian ? 3 : 0] = largeValueOffset & 255;
    [oneData replaceBytesInRange:NSMakeRange(stripOffsetsTagNew + 8, 4) withBytes:buffer];
    free(buffer);
    
    if (countOfStripes == 1)
    {        
        int stripBytesCount = stripBytesCountOffset;
        int stripOffset = offsetOfStripsOffsets;
        
        // Write data
        buffer = (Byte *)malloc(stripBytesCount);
        [self.data getBytes:buffer range:NSMakeRange(stripOffset, stripBytesCount)];
        [oneData replaceBytesInRange:NSMakeRange(largeValueOffset, stripBytesCount) withBytes:buffer];
        free(buffer);
        
        // Write offset of strip        
        buffer = (Byte *)malloc(4);
        buffer[self.isBigEndian ? 0 : 3] = (largeValueOffset >> 24) & 255;
        buffer[self.isBigEndian ? 1 : 2] = (largeValueOffset >> 16) & 255;
        buffer[self.isBigEndian ? 2 : 1] = (largeValueOffset >> 8) & 255;
        buffer[self.isBigEndian ? 3 : 0] = largeValueOffset & 255;
        [oneData replaceBytesInRange:NSMakeRange(stripOffsetsTagNew + 8, 4) withBytes:buffer];
        free(buffer);
        
        largeValueOffset += stripBytesCount;
    }
    else
    {        
        // Write correct offset of stripsOffsets 
        int arrayOfStripsOffsets = largeValueOffset;
        largeValueOffset += 4 * countOfStripes;
        for (int j = 0; j < countOfStripes; ++j)
        {
            int stripBytesCount = [self valueForBytesAt:stripBytesCountOffset+4*j count:4];
            int stripOffset = [self valueForBytesAt:offsetOfStripsOffsets+4*j count:4];
            
            // Write data
            buffer = (Byte *)malloc(stripBytesCount);
            [self.data getBytes:buffer range:NSMakeRange(stripOffset, stripBytesCount)];
            [oneData replaceBytesInRange:NSMakeRange(largeValueOffset, stripBytesCount) withBytes:buffer];
            free(buffer);
            
            // Write offset of strip        
            buffer = (Byte *)malloc(4);
            buffer[self.isBigEndian ? 0 : 3] = (largeValueOffset >> 24) & 255;
            buffer[self.isBigEndian ? 1 : 2] = (largeValueOffset >> 16) & 255;
            buffer[self.isBigEndian ? 2 : 1] = (largeValueOffset >> 8) & 255;
            buffer[self.isBigEndian ? 3 : 0] = largeValueOffset & 255;
            [oneData replaceBytesInRange:NSMakeRange(arrayOfStripsOffsets, 4) withBytes:buffer];
            free(buffer);
            
            largeValueOffset += stripBytesCount;
            arrayOfStripsOffsets += 4;
        }
    }
        
    // Set proper size of new data
    [oneData setLength:largeValueOffset];
    
    return oneData;
}


#pragma mark - Auxiliary methods

- (int) valueForBytesAt:(int)offset count:(int)countOfBytes
{
    Byte *buffer = (Byte *)malloc(countOfBytes);
    [self.data getBytes:buffer range:NSMakeRange(offset, countOfBytes)];
    
    if (!self.isBigEndian && countOfBytes > 1)
    {
        // Revert bytes
        for (int i = 0; i < countOfBytes / 2; ++i)
        {
            Byte tmp = buffer[i];
            buffer[i] = buffer[countOfBytes-i-1];
            buffer[countOfBytes-i-1] = tmp;
        }
    }
    
    int value = buffer[0];
    for (int i = 1; i < countOfBytes; ++i)
    {
        value <<= 8;
        value |= buffer[i];
    }
    free(buffer);
    return value;
}

@end
