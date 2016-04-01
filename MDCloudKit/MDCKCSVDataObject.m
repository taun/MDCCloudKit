//
//  MDCKCSVDataObject.m
//  DaisyCloudAdmin
//
//  Created by Taun Chapman on 05/28/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

#import "MDCKCSVDataObject.h"
#import "CHCSVParser.h"

@interface MDCKCSVDataObject ()

@property(nonatomic,strong)CHCSVParser          *parser;
@property(nonatomic,strong)NSMutableArray       *columnHeaders;
@property(nonatomic,strong)NSMutableArray       *columnData;

@end



@implementation MDCKCSVDataObject

+(instancetype)csvDataObjectWithContentsOfCSVURL: (NSURL*)csvURL
{
    return [[[self class] alloc] initWithContentsOfCSVURL: csvURL];
}

- (instancetype)initWithContentsOfCSVURL: (NSURL*)csvURL
{
    self = [super init];
    if (self) {
        _numberOfImportedLines = 0;
        _parser = [[CHCSVParser alloc]initWithContentsOfCSVURL: csvURL];
        _parser.delegate = self;
        [_parser parse];
    }
    return self;
}

- (void)parserDidBeginDocument:(CHCSVParser *)parser
{
    _columnHeaders = [NSMutableArray new];
    _columnData = [NSMutableArray new];
    _numberOfImportedLines = 0;
}

- (void)parserDidEndDocument:(CHCSVParser *)parser
{
    NSMutableDictionary* parsedData = [[NSMutableDictionary alloc]initWithCapacity: self.columnHeaders.count];
    
    NSUInteger index = 0;
    
    for (id key in self.columnHeaders)
    {
        parsedData[key] = [self.columnData[index] copy];
        index++;
    }
    self.parsedColumns = [parsedData copy];
}

- (void)parser:(CHCSVParser *)parser didBeginLine:(NSUInteger)recordNumber
{
    self.numberOfImportedLines = recordNumber;
}

- (void)parser:(CHCSVParser *)parser didEndLine:(NSUInteger)recordNumber
{
    if (recordNumber == 1)
    {   // headers done
        NSUInteger columns = self.columnHeaders.count;
        
        for (int i = 0; i < columns; i++)
        {
            [self.columnData addObject: [NSMutableArray new]];
        }
    }
}

- (void)parser:(CHCSVParser *)parser didReadField:(NSString *)field atIndex:(NSInteger)fieldIndex
{
    if (self.numberOfImportedLines == 1)
    {   // header
        [self.columnHeaders addObject: field];
    }
    else
    {   // data
        [self.columnData[fieldIndex] addObject: field];
    }
}

- (void)parser:(CHCSVParser *)parser didReadComment:(NSString *)comment
{
    // ignore comments
}

- (void)parser:(CHCSVParser *)parser didFailWithError:(NSError *)error
{
    DDLogError(@"DaisySensorLog CSV Parse error: %@", error);
}

@end
