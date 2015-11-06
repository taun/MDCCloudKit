//  Created by Taun Chapman on 09/15/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

@import CloudKit;

#import "MDLCloudKitManager.h"

@interface MDLCloudKitManager ()

@property(nonatomic,strong)NSString     *cloudKitRecordType;
@property (readonly) CKContainer        *container;
@property (readonly) CKDatabase         *publicDatabase;

@end

@implementation MDLCloudKitManager

-(instancetype)initWithIdentifier:(NSString *)containerIdentifier andRecordType:(NSString *)cloudKitRecordType
{
    self = [super init];
    if (self) {
        if (containerIdentifier && containerIdentifier.length > 0)
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

#pragma mark - sample cloud

- (void)requestDiscoverabilityPermission:(void (^)(BOOL discoverable)) completionHandler {
    
    [self.container requestApplicationPermission: CKApplicationPermissionUserDiscoverability
                               completionHandler:^(CKApplicationPermissionStatus applicationPermissionStatus, NSError *error) {
                                   if (error) {
                                       // In your app, handle this error really beautifully.
                                       NSLog(@"An error occured in %@: %@", NSStringFromSelector(_cmd), error);
//                                       abort();
                                   } else {
                                       dispatch_async(dispatch_get_main_queue(), ^{
                                           completionHandler(applicationPermissionStatus == CKApplicationPermissionStatusGranted);
                                       });
                                   }
                               }];
}

- (void)discoverUserInfo:(void (^)(CKDiscoveredUserInfo *user))completionHandler {
    
    [self.container fetchUserRecordIDWithCompletionHandler:^(CKRecordID *recordID, NSError *error) {
        
        if (error) {
            // In your app, handle this error in an awe-inspiring way.
            NSLog(@"An error occured in %@: %@", NSStringFromSelector(_cmd), error);
            abort();
        } else {
            [self.container discoverUserInfoWithUserRecordID:recordID
                                           completionHandler:^(CKDiscoveredUserInfo *user, NSError *derror) {
                                               if (derror) {
                                                   // In your app, handle this error deftly.
                                                   NSLog(@"An error occured in %@: %@", NSStringFromSelector(_cmd), error);
                                                   abort();
                                               } else {
                                                   dispatch_async(dispatch_get_main_queue(), ^(void){
                                                       completionHandler(user);
                                                   });
                                               }
                                           }];
        }
    }];
}

- (void)fetchRecordWithID:(NSString *)recordID completionHandler:(void (^)(CKRecord *record))completionHandler {
    
    CKRecordID *current = [[CKRecordID alloc] initWithRecordName:recordID];
    [self.publicDatabase fetchRecordWithID:current completionHandler:^(CKRecord *record, NSError *error) {
        
        if (error) {
            // In your app, handle this error gracefully.
            NSLog(@"An error occured in %@: %@", NSStringFromSelector(_cmd), error);
            abort();
        } else {
            dispatch_async(dispatch_get_main_queue(), ^(void){
                completionHandler(record);
            });
        }
    }];
}

- (void)fetchRecordsWithIDs:(NSArray *)recordIDObjects desiredKeys: (NSArray*)keys perRecordHandler: (void (^)(CKRecord *record, CKRecordID *recordID, NSError *error))perRecordHandler completionHandler:(void (^)(NSDictionary *recordsByRecordID, NSError *operationError))completionHandler
{
    CKFetchRecordsOperation* fetchRecordsOp = [[CKFetchRecordsOperation alloc]initWithRecordIDs: recordIDObjects];
    fetchRecordsOp.database = self.publicDatabase;
    fetchRecordsOp.perRecordCompletionBlock = perRecordHandler;
    fetchRecordsOp.fetchRecordsCompletionBlock = completionHandler;
    fetchRecordsOp.desiredKeys = keys;
    [self.publicDatabase addOperation: fetchRecordsOp];
}


- (void)queryForRecordsNearLocation:(CLLocation *)location completionHandler:(void (^)(NSArray *records))completionHandler {
    
    CGFloat radiusInKilometers = 5;
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"distanceToLocation:fromLocation:(location, %@) < %f", location, radiusInKilometers];
    
    CKQuery *query = [[CKQuery alloc] initWithRecordType: self.cloudKitRecordType predicate:predicate];
    
    CKQueryOperation *queryOperation = [[CKQueryOperation alloc] initWithQuery:query];
    
    NSMutableArray *results = [[NSMutableArray alloc] init];
    
    [queryOperation setRecordFetchedBlock:^(CKRecord *record) {
        [results addObject:record];
    }];
    
    queryOperation.queryCompletionBlock = ^(CKQueryCursor *cursor, NSError *error) {
        if (error) {
            // In your app, handle this error with such perfection that your users will never realize an error occurred.
            NSLog(@"An error occured in %@: %@", NSStringFromSelector(_cmd), error);
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
            NSLog(@"An error occured in %@: %@", NSStringFromSelector(_cmd), error);
            
            dispatch_async(dispatch_get_main_queue(), ^(void){
                completionHandler(error);
            });
        } else
        {
            NSLog(@"Successfully saved record");
            
            dispatch_async(dispatch_get_main_queue(), ^(void){
                completionHandler(error);
            });
        }
    }];
}

