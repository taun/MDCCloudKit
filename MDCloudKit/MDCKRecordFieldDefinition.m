//
//  MDCKRecordFieldDefinition.m
//  DaisyCloudAdmin
//
//  Created by Taun Chapman on 05/26/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

#import "MDCKRecordFieldDefinition.h"
@import CloudKit;


@interface MDCKRecordFieldDefinition ()
+(id)transformData: (id)data usingTransformerNamed: (NSString*)transformerName;
@end

@implementation MDCKRecordFieldDefinition

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"

+(id)transformData: (id)data usingTransformerNamed: (NSString*)transformerName
{
    id returnValue;
    
    if ([[self class] respondsToSelector: NSSelectorFromString(transformerName)])
    {
        returnValue = [[self class] performSelector: NSSelectorFromString(transformerName) withObject: data];
    }

    return returnValue;
}

#pragma clang diagnostic pop


+(NSString*)transformToLower: (NSString*)data
{
    return [data lowercaseString];
}

+(NSString*)trimWhiteSpace:(NSString *)data
{
    return [data stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
}

+(NSNumber*)stringToNumber: (NSString*)data
{
    NSNumber* numVal;
    if (data && data.length > 0) numVal = [NSNumber numberWithDouble: [data doubleValue]];
    
    return numVal;
}

+(NSNumber*)farenheitToCelsius: (NSNumber*)data
{
    NSNumber* numVal;
    
    if (data)
    {
        double farenheit = [data doubleValue];
        
        double celsius = (farenheit - 32.0) * 5.0/9.0;
        numVal = [NSNumber numberWithDouble: celsius];
    }
    return numVal;
}

+(NSArray *)spaceSeparatedToArray:(NSString *)data
{
    NSArray* rVal;
    
    if (data && data.length > 0)
    {
        NSArray* tempArray = [data componentsSeparatedByCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
        NSMutableArray* culledArray = [NSMutableArray arrayWithCapacity: tempArray.count];
        for (NSString* item in tempArray)
        {
            if (item && item.length > 0)
            {
                [culledArray addObject: item];
            }
        }
        rVal = [culledArray copy];
    }
    return rVal;
}

+(NSArray *)commaSeparatedToArray:(NSString *)data
{
    NSArray* rVal;
    
    if (data && data.length > 0)
    {
        NSArray* tempArray = [data componentsSeparatedByString: @","];
        NSMutableArray* trimmedArray = [NSMutableArray arrayWithCapacity: tempArray.count];
        for (NSString* item in tempArray)
        {
            [trimmedArray addObject: [item stringByTrimmingCharactersInSet:[ NSCharacterSet whitespaceCharacterSet]]];
        }
        rVal = [trimmedArray copy];
    }
    return rVal;
}

-(void)encodeWithCoder:(NSCoder *)aCoder
{
    if (_csvColumnIdentifier) [aCoder encodeObject: self.csvColumnIdentifier forKey: @"csvColumnIdentifier"];
    if (_fieldKeyString) [aCoder encodeObject: self.fieldKeyString forKey: @"fieldKeyString"];
    if (_dataClass)
    {
        NSString* classString = NSStringFromClass(self.dataClass);
        [aCoder encodeObject: classString forKey: @"dataClassString"];
    }
    if (_dataTransformers) [aCoder encodeObject: self.dataTransformers forKey: @"dataTransformers"];
}

-(instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self) {
        
        [self decodeVersion1WithCoder:  aDecoder];
        
    }
    //    NSLog(@"Loaded Fractal: %@",self.name);
    return self;
}

-(void) decodeVersion1WithCoder: (NSCoder*)aDecoder
{
    _csvColumnIdentifier = [aDecoder decodeObjectForKey: @"csvColumnIdentifier"];
    _fieldKeyString = [aDecoder decodeObjectForKey: @"fieldKeyString"];
    NSString* classString = [aDecoder decodeObjectForKey: @"dataClassString"];
    if (classString && classString.length > 0)
    {
        _dataClass = NSClassFromString(classString);
    }
}

-(id)applyTransformersTo:(id)data
{
    id inputData = data;
    id transformedData = data;
    
    for (NSString* transformerName in self.dataTransformers)
    {
        transformedData = [[self class]transformData: inputData usingTransformerNamed: transformerName];
        
        if (!transformedData)
        {
            break;
        }
        
        inputData = transformedData;
    }
    return transformedData;
}

-(CKReference *)referenceRecordForIdentifier:(NSString *)identifier
{
    CKReference* reference;
    if (self.potentialReferenceRecordsArray.count > 0)
    {
        for (CKRecord* record in self.potentialReferenceRecordsArray)
        {
            if ([record[self.referenceRecordKey] isEqualToString: identifier])
            {
                reference = [[CKReference alloc]initWithRecord: record action: CKReferenceActionNone];
                break;
            }
        }
    }
    
    return reference;
}

@end
