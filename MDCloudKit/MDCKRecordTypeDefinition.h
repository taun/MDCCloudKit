//  Created by Taun Chapman on 05/26/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

/*!
 Describes the CKRecordTypes and corresponding fields for a CloudKit container.
 This will get saved as a document which can be used for importing and uploading CloudKit schemas and records.
 
 Need a way to edit the schema at some point. Can be hard coded for now.
 */
@interface MDCKRecordTypeDefinition : NSObject

/*!
 CloudKit CKRecordType string
 */
@property NSString                          *typeString;
/*!
 Definition of each field to be stored in the cloud for the recordType
 */
@property(nonatomic) NSMutableSet           *fields;

@end
