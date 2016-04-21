//  Created by Taun Chapman on 09/15/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

@import CloudKit;
@import QuartzCore;


#import "MDLCloudKitManager.h"
#import "NSString+MDKConvenience.h"
#import <Crashlytics/Crashlytics.h>

#define LOG_LEVEL_DEF ddLogLevel
#import <CocoaLumberjack/CocoaLumberjack.h>

#ifdef DEBUG
static const DDLogLevel ddLogLevel = DDLogLevelVerbose;
#else
static const DDLogLevel ddLogLevel = DDLogLevelInfo;
#endif

@interface MDLCloudKitManager ()

@property(nonatomic,strong)NSString     *cloudKitRecordType;
@property (readonly) CKContainer        *container;
@property (readonly) CKDatabase         *publicDatabase;

@end

@implementation MDLCloudKitManager

@synthesize resourceCache = _resourceCache;

-(instancetype)initWithIdentifier:(NSString *)containerIdentifier andRecordType:(NSString *)cloudKitRecordType
{
    self = [super init];
    if (self) {
        if ([containerIdentifier isNonEmptyString])
        {
            _container = [CKContainer containerWithIdentifier: containerIdentifier];
        }
        else
        {
            _container = [CKContainer defaultContainer];
        }
        _publicDatabase = [_container publicCloudDatabase];
        
        _cloudKitRecordType = cloudKitRecordType;
    }
    
    return self;
}

- (BOOL)isCloudAvailable {
    return [[NSFileManager defaultManager] ubiquityIdentityToken] != nil;
}

-(NSCache *)resourceCache
{
    if (!_resourceCache) _resourceCache = [NSCache new];
    return _resourceCache;
}

-(UIImage*) getCachedImageForRecordName: (NSString*)recordName
{
    NSPurgeableData* imageData = [self.resourceCache objectForKey: recordName];
    
    UIImage* image;
    
    if (imageData)
    {
        if ([imageData beginContentAccess])
        {
            image = [UIImage imageWithData: imageData];
            [imageData endContentAccess];
        }
    }
    
    return image;
}

-(void) cacheImageData: (NSPurgeableData*)imageData forRecordName: (NSString*)recordName
{
    [self.resourceCache setObject: imageData forKey: recordName];
}

-(void)fetchImageAsset:(NSString *)key forRecordWithID:(NSString *)recordName completionHandler:(void (^)(UIImage *))completionHandler
{
    UIImage* cachedThumbnailImage = [self getCachedImageForRecordName: recordName];
    
    if (!cachedThumbnailImage)
    {   // NOT cached so fetch from the cloud.
        CKRecordID *recordID = [[CKRecordID alloc] initWithRecordName: recordName];
        CKFetchRecordsOperation* fetchRecordsOp = [[CKFetchRecordsOperation alloc]initWithRecordIDs: @[recordID]];
        fetchRecordsOp.database = self.publicDatabase;
        
        fetchRecordsOp.perRecordCompletionBlock = ^(CKRecord *record, CKRecordID* recordID, NSError* error) {
     
            CKAsset* thumbnailAsset = record[key];
            if (thumbnailAsset)
            {
                NSData* thumbnailData = [NSData dataWithContentsOfURL: thumbnailAsset.fileURL];
                [self cacheImageData: [NSPurgeableData dataWithData: thumbnailData] forRecordName: recordID.recordName];
                UIImage* cloudThumbnailImage = [UIImage imageWithData: thumbnailData];
                if (cloudThumbnailImage)
                {
                    completionHandler(cloudThumbnailImage);
                }
            }

            };
            
        fetchRecordsOp.desiredKeys = @[key];
        fetchRecordsOp.qualityOfService = NSQualityOfServiceUserInitiated;
        [self.publicDatabase addOperation: fetchRecordsOp];
    }
    else
    {   // cached,
        completionHandler(cachedThumbnailImage);
    }
}

#pragma mark - cloud user info

