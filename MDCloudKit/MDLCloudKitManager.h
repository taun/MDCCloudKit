//  Created by Taun Chapman on 09/15/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

@import Foundation;
@import UIKit;
@import CloudKit;

/*!
 Local interface to the CloudKit api
 
 Mostly copied from Apple sample but not liked.
 */
@interface MDLCloudKitManager : NSObject

@property(nonatomic,strong)NSArray                              *defaultSortDescriptors;
@property(nonatomic,strong)NSString                             *cloudSubscriptionIDKey;
@property(nonatomic,weak)CKOperation                            *currentOperation;
@property (nonatomic, readonly, getter=isCloudAvailable) BOOL   cloudAvailable;
@property(nonatomic,readonly) NSCache                           *resourceCache;

-(instancetype)initWithIdentifier: (NSString*)containerIdentifier andRecordType: (NSString*)cloudKitRecordType;


#pragma mark - CloudKit
- (void)requestDiscoverabilityPermission:(void (^)(BOOL discoverable))completionHandler;
- (void)discoverUserInfo:(void (^)(CKUserIdentity *user))completionHandler;

- (void)uploadAssetWithURL:(NSURL *)assetURL completionHandler:(void (^)(CKRecord *record))completionHandler;
- (void)addRecordWithName:(NSString *)name location:(CLLocation *)location completionHandler:(void (^)(CKRecord *record))completionHandler;

/*!
 CloudKit query method using NSCache for storing retrieved images
 
 @param key               image asset key
 @param recordID          recordName of record with image asset
 @param completionHandler block for retrieved image assignment
 */
- (void)fetchImageAsset: (NSString*)key forRecordWithID:(NSString *)recordID completionHandler:(void (^)(UIImage *image))completionHandler;
/*!
 Standard CloudKit record query
 
 @param recordID          recordName
 @param completionHandler block for retirieved record.
 */
- (void)fetchRecordWithID:(NSString *)recordID completionHandler:(void (^)(CKRecord *record))completionHandler;
- (void)fetchRecordsWithIDs:(NSArray *)recordIDObjects desiredKeys: (NSArray*)keys qualityOfService: (NSQualityOfService)quality perRecordHandler: (void (^)(CKRecord *record, CKRecordID *recordID, NSError *error))perRecordHandler completionHandler:(void (^)(NSDictionary *recordsByRecordID, NSError *operationError))completionHandler;
- (void)queryForRecordsNearLocation:(CLLocation *)location completionHandler:(void (^)(NSArray *records))completionHandler;

- (void)savePublicRecord:(CKRecord *)record withCompletionHandler:(void (^)(NSError* error))completionHandler;
- (void)savePublicRecords:(NSArray *)records qualityOfService: (NSQualityOfService)quality withCompletionHandler:(void (^)(NSError *error))completionHandler;

- (void)deletePublicRecord:(CKRecord *)record;
- (void)deletePublicRecords:(NSArray *)records withCompletionHandler:(void (^)(NSError *error))completionHandler;

/*!
 Convenience method for fetchPublicRecordsWithType: which substitutes the initialized recordType for type.
 
 @param predicate         query predicate
 @param descriptors       sort descriptors
 @param cloudKeys         cloudKeys for properties to fetch
 @param completionHandler what to do with the results
 */
- (CKQueryOperation*)fetchPublicRecordsWithPredicate: (NSPredicate*)predicate sortDescriptors: (NSArray*) descriptors cloudKeys: (NSArray*)cloudKeys qualityOfService: (NSQualityOfService)quality resultLimit: (NSUInteger)limit perRecordBlock:(void (^)(CKRecord *record))recordBlock completionHandler:(void (^)(CKQueryCursor *cursor, NSError* error))completionHandler;
/*!
 Query to run on the CloudKit app public container.
 
 @param recordType        CloudKit record type
 @param predicate         query predicate
 @param descriptors       sort descriptors
 @param cloudKeys         cloudKeys for properties to fetch
 @param completionHandler what to do with the results
 */
- (CKQueryOperation*)fetchPublicRecordsWithType:(NSString *)recordType predicate: (NSPredicate*)predicate sortDescriptors: (NSArray*) descriptors cloudKeys: (NSArray*)cloudKeys qualityOfService: (NSQualityOfService)quality perRecordBlock:(void (^)(CKRecord *record))recordBlock completionHandler:(void (^)(CKQueryCursor *cursor, NSError* error))completionHandler;
- (CKQueryOperation*)fetchPublicRecordsWithType:(NSString *)recordType predicate: (NSPredicate*)predicate sortDescriptors: (NSArray*) descriptors cloudKeys: (NSArray*)cloudKeys qualityOfService: (NSQualityOfService)quality resultLimit: (NSUInteger)limit perRecordBlock:(void (^)(CKRecord *record))recordBlock completionHandler:(void (^)(CKQueryCursor *cursor, NSError* error))completionHandler;
/*!
 Fetch the next record set
 
 @param cursor cursor returned from a previous incomplete fetch
 
 @return the CKQueryOperation
 */
- (CKQueryOperation*)fetchNextRecordWithCursor: (CKQueryCursor*)cursor;
/*!
 Cancel the CKQueroperation returned above.
 
 @param operation operation to cancel
 */
- (void)cancelOperation: (CKQueryOperation*)operation;
/*!
 Convenience method for fetching the record references
 
 @param referenceRecordName item referenced
 @param completionHandler   what to do with it
 */
- (void)queryForPublicRecordsWithReferenceNamed:(NSString *)referenceRecordName qualityOfService: (NSQualityOfService)quality completionHandler:(void (^)(NSArray *records))completionHandler;

@property (nonatomic, readonly, getter=isSubscribed) BOOL subscribed;
- (void)subscribe;
- (void)unsubscribe;

@end

//CKFractalRecordType
//@[CKFractalRecordNameField,CKFractalRecordDescriptorField,CKFractalRecordFractalDefinitionAssetField,CKFractalRecordFractalThumbnailAssetField]
// CKFractalRecordSubscriptionIDkey