- (void)savePublicRecords:(NSArray *)records withCompletionHandler:(void (^)(NSError *error))completionHandler
{
    CKModifyRecordsOperation* saveOperation = [[CKModifyRecordsOperation alloc]initWithRecordsToSave: records recordIDsToDelete: nil];
    saveOperation.modifyRecordsCompletionBlock = ^( NSArray *savedRecords, NSArray *deletedRecordIDs, NSError *operationError) {
        if (operationError)
        {
            // In your app, handle this error awesomely.
            NSLog(@"An error occured in %@: %@", NSStringFromSelector(_cmd), operationError);
            
            dispatch_async(dispatch_get_main_queue(), ^(void){
                completionHandler(operationError);
            });
        }
        else
        {
            NSLog(@"Successfully saved records");
            
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
            NSLog(@"An error occured in %@: %@", NSStringFromSelector(_cmd), error);
            abort();
        } else {
            NSLog(@"Successfully deleted record");
        }
    }];
}

- (void)deletePublicRecords:(NSArray *)records withCompletionHandler:(void (^)(NSError *error))completionHandler
{
    CKModifyRecordsOperation* deleteOperation = [[CKModifyRecordsOperation alloc]initWithRecordsToSave: nil recordIDsToDelete: records];
    
    deleteOperation.modifyRecordsCompletionBlock = ^( NSArray *savedRecords, NSArray *deletedRecordIDs, NSError *operationError) {
        if (operationError) {
            // In your app, handle this error. Please.
            NSLog(@"An error occured in %@: %@", NSStringFromSelector(_cmd), operationError);
            abort();
        } else {
            NSLog(@"Successfully deleted records");
        }
    };
    [self.publicDatabase addOperation: deleteOperation];
}

-(void)fetchPublicRecordsWithPredicate:(NSPredicate *)predicate sortDescriptors:(NSArray *)descriptors cloudKeys:(NSArray *)cloudKeys perRecordBlock:(void (^)(CKRecord *record))recordBlock completionHandler:(void (^)(NSArray *, NSError *))completionHandler
{
    [self fetchPublicRecordsWithType: self.cloudKitRecordType predicate: predicate sortDescriptor: descriptors cloudKeys: cloudKeys perRecordBlock: recordBlock completionHandler: completionHandler];
}

- (void)fetchPublicRecordsWithType:(NSString *)recordType predicate: (NSPredicate*)predicate sortDescriptor: (NSArray*) descriptors cloudKeys: (NSArray*)cloudKeys perRecordBlock:(void (^)(CKRecord *record))recordBlock completionHandler:(void (^)(NSArray *records, NSError* error))completionHandler
{
    if (!predicate) {
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
//    queryOperation.resultsLimit = 4;
    
    NSMutableArray *results = [[NSMutableArray alloc] init];
    
    queryOperation.recordFetchedBlock = ^(CKRecord *record) {
        [results addObject:record];
        recordBlock(record);
    };
#pragma message "TODO: handle CKQueryCursor for when there are lots of records. Where to add logic?"
    queryOperation.queryCompletionBlock = ^(CKQueryCursor *cursor, NSError *error) {
        
        if (cursor) NSLog(@"FractalScapes optimizer unused query cursor returned: %@", cursor);
        
            dispatch_async(dispatch_get_main_queue(), ^(void){
                completionHandler(results, error);
            });
    };
    
    [self.publicDatabase addOperation:queryOperation];
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
//            NSLog(@"An error occured in %@: %@", NSStringFromSelector(_cmd), error);
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
                NSLog(@"An error occured in %@: %@", NSStringFromSelector(_cmd), error);
                abort();
            } else {
                NSLog(@"Subscribed to Item");
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
                NSLog(@"An error occured in %@: %@", NSStringFromSelector(_cmd), error);
                abort();
            } else {
                NSLog(@"Unsubscribed to Item");
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