- (void)requestDiscoverabilityPermission:(void (^)(BOOL discoverable)) completionHandler {
    
    [self.container requestApplicationPermission: CKApplicationPermissionUserDiscoverability
                               completionHandler:^(CKApplicationPermissionStatus applicationPermissionStatus, NSError *error) {
                                   if (error) {
                                       // In your app, handle this error really beautifully.
                                       DDLogError(@"DaisySensorLog An error occured in %@: %@", NSStringFromSelector(_cmd), error);
//                                       abort();
                                   } else {
                                       dispatch_async(dispatch_get_main_queue(), ^{
                                           completionHandler(applicationPermissionStatus == CKApplicationPermissionStatusGranted);
                                       });
                                   }
                               }];
}

- (void)discoverUserInfo:(void (^)(CKDiscoveredUserInfo *user))completionHandler
{
    
    [self.container fetchUserRecordIDWithCompletionHandler:^(CKRecordID *recordID, NSError *error) {
        
        if (error)
        {
            // In your app, handle this error in an awe-inspiring way.
            DDLogError(@"An error occured in %@: %@", NSStringFromSelector(_cmd), error);
        }
        else
        {
            [self.container discoverUserInfoWithUserRecordID:recordID
                                           completionHandler:^(CKDiscoveredUserInfo *user, NSError *derror) {
                                               if (derror)
                                               {
                                                   // In your app, handle this error deftly.
                                                   DDLogError(@"An error occured in %@: %@", NSStringFromSelector(_cmd), derror);
                                                   // Don't do anything if a network error
                                               }
                                               else
                                               {
                                                   dispatch_async(dispatch_get_main_queue(), ^(void){
                                                       completionHandler(user);
                                                   });
                                               }
                                           }];
        }
    }];
}

- (void)fetchRecordWithID:(NSString *)recordID completionHandler:(void (^)(CKRecord *record))completionHandler {
    
    CKRecordID *current = [[CKRecordID alloc] initWithRecordName: recordID];
    [self.publicDatabase fetchRecordWithID:current completionHandler:^(CKRecord *record, NSError *error) {
        
        if (error) {
            // In your app, handle this error gracefully.
            DDLogError(@"DaisySensorLog An error occured in %@: %@", NSStringFromSelector(_cmd), error);
            abort();
        } else {
            dispatch_async(dispatch_get_main_queue(), ^(void){
                completionHandler(record);
            });
        }
    }];
}

- (void)fetchRecordsWithIDs:(NSArray *)recordIDObjects desiredKeys: (NSArray*)keys qualityOfService: (NSQualityOfService)quality perRecordHandler: (void (^)(CKRecord *record, CKRecordID *recordID, NSError *error))perRecordHandler completionHandler:(void (^)(NSDictionary *recordsByRecordID, NSError *operationError))completionHandler
{
    CKFetchRecordsOperation* fetchRecordsOp = [[CKFetchRecordsOperation alloc]initWithRecordIDs: recordIDObjects];
    fetchRecordsOp.database = self.publicDatabase;
    fetchRecordsOp.perRecordCompletionBlock = perRecordHandler;
    fetchRecordsOp.fetchRecordsCompletionBlock = completionHandler;
    fetchRecordsOp.desiredKeys = keys;
    fetchRecordsOp.qualityOfService = quality;
    [self.publicDatabase addOperation: fetchRecordsOp];
}


