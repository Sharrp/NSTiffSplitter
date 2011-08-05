//
//  NSTiffSplitter
//
//  Created by Sharrp on 09.05.11.
//  Copyright 2011 Anton Furin http://twitter.com/thesharrp All rights reserved.
//

#import "NSTiffSplitter.h"

@interface NSTiffSplitter()

- (int) valueForBytesAt:(int)offset count:(int)countOfBytes;

@end


@implementation NSTiffSplitter

@synthesize countOfImages;

- (id) initWithData:(NSData *)imgData usingMapping:(BOOL)usingMapping
{
    if (imgData == nil)
    {
        return nil;
    }
    
    if (usingMapping)
    {
        NSString *tempPath = [NSTemporaryDirectory() stringByAppendingFormat:@"/tiff_splitter.tiff"];
        [imgData writeToFile:tempPath atomically:NO];
        data = [[NSData alloc] initWithContentsOfMappedFile:tempPath];
    }
    else
    {
        data = [imgData retain];
    }
    
    self = [super init];
    if (self)
    { 
        // Define order of bytes
        if ('M' == [self valueForBytesAt:0 count:1])
        {
            isBigEndian = YES;
        }
        else
        {
            isBigEndian = NO; // little-endian
        }
        
        // Check - is it a tiff file
        if (42 != [self valueForBytesAt:2 count:2])
        {
            [data release];
            return nil;
        }
        
        // Counting images
        countOfImages = 0;
        int ifdOffset = [self valueForBytesAt:4 count:4];
        while (ifdOffset != 0)
        {
            ++countOfImages;
            int countOfFields = [self valueForBytesAt:ifdOffset count:2];
            ifdOffset = [self valueForBytesAt:ifdOffset+2+12*countOfFields count:4];
        }
        
        // Calculate sizes of images and all IFD's offsets
        if (countOfImages > 0)
        {
            sizeOfTypes = (Byte *)malloc(sizeof(Byte) * (MAX_DEFINED_TYPE + 1));
            sizeOfTypes[0] = 0; // just to be sure that all will be ok
            sizeOfTypes[1] = 1; // BYTE
            sizeOfTypes[2] = 1; // ASCII
            sizeOfTypes[3] = 2; // SHORT
            sizeOfTypes[4] = 4; // LONG
            sizeOfTypes[5] = 8; // RATIONAL
            sizeOfTypes[6] = 1; // SBYTE
            
            sizeOfImage = (int *)malloc(countOfImages * sizeof(int));
            IFDOffsets = (int *)malloc(countOfImages * sizeof(int));
            
            IFDOffsets[0] = [self valueForBytesAt:4 count:4];
            int countOfFields = [self valueForBytesAt:IFDOffsets[0] count:2];
            for (int i = 0; i < countOfImages; ++i)
            {
                if (i > 0)
                {
                    IFDOffsets[i] = [self valueForBytesAt:IFDOffsets[i-1]+2+12*countOfFields count:4];
                    countOfFields = [self valueForBytesAt:IFDOffsets[i] count:2];
                }
                
                sizeOfImage[i] = 8 + 2 + 12 * countOfFields + 4; // header + count of fields + fields + offset of next IFD (4 bytes of zeros)
                for (int j = 0; j < countOfFields; ++j)
                {
                    
                    int tag = [self valueForBytesAt:IFDOffsets[i]+2+12*j count:2];
                    int tagType = [self valueForBytesAt:IFDOffsets[i]+2+12*j+2 count:2];
                    int countOfElements = [self valueForBytesAt:IFDOffsets[i]+2+12*j+4 count:4];
                    
                    int bytesInField = sizeOfTypes[tagType] * countOfElements;
                    if (bytesInField > 4)
                    {
                        sizeOfImage[i] += bytesInField;
                    }
                    
                    if (tag == 279) // strip byte counts
                    {
                        int stripBytesOffset = [self valueForBytesAt:IFDOffsets[i]+2+12*j+8 count:4];
                        
                        if (bytesInField > 4)
                        {
                            for (int k = 0; k < countOfElements; ++k)
                            {
                                sizeOfImage[i] += [self valueForBytesAt:stripBytesOffset+sizeOfTypes[tagType]*k count:sizeOfTypes[tagType]];
                            }
                        }
                        else
                        {
                            sizeOfImage[i] += stripBytesOffset; //in this case it's not offset - it's value
                        }
                    }
                }
            }
        }
    } 
    else
    {
        [data release];
    }
    return self;
}

- (id) initWithPathToImage:(NSString *)imgPath
{
    NSData *imgData = [[NSData alloc] initWithContentsOfMappedFile:imgPath];   
    self = [self initWithData:imgData usingMapping:NO];
    [imgData release];
    return self;
}

- (void)dealloc 
{
    if (countOfImages > 0)
    {
        free(sizeOfTypes);
        free(sizeOfImage);
        free(IFDOffsets);
    }
    
    [data release];
    
    [super dealloc];
}


#pragma mark - Info methods

- (int) sizeOfImage:(NSUInteger)imageIndex
{
    if (imageIndex >= countOfImages)
    {
        return -1;
    }
    else
    {
        return sizeOfImage[imageIndex];
    }
}


#pragma mark - Splitting methods

