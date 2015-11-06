//  Created by Taun Chapman on 09/15/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

@import UIKit;
@import Foundation;
@import CloudKit;

/*!
 Local interface to the CloudKit api
 
 Mostly copied from Apple sample but not liked.
 */
@interface MDLCloudKitManager : NSObject

@property(nonatomic,strong)NSArray      *defaultSortDescriptors;
@property(nonatomic,strong)NSString     *cloudSubscriptionIDKey;

-(instancetype)initWithIdentifier: (NSString*)containerIdentifier andRecordType: (NSString*)cloudKitRecordType;

#pragma mark - CloudKit
- (void)requestDiscoverabilityPermission:(void (^)(BOOL discoverable))completionHandler;
- (void)discoverUserInfo:(void (^)(CKDiscoveredUserInfo *user))completionHandler;

- (void)fetchRecordWithID:(NSString *)recordID completionHandler:(void (^)(CKRecord *record))completionHandler;
- (void)fetchRecordsWithIDs:(NSArray *)recordIDObjects desiredKeys: (NSArray*)keys perRecordHandler: (void (^)(CKRecord *record, CKRecordID *recordID, NSError *error))perRecordHandler completionHandler:(void (^)(NSDictionary *recordsByRecordID, NSError *operationError))completionHandler;
- (void)queryForRecordsNearLocation:(CLLocation *)location completionHandler:(void (^)(NSArray *records))completionHandler;

- (void)savePublicRecord:(CKRecord *)record withCompletionHandler:(void (^)(NSError* error))completionHandler;
- (void)savePublicRecords:(NSArray *)records withCompletionHandler:(void (^)(NSError *error))completionHandler;

- (void)deletePublicRecord:(CKRecord *)record;
- (void)deletePublicRecords:(NSArray *)records withCompletionHandler:(void (^)(NSError *error))completionHandler;

/*!
 Convenience method for fetchPublicRecordsWithType: which substitutes the initialized recordType for type.
 
 @param predicate         query predicate
 @param descriptors       sort descriptors
 @param cloudKeys         cloudKeys for properties to fetch
 @param completionHandler what to do with the results
 */
- (void)fetchPublicRecordsWithPredicate: (NSPredicate*)predicate sortDescriptors: (NSArray*) descriptors cloudKeys: (NSArray*)cloudKeys perRecordBlock:(void (^)(CKRecord *record))recordBlock completionHandler:(void (^)(NSArray *records, NSError* error))completionHandler;
/*!
 Query to run on the CloudKit app public container.
 
 @param recordType        CloudKit record type
 @param predicate         query predicate
 @param descriptors       sort descriptors
 @param cloudKeys         cloudKeys for properties to fetch
 @param completionHandler what to do with the results
 */
- (void)fetchPublicRecordsWithType:(NSString *)recordType predicate: (NSPredicate*)predicate sortDescriptors: (NSArray*) descriptors cloudKeys: (NSArray*)cloudKeys perRecordBlock:(void (^)(CKRecord *record))recordBlock completionHandler:(void (^)(NSArray *records, NSError* error))completionHandler;
/*!
 Convenience method for fetching the record references
 
 @param referenceRecordName item referenced
 @param completionHandler   what to do with it
 */
- (void)queryForPublicRecordsWithReferenceNamed:(NSString *)referenceRecordName completionHandler:(void (^)(NSArray *records))completionHandler;

@property (nonatomic, readonly, getter=isSubscribed) BOOL subscribed;
- (void)subscribe;
- (void)unsubscribe;

@end

//CKFractalRecordType
//@[CKFractalRecordNameField,CKFractalRecordDescriptorField,CKFractalRecordFractalDefinitionAssetField,CKFractalRecordFractalThumbnailAssetField]
// CKFractalRecordSubscriptionIDkey