- (void)queryForRecordsNearLocation:(CLLocation *)location qualityOfService: (NSQualityOfService)quality completionHandler:(void (^)(NSArray *records))completionHandler {
    
    CGFloat radiusInKilometers = 5;
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"distanceToLocation:fromLocation:(location, %@) < %f", location, radiusInKilometers];
    
    CKQuery *query = [[CKQuery alloc] initWithRecordType: self.cloudKitRecordType predicate:predicate];
    
    CKQueryOperation *queryOperation = [[CKQueryOperation alloc] initWithQuery:query];
    
    queryOperation.qualityOfService = quality;
    
    NSMutableArray *results = [[NSMutableArray alloc] init];
    
    [queryOperation setRecordFetchedBlock:^(CKRecord *record) {
        [results addObject:record];
    }];
    
    queryOperation.queryCompletionBlock = ^(CKQueryCursor *cursor, NSError *error) {
        if (error) {
            // In your app, handle this error with such perfection that your users will never realize an error occurred.
            DDLogError(@"DaisySensorLog An error occured in %@: %@", NSStringFromSelector(_cmd), error);
            abort();
        } else {
            dispatch_async(dispatch_get_main_queue(), ^(void){
                completionHandler(results);
            });
        }
    };
    
    [self.publicDatabase addOperation:queryOperation];
}


- (void)savePublicRecord:(CKRecord *)record withCompletionHandler:(void (^)(NSError* error))completionHandler
{
    [self.publicDatabase saveRecord: record completionHandler:^(CKRecord *cRecord, NSError *error) {
        if (error)
        {
            // In your app, handle this error awesomely.
            DDLogError(@"DaisySensorLog An error occured in %@: %@", NSStringFromSelector(_cmd), error);
            
            dispatch_async(dispatch_get_main_queue(), ^(void){
                completionHandler(error);
            });
        } else
        {
            DDLogInfo(@"Successfully saved record");
            
            dispatch_async(dispatch_get_main_queue(), ^(void){
                completionHandler(error);
            });
        }
    }];
}

- (void)savePublicRecords:(NSArray *)records qualityOfService: (NSQualityOfService)quality withCompletionHandler:(void (^)(NSError *error))completionHandler
{
    CKModifyRecordsOperation* saveOperation = [[CKModifyRecordsOperation alloc]initWithRecordsToSave: records recordIDsToDelete: nil];
    saveOperation.qualityOfService = quality;
    saveOperation.modifyRecordsCompletionBlock = ^( NSArray *savedRecords, NSArray *deletedRecordIDs, NSError *operationError) {
        if (operationError)
        {
            // In your app, handle this error awesomely.
            DDLogError(@"DaisySensorLog An error occured in %@: %@", NSStringFromSelector(_cmd), operationError);
            
            dispatch_async(dispatch_get_main_queue(), ^(void){
                completionHandler(operationError);
            });
        }
        else
        {
            DDLogInfo(@"Successfully saved records");
            
            dispatch_async(dispatch_get_main_queue(), ^(void){
                completionHandler(operationError);
            });
        }
    };
    
    [self.publicDatabase addOperation: saveOperation];
}

- (void)deletePublicRecord:(CKRecord *)record {
    [self.publicDatabase deleteRecordWithID: record.recordID completionHandler:^(CKRecordID *recordID, NSError *error) {
        if (error) {
            // In your app, handle this error. Please.
            DDLogError(@"DaisySensorLog An error occured in %@: %@", NSStringFromSelector(_cmd), error);
            abort();
        } else {
            DDLogInfo(@"Successfully deleted record");
        }
    }];
}

- (void)deletePublicRecords:(NSArray *)records withCompletionHandler:(void (^)(NSError *error))completionHandler
{
    CKModifyRecordsOperation* deleteOperation = [[CKModifyRecordsOperation alloc]initWithRecordsToSave: nil recordIDsToDelete: records];
    
    deleteOperation.modifyRecordsCompletionBlock = ^( NSArray *savedRecords, NSArray *deletedRecordIDs, NSError *operationError) {
        if (operationError) {
            // In your app, handle this error. Please.
            DDLogError(@"DaisySensorLog An error occured in %@: %@", NSStringFromSelector(_cmd), operationError);
            abort();
        } else {
            DDLogInfo(@"Successfully deleted records");
        }
    };
    [self.publicDatabase addOperation: deleteOperation];
}

