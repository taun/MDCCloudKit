//
//  MDCKRecordFieldDefinition.h
//  DaisyCloudAdmin
//
//  Created by Taun Chapman on 05/26/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CKReference;

typedef id(^valueTransformBlock)(id value);

@interface MDCKRecordFieldDefinition : NSObject

/*!
 NSString of the column in the CSV file
 */
@property NSString                                          *csvColumnIdentifier;
/*!
 NSString of the key for the cloud attribute definition
 */
@property NSString                                          *fieldKeyString;
/*!
 Whether the field is a reference field and so needs the recordIDs
 */
@property (getter=isReference) BOOL                         reference;
/*!
 CKRecordType for getting potential reference records
 */
@property NSString                                          *referenceRecordType;
/*!
 Key in the reference record to match to the imported csv value
 */
@property NSString                                          *referenceRecordKey;
/*!
 NSArray of fetched records which need to be searched for a reference record
 */
@property NSArray                                           *potentialReferenceRecordsArray;
/*!
 Data type of the cloud information
 */
@property Class                                             dataClass;
/*!
 Method name of data transformer
 */
@property NSArray                                          *dataTransformers;


+(NSString*)transformToLower: (NSString*)data;
+(NSString*)trimWhiteSpace: (NSString*)data;
+(NSNumber*)stringToNumber: (NSString*)data;
+(NSNumber*)farenheitToCelsius: (NSNumber*)data;
+(NSArray*)spaceSeparatedToArray: (NSString*)data;
+(NSArray*)commaSeparatedToArray: (NSString*)data;

-(id)applyTransformersTo: (id)data;

-(CKReference*)referenceRecordForIdentifier: (NSString*)identifier;

@end
