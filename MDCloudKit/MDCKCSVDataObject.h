//
//  MDCKCSVDataObject.h
//  DaisyCloudAdmin
//
//  Created by Taun Chapman on 05/28/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CHCSVParser.h"

/*!
 Encapsulate parsing of CSV file
 */
@interface MDCKCSVDataObject : NSObject <CHCSVParserDelegate>

/*!
 Dictionary keyed by CSV column header with arrays of data.
 */
@property(nonatomic,strong)NSDictionary*    parsedColumns;
/*!
 Number of lines imported from CSV file. Used to iterate through arrays simultaneously.
 */
@property(nonatomic,assign)NSUInteger           numberOfImportedLines;

+(instancetype)csvDataObjectWithContentsOfCSVURL: (NSURL*)csvURL;

-(instancetype)initWithContentsOfCSVURL: (NSURL*)csvURL;

- (void)parserDidBeginDocument:(CHCSVParser *)parser;

/**
 *  Indicates that the parser has successfully finished parsing the stream
 *
 *  This method is not invoked if any error is encountered
 *
 *  @param parser The @c CHCSVParser instance
 */
- (void)parserDidEndDocument:(CHCSVParser *)parser;

/**
 *  Indicates the parser has started parsing a line
 *
 *  @param parser       The @c CHCSVParser instance
 *  @param recordNumber The 1-based number of the record
 */
- (void)parser:(CHCSVParser *)parser didBeginLine:(NSUInteger)recordNumber;

/**
 *  Indicates the parser has finished parsing a line
 *
 *  @param parser       The @c CHCSVParser instance
 *  @param recordNumber The 1-based number of the record
 */
- (void)parser:(CHCSVParser *)parser didEndLine:(NSUInteger)recordNumber;

/**
 *  Indicates the parser has parsed a field on the current line
 *
 *  @param parser     The @c CHCSVParser instance
 *  @param field      The parsed string. If configured to do so, this string may be sanitized and trimmed
 *  @param fieldIndex The 0-based index of the field within the current record
 */
- (void)parser:(CHCSVParser *)parser didReadField:(NSString *)field atIndex:(NSInteger)fieldIndex;

/**
 *  Indicates the parser has encountered a comment
 *
 *  This method is only invoked if @c CHCSVParser.recognizesComments is @c YES
 *
 *  @param parser  The @c CHCSVParser instance
 *  @param comment The parsed comment
 */
- (void)parser:(CHCSVParser *)parser didReadComment:(NSString *)comment;

/**
 *  Indicates the parser encounter an error while parsing
 *
 *  @param parser The @c CHCSVParser instance
 *  @param error  The @c NSError instance
 */
- (void)parser:(CHCSVParser *)parser didFailWithError:(NSError *)error;

@end