-(CKQueryOperation*)fetchPublicRecordsWithPredicate:(NSPredicate *)predicate sortDescriptors:(NSArray *)descriptors cloudKeys:(NSArray *)cloudKeys qualityOfService: (NSQualityOfService)quality resultLimit: (NSUInteger)limit perRecordBlock:(void (^)(CKRecord *record))recordBlock completionHandler:(void (^)(CKQueryCursor *, NSError *))completionHandler
{
    return [self fetchPublicRecordsWithType: self.cloudKitRecordType predicate: predicate sortDescriptors: descriptors cloudKeys: cloudKeys qualityOfService: quality perRecordBlock: recordBlock completionHandler: completionHandler];
}

/*     queryOperation.desiredKeys = @[CommonNameField,SciNameField,WikiField,PhotoAssetField]; */
- (CKQueryOperation*)fetchPublicRecordsWithType:(NSString *)recordType predicate: (NSPredicate*)predicate sortDescriptors: (NSArray*) descriptors cloudKeys: (NSArray*)cloudKeys qualityOfService: (NSQualityOfService)quality perRecordBlock:(void (^)(CKRecord *record))recordBlock completionHandler:(void (^)(CKQueryCursor *cursor, NSError* error))completionHandler
{
    return [self fetchPublicRecordsWithType: recordType predicate: predicate sortDescriptors: descriptors cloudKeys: cloudKeys qualityOfService: quality resultLimit: 0 perRecordBlock: recordBlock completionHandler: completionHandler];
}

- (CKQueryOperation*)fetchPublicRecordsWithType:(NSString *)recordType predicate: (NSPredicate*)predicate sortDescriptors: (NSArray*) descriptors cloudKeys: (NSArray*)cloudKeys qualityOfService: (NSQualityOfService)quality resultLimit: (NSUInteger)limit perRecordBlock:(void (^)(CKRecord *record))recordBlock completionHandler:(void (^)(CKQueryCursor *cursor, NSError* error))completionHandler
{
    if (!predicate)
    {
        predicate = [NSPredicate predicateWithValue: YES];
    }
    
    CKQuery *query = [[CKQuery alloc] initWithRecordType: recordType predicate: predicate];
    if (descriptors && descriptors.count > 0)
    {
        query.sortDescriptors = descriptors;
    }
    else if (self.defaultSortDescriptors && self.defaultSortDescriptors.count >0)
    {
        query.sortDescriptors = self.defaultSortDescriptors;
    }
    else
    {
        query.sortDescriptors = nil;
    }
    
    CKQueryOperation *queryOperation = [[CKQueryOperation alloc] initWithQuery:query];
    // Just request the name field for all records
    queryOperation.desiredKeys = cloudKeys;
    if (quality != 0) queryOperation.qualityOfService = quality;
    if (limit > 0) queryOperation.resultsLimit = limit;
    
    queryOperation.recordFetchedBlock = ^(CKRecord *record) {
        recordBlock(record);
    };
#pragma message "TODO: handle CKQueryCursor for when there are lots of records. Where to add logic?"
    queryOperation.queryCompletionBlock = ^(CKQueryCursor *cursor, NSError *error) {
        
        if (cursor) DDLogWarn(@"DaisySensorLog FractalScapes optimizer unused query cursor returned: %@", cursor);
        
            dispatch_async(dispatch_get_main_queue(), ^(void){
                completionHandler(cursor, error); // changes this to the cursor
            });
    };
    
    [self.publicDatabase addOperation: queryOperation];
    return queryOperation;
}

-(CKQueryOperation*)fetchNextRecordWithCursor: (CKQueryCursor*)cursor
{
    CKQueryOperation* nextOperation = [[CKQueryOperation alloc]initWithCursor: cursor];
    [self.publicDatabase addOperation: nextOperation];
    
    return nextOperation;
}

-(void)cancelOperation: (CKQueryOperation*)operation
{
    if (operation && (operation.isReady || operation.isExecuting))
    {
        [operation cancel];
    }
}