- (NSData *) dataForImage:(NSUInteger)imageIndex
{
    if (imageIndex >= countOfImages)
    {
        return nil;
    }
    
    NSMutableData *oneData = [[NSMutableData alloc] initWithLength:sizeOfImage[imageIndex]];
 
    // Copy header
    Byte *buffer = (Byte *)malloc(4);
    [data getBytes:buffer length:4];
    [oneData replaceBytesInRange:NSMakeRange(0, 4) withBytes:buffer];
    free(buffer);
    
    // change offset of 1st IFD in header    
    int var = isBigEndian ? 134217728 : 8; // 134217728 = (as hex) 08 00 00 00
    [oneData replaceBytesInRange:NSMakeRange(4, 4) withBytes:&var];
	
	// How much fields we will transfer to new file
    int ifdOffset = IFDOffsets[imageIndex];
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
    buffer[isBigEndian ? 0 : 1] = (properFields >> 8) & 255;
    buffer[isBigEndian ? 1 : 0] = properFields & 255;
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
            
            int bytesToCopy = sizeOfTypes[[self valueForBytesAt:fieldOffset+2 count:2]] * [self valueForBytesAt:fieldOffset+4 count:4];
            if (bytesToCopy > 4) // in field's value/offset we can store only 4 bytes or offset of real data
            {                    
                // Write tag, type and count of field without changes
                buffer = (Byte *)malloc(8);
                [data getBytes:buffer range:NSMakeRange(fieldOffset, 8)];
                [oneData replaceBytesInRange:NSMakeRange(10+12*newOneFieldNumber, 8) withBytes:buffer];
                free(buffer);
                
                // Write offset of field's value
                buffer = (Byte *)malloc(4);
                buffer[isBigEndian ? 0 : 3] = (largeValueOffset >> 24) & 255;
                buffer[isBigEndian ? 1 : 2] = (largeValueOffset >> 16) & 255;
                buffer[isBigEndian ? 2 : 1] = (largeValueOffset >> 8) & 255;
                buffer[isBigEndian ? 3 : 0] = largeValueOffset & 255;
                [oneData replaceBytesInRange:NSMakeRange(10+12*newOneFieldNumber + 8, 4) withBytes:buffer];
                free(buffer);
                
                // copy data to largeValueOffset (copy large value from old place to new)
                buffer = (Byte *)malloc(bytesToCopy);
                [data getBytes:buffer range:NSMakeRange([self valueForBytesAt:fieldOffset+8 count:4], bytesToCopy)];
                [oneData replaceBytesInRange:NSMakeRange(largeValueOffset, bytesToCopy) withBytes:buffer];
                free(buffer);
                
                largeValueOffset += bytesToCopy;
            }
            else
            {
                buffer = (Byte *)malloc(12);
                [data getBytes:buffer range:NSMakeRange(fieldOffset, 12)];
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
    buffer[isBigEndian ? 0 : 3] = (largeValueOffset >> 24) & 255;
    buffer[isBigEndian ? 1 : 2] = (largeValueOffset >> 16) & 255;
    buffer[isBigEndian ? 2 : 1] = (largeValueOffset >> 8) & 255;
    buffer[isBigEndian ? 3 : 0] = largeValueOffset & 255;
    [oneData replaceBytesInRange:NSMakeRange(stripOffsetsTagNew + 8, 4) withBytes:buffer];
    free(buffer);
    
    if (countOfStripes == 1)
    {        
        int stripBytesCount = stripBytesCountOffset;
        int stripOffset = offsetOfStripsOffsets;
        
        // Write data
        buffer = (Byte *)malloc(stripBytesCount);
        [data getBytes:buffer range:NSMakeRange(stripOffset, stripBytesCount)];
        [oneData replaceBytesInRange:NSMakeRange(largeValueOffset, stripBytesCount) withBytes:buffer];
        free(buffer);
        
        // Write offset of strip        
        buffer = (Byte *)malloc(4);
        buffer[isBigEndian ? 0 : 3] = (largeValueOffset >> 24) & 255;
        buffer[isBigEndian ? 1 : 2] = (largeValueOffset >> 16) & 255;
        buffer[isBigEndian ? 2 : 1] = (largeValueOffset >> 8) & 255;
        buffer[isBigEndian ? 3 : 0] = largeValueOffset & 255;
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
            [data getBytes:buffer range:NSMakeRange(stripOffset, stripBytesCount)];
            [oneData replaceBytesInRange:NSMakeRange(largeValueOffset, stripBytesCount) withBytes:buffer];
            free(buffer);
            
            // Write offset of strip        
            buffer = (Byte *)malloc(4);
            buffer[isBigEndian ? 0 : 3] = (largeValueOffset >> 24) & 255;
            buffer[isBigEndian ? 1 : 2] = (largeValueOffset >> 16) & 255;
            buffer[isBigEndian ? 2 : 1] = (largeValueOffset >> 8) & 255;
            buffer[isBigEndian ? 3 : 0] = largeValueOffset & 255;
            [oneData replaceBytesInRange:NSMakeRange(arrayOfStripsOffsets, 4) withBytes:buffer];
            free(buffer);
            
            largeValueOffset += stripBytesCount;
            arrayOfStripsOffsets += 4;
        }
    }
        
    // Set proper size of new data
    [oneData setLength:largeValueOffset];
    
    return [oneData autorelease];
}


#pragma mark - Auxiliary methods

- (int) valueForBytesAt:(int)offset count:(int)countOfBytes
{
    Byte *buffer = (Byte *)malloc(countOfBytes);
    [data getBytes:buffer range:NSMakeRange(offset, countOfBytes)];
    
    if (!isBigEndian && countOfBytes > 1)
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