- (void)queryForPublicRecordsWithReferenceNamed:(NSString *)referenceRecordName completionHandler:(void (^)(NSArray *records))completionHandler {
    
//    CKRecordID *recordID = [[CKRecordID alloc] initWithRecordName:referenceRecordName];
//    CKReference *parent = [[CKReference alloc] initWithRecordID:recordID action:CKReferenceActionNone];
//    
//    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"parent == %@", parent];
//    CKQuery *query = [[CKQuery alloc] initWithRecordType:ReferenceSubItemsRecordType predicate:predicate];
//    
//    CKQueryOperation *queryOperation = [[CKQueryOperation alloc] initWithQuery:query];
//    // Just request the name field for all records
//    queryOperation.desiredKeys = @[NameField];
//    
//    NSMutableArray *results = [[NSMutableArray alloc] init];
//    
//    queryOperation.recordFetchedBlock = ^(CKRecord *record) {
//        [results addObject:record];
//    };
//    
//    queryOperation.queryCompletionBlock = ^(CKQueryCursor *cursor, NSError *error) {
//        if (error) {
//            // In your app, you should do the Right Thing
//            DDLogInfo(@"An error occured in %@: %@", NSStringFromSelector(_cmd), error);
//            abort();
//        } else {
//            dispatch_async(dispatch_get_main_queue(), ^(void){
//                completionHandler(results);
//            });
//        }
//    };
//    
//    [self.publicDatabase addOperation:queryOperation];
}

- (void)subscribe {
    
    if (self.subscribed == NO) {
        
        NSPredicate *truePredicate = [NSPredicate predicateWithValue:YES];
        CKSubscription *itemSubscription = [[CKSubscription alloc] initWithRecordType: self.cloudKitRecordType
                                                                            predicate: truePredicate
                                                                              options: CKSubscriptionOptionsFiresOnRecordCreation];
        
        
        CKNotificationInfo *notification = [[CKNotificationInfo alloc] init];
        notification.alertBody = @"New Item Added!";
        itemSubscription.notificationInfo = notification;
        
        [self.publicDatabase saveSubscription:itemSubscription completionHandler:^(CKSubscription *subscription, NSError *error) {
            if (error) {
                // In your app, handle this error appropriately.
                DDLogError(@"DaisySensorLog An error occured in %@: %@", NSStringFromSelector(_cmd), error);
                abort();
            } else {
                DDLogInfo(@"DaisySensorLog Subscribed to Item");
                NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                [defaults setBool:YES forKey:@"subscribed"];
                [defaults setObject:subscription.subscriptionID forKey: self.cloudSubscriptionIDKey];
            }
        }];
    }
}

- (void)unsubscribe {
    if (self.subscribed == YES) {
        
        NSString *subscriptionID = [[NSUserDefaults standardUserDefaults] objectForKey: self.cloudSubscriptionIDKey];
        
        CKModifySubscriptionsOperation *modifyOperation = [[CKModifySubscriptionsOperation alloc] init];
        modifyOperation.subscriptionIDsToDelete = @[subscriptionID];
        
        modifyOperation.modifySubscriptionsCompletionBlock = ^(NSArray *savedSubscriptions, NSArray *deletedSubscriptionIDs, NSError *error) {
            if (error) {
                // In your app, handle this error beautifully.
                DDLogError(@"DaisySensorLog An error occured in %@: %@", NSStringFromSelector(_cmd), error);
                abort();
            } else {
                DDLogInfo(@"DaisySensorLog Unsubscribed to Item");
                [[NSUserDefaults standardUserDefaults] removeObjectForKey: self.cloudSubscriptionIDKey];
            }
        };
        
        [self.publicDatabase addOperation:modifyOperation];
    }
}

- (BOOL)isSubscribed {
    return [[NSUserDefaults standardUserDefaults] objectForKey: self.cloudSubscriptionIDKey] != nil;
}

@end
