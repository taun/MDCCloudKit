//
//  MDCKBaseCloudBrowserViewController.m
//  MDCloudKit
//
//  Created by Taun Chapman on 05/23/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

#import "MDCKBaseCloudBrowserViewController.h"
#import "MDLDaisyAppModel.h"
#import "MDLCloudKitManager.h"

#import <Crashlytics/Crashlytics.h>

@interface MDCKBaseCloudBrowserViewController ()

/*!
 The data source of returned public CKRecords
 */
@property(nonatomic,readwrite,strong) NSMutableArray                         *publicCloudRecords;
/*!
 A mapping of the CKRecord by RecordID to it's index location in the collection.
 */
@property(nonatomic,strong) NSMutableDictionary                              *publicRecordsCacheByRecordIDName;

@property(nonatomic,strong) NSTimer                                          *networkTimer;

@end

@implementation MDCKBaseCloudBrowserViewController

-(NSMutableArray *)publicCloudRecords
{
    if (!_publicCloudRecords)
    {
        _publicCloudRecords = [NSMutableArray arrayWithCapacity: 10];
    }
    return _publicCloudRecords;
}

-(NSMutableDictionary *)publicRecordsCacheByRecordIDName
{
    if (!_publicRecordsCacheByRecordIDName)
    {
        _publicRecordsCacheByRecordIDName = [NSMutableDictionary dictionaryWithCapacity: 10];
    }
    
    return _publicRecordsCacheByRecordIDName;
}

-(void) fetchCloudRecordsWithPredicate: (NSPredicate*)predicate sortDescriptors: (NSArray*)descriptors timeout:(NSTimeInterval)timeout
{
    self.getSelectedButton.enabled = NO;
    NSDate* fetchStartDate = [NSDate date];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self startNetworkTimerWithInterval: timeout];
    });
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible: YES];
    
    if (self.publicCloudRecords.count > 0)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSUInteger sections = [self.collectionView numberOfSections];
            [self.publicRecordsCacheByRecordIDName removeAllObjects];
            [self.publicCloudRecords removeAllObjects];
            if (sections > 0) [self.collectionView deleteSections: [NSIndexSet indexSetWithIndexesInRange: NSMakeRange(0, sections)]];
        });
    }
    
    self.currentSearchOperation = [self.appModel.cloudKitManager fetchPublicRecordsWithPredicate: predicate sortDescriptors: descriptors cloudKeys: self.cloudDownloadKeys qualityOfService: NSQualityOfServiceUserInteractive resultLimit: 1 perRecordBlock:^(CKRecord *record) {
        //
        if (record)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                // would this ever get called if there was not a valid record?
                self.networkConnected = YES;
                self.emptySearchResultLabel.hidden = YES;
                self.searchButton.enabled = YES;
                
                NSUInteger recordSection = 0;
                NSUInteger recordCount = self.publicCloudRecords.count;
                NSIndexPath* newIndexPath = [NSIndexPath indexPathForItem: recordCount inSection: recordSection];
                
                if (recordCount == 0)
                { // special case first record
                    [self.publicCloudRecords addObject: record];
                    self.publicRecordsCacheByRecordIDName[record.recordID.recordName] = newIndexPath;
                    
                    [self.collectionView insertSections: [NSIndexSet indexSetWithIndex: recordSection]];
                    // will automatically load existing record for section
                }
                else
                {  // we already have some records so is this a duplicate?
                    NSIndexPath* recordIndexPath = self.publicRecordsCacheByRecordIDName[record.recordID.recordName];
                    
                    if (!recordIndexPath)
                    {   // new record needs to be added and inserted
                        [self.publicCloudRecords addObject: record];
                        self.publicRecordsCacheByRecordIDName[record.recordID.recordName] = newIndexPath;
                        
                        [self.collectionView insertItemsAtIndexPaths: @[newIndexPath]];
                    }
                    else
                    {   // already exists, need to update
                        [self.collectionView reloadItemsAtIndexPaths: @[recordIndexPath]];
                    }
                }
                
            });
            
        }
    } completionHandler:^(CKQueryCursor *cursor, NSError* error)
     {
         [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible: NO];
         dispatch_async(dispatch_get_main_queue(), ^{

             [self stopNetworkTimer];
             
             NSTimeInterval fetchInterval = [fetchStartDate timeIntervalSinceNow];
             [Answers logCustomEventWithName: NSStringFromClass([self class]) customAttributes: @{@"Successful fetch interval": @(fetchInterval)}];
             
             if (!error)
             {
                 if (self.publicCloudRecords.count == 0)
                 {
                     self.emptySearchResultLabel.hidden = NO;
                 }
                 
                 [self handleFetchRequestSuccess];
                 
                 if (cursor)
                 {
                     self.currentSearchOperation = [self.appModel.cloudKitManager fetchNextRecordWithCursor: cursor];
                 }
             }
             else
             {
                 if (error.code != CKErrorOperationCancelled)
                 {  // need to skip when the operation was cancelled due to typing
                     [self handleFetchRequestError: error];
                 }
             }
         });
     }];
}

-(void) handleFetchRequestSuccess
{
    
}

-(void) handleFetchRequestError: (NSError*)error
{
    self.networkConnected = NO;
    BOOL giveRetryOption = NO;
    
    NSString *title;
    NSString *message;
    DDLogError(@"%@ error code: %ld, %@",NSStringFromSelector(_cmd),(long)error.code,[error.userInfo debugDescription]);
    CKErrorCode code = error.code;
    
    switch (code) {
        case CKErrorInternalError: // 1
            title = NSLocalizedString(@"Network problem", nil);
            message = @"Please try again in couple of minutes";
            break;
            
        case CKErrorPartialFailure: // 2
            title = NSLocalizedString(@"Network problem", nil);
            message = @"Please try again in couple of minutes";
            break;
            
        case CKErrorNetworkUnavailable: // 3
            title = NSLocalizedString(@"No Network", nil);
            message = @"Please try again when connected to a network";
            break;
            
        case CKErrorNetworkFailure: // 4
            title = NSLocalizedString(@"Network problem", nil);
            message = @"Please try again in couple of minutes";
            break;
            
        case CKErrorServiceUnavailable: // 6
            title = NSLocalizedString(@"Cloud Unavailable", nil);
            message = @"iCloud is temporarily unavailable. Please try again in couple of minutes";
            break;
            
        case CKErrorRequestRateLimited: // 7
            title = NSLocalizedString(@"Cloud Unavailable", nil);
            message = [NSString stringWithFormat: @"iCloud is temporarily unavailable. Please try again in %@ seconds",error.userInfo[@"CKRetryAfter"]];
            break;
            
        case CKErrorZoneBusy: // 23
            title = NSLocalizedString(@"Too Much Traffic", nil);
            message = @"Please try again in couple of minutes";
            break;
            
        case CKErrorOperationCancelled: // 20
            title = NSLocalizedString(@"Cloud Timeout", nil);
            message = @"Try again later";
            giveRetryOption = YES;
            break;
            
        case CKErrorQuotaExceeded: // 25
            title = NSLocalizedString(@"Cloud quota reached", nil);
            message = @"Free some cloud space";
            break;
            
        default:
            title = NSLocalizedString(@"Problem with the Cloud", nil);
            message = @"Try again later.";
            break;
    }
    
    [Answers logCustomEventWithName: NSStringFromClass([self class]) customAttributes: @{@"Fetch error": @(error.code)}];

    UIAlertController* alert = [UIAlertController alertControllerWithTitle: title
                                                                   message: message
                                                            preferredStyle: UIAlertControllerStyleAlert];
    
    UIAlertController* __weak weakAlert = alert;
    
    if (giveRetryOption)
    {
        NSString* actionTitle = NSLocalizedString(@"Retry Now", @"Try the action again now");
        UIAlertAction* retryAction = [UIAlertAction actionWithTitle: actionTitle style: UIAlertActionStyleDefault handler:^(UIAlertAction * action)
                                      {
//                                          [weakAlert dismissViewControllerAnimated:YES completion:nil];
                                          [self updateSearchResultsForSearchController: self.searchController];
                                      }];
        
        [alert addAction: retryAction];
    }

    NSString *okActionTitle = NSLocalizedString(@"Ok", nil);
    
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle: okActionTitle style: UIAlertActionStyleCancel handler:^(UIAlertAction * action)
                                    {
//                                        [weakAlert dismissViewControllerAnimated:YES completion:nil];
                                    }];
    
    [alert addAction: defaultAction];
    
#pragma message "TODO how to include additional options from subclass?"
    [self presentViewController: weakAlert animated: YES completion:^{
        //
    }];
}

-(void)setupSearchController
{
    _searchController = [[UISearchController alloc] initWithSearchResultsController: nil];
    _searchController.searchResultsUpdater = self;
    _searchController.dimsBackgroundDuringPresentation = NO;
    _searchController.hidesNavigationBarDuringPresentation = NO;
    //    _searchController.searchBar.prompt = @"Search by name";
    UISearchBar* searchBar = _searchController.searchBar;
    searchBar.searchBarStyle = UISearchBarStyleMinimal;
    searchBar.showsScopeBar = NO;
    searchBar.showsCancelButton = NO;
    searchBar.tintColor = self.view.tintColor;
    [searchBar sizeToFit];
    [self.searchBarContainer addSubview: searchBar];
    self.searchBarContainerHeightConstraint.constant = 0;
    searchBar.delegate = self;
    _searchController.delegate = self;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupSearchController];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.emptySearchResultLabel.hidden = YES;
    
    [self updateCollectionViewOffsetForNavAndSearch];

    self.searchController.delegate = self;
}

-(void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.searchController.delegate = nil;
}

-(void)startNetworkTimerWithInterval: (NSTimeInterval)timeout
{
    [self.activityIndicator startAnimating];
    self.networkTimer = [NSTimer timerWithTimeInterval: timeout
                                                target: self
                                              selector: @selector(networkTimeoutTriggeredBy:)
                                              userInfo: nil
                                               repeats: NO];
    
    [[NSRunLoop mainRunLoop] addTimer: self.networkTimer forMode: NSDefaultRunLoopMode];
}

-(void)stopNetworkTimer
{
    [self.activityIndicator stopAnimating];
    if (self.networkTimer.isValid)
    {
        [self.networkTimer invalidate];
    }
}

-(void)networkTimeoutTriggeredBy: (NSTimer*)timer
{
    [Answers logCustomEventWithName: NSStringFromClass([self class]) customAttributes: @{@"Network Timeout": @YES}];
    [self.appModel.cloudKitManager cancelOperation: self.currentSearchOperation];
    [self.activityIndicator stopAnimating];
//    [self showAlertActionsNetworkTimeout: self];
}

-(void)showAlertActionsToAddiCloud: (id)sender
{
    NSString* title = NSLocalizedString(@"iCloud Share", nil);
    NSString* message = NSLocalizedString(@"You must have your device logged into iCloud", nil);
    
    UIAlertController* alert = [UIAlertController alertControllerWithTitle: title
                                                                   message: message
                                                            preferredStyle: UIAlertControllerStyleActionSheet];
    
    UIAlertController* __weak weakAlert = alert;
    
    //    ALAuthorizationStatus cameraAuthStatus = [ALAssetsLibrary authorizationStatus];
    
    UIAlertAction* fractalCloud = [UIAlertAction actionWithTitle:@"Go to iCloud Settings" style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * action)
                                   {
                                       [Answers logCustomEventWithName: NSStringFromClass([self class]) customAttributes: @{@"Share action": @"iCloud Settings"}];
                                       [weakAlert dismissViewControllerAnimated:YES completion:nil]; // because of popover mode
                                       [self sendUserToSystemiCloudSettings: sender];
                                   }];
    [alert addAction: fractalCloud];
    
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"Later Maybe" style:UIAlertActionStyleCancel
                                                          handler:^(UIAlertAction * action)
                                    {
                                        [Answers logCustomEventWithName: NSStringFromClass([self class]) customAttributes: @{@"Share action": @"Later"}];
                                        [weakAlert dismissViewControllerAnimated:YES completion:nil]; // because of popover mode
                                    }];
    [alert addAction: defaultAction];
    
    UIPopoverPresentationController* ppc = alert.popoverPresentationController;
    ppc.barButtonItem = sender;
    ppc.permittedArrowDirections = UIPopoverArrowDirectionAny;
    
    [self.navigationController presentViewController:alert animated:YES completion:nil];
}

-(void)sendUserToSystemiCloudSettings: (id)sender
{
    [[UIApplication sharedApplication] openURL: [NSURL URLWithString:@"prefs:root=iCloud"]];
}


-(void) viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize: size withTransitionCoordinator: coordinator];
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context){
        //
        
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context){
        //
        [self.collectionView.collectionViewLayout invalidateLayout];
        if (self.searchController.active)
        {
            [self.searchController.searchBar setNeedsLayout];
            [self.searchController.searchBar layoutIfNeeded];
        }
        [self updateCollectionViewOffsetForNavAndSearch];
        
    }];
}

-(void)updateCollectionViewOffsetForNavAndSearch
{
    CGFloat padding = 0;
    if (self.searchController.active)
    {
        padding = self.searchController.searchBar.bounds.size.height;
    }
    self.searchBarContainerHeightConstraint.constant = padding;
    
    CGRect navFrame = self.navigationController.navigationBar.frame;
    CGFloat navHeight = CGRectGetMaxY(navFrame) + padding;
    self.collectionView.contentInset = UIEdgeInsetsMake(navHeight, 0, 0, 0);
    [self.collectionView setContentOffset: CGPointMake(0, -navHeight) animated: YES] ;
}

#pragma mark - UISearchControllerDelegate
-(void)willPresentSearchController:(UISearchController *)searchController
{
}

-(void)presentSearchController:(UISearchController *)searchController
{
}

-(void)didPresentSearchController:(UISearchController *)searchController
{
    //    searchController.searchBar.showsCancelButton = NO;
    [self updateCollectionViewOffsetForNavAndSearch];
    
    self.tabBarController.tabBar.hidden = YES;
}

-(void)willDismissSearchController:(UISearchController *)searchController
{
    
}

-(void)didDismissSearchController:(UISearchController *)searchController
{
    [self updateCollectionViewOffsetForNavAndSearch];
    self.tabBarController.tabBar.hidden = NO;
}

- (IBAction)activateSearch:(id)sender
{
    self.searchController.active = !self.searchController.active;
}

#pragma mark - UISearchBarDelegate
-(void)searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope
{
    [self updateSearchResultsForSearchController: self.searchController];
}

-(void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    self.textWasEdited = YES;
}

-(void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
    
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
}


#pragma mark - UISearchResultsUpdating
- (void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
    [self fetchCloudRecordsWithPredicate: nil sortDescriptors: nil timeout: 20.0];
}

#pragma mark - FlowLayoutDelegate
- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    CGFloat minInset = 2.0;
    
    UICollectionViewFlowLayout* layout = (UICollectionViewFlowLayout*)collectionViewLayout;
    CGFloat itemWidth = layout.itemSize.width;
    CGFloat rowWidth = collectionView.bounds.size.width - (2*minInset);
    NSInteger numItems = floorf(rowWidth/itemWidth);
    CGFloat margins = floorf((rowWidth - (numItems * itemWidth))/(numItems+1.0));
    //    margins = MAX(margins, 4.0);
    UIEdgeInsets oldInsets = layout.sectionInset;
    UIEdgeInsets insets = UIEdgeInsetsMake(oldInsets.top, margins, oldInsets.bottom, margins);
    return insets;
    //    return 20.0;
}

#pragma mark - UICollectionViewDataSource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return self.publicCloudRecords.count ? 1 : 0;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    if (self.publicCloudRecords)
    {
        return self.publicCloudRecords.count;
    }
    else
    {
        return 1;
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return nil;
}

#pragma mark - UICollectionViewDelegate
-(BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell* cell = [collectionView cellForItemAtIndexPath: indexPath];
    
    if (cell.isSelected)
    {
        [collectionView deselectItemAtIndexPath: indexPath animated: YES];
        self.getSelectedButton.enabled = NO;
        return NO;
    }
    else
    {
        return YES;
    }
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    self.getSelectedButton.enabled = YES;
}

-(void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[self.collectionView indexPathsForSelectedItems] count] == 0) {
        self.getSelectedButton.enabled = NO;
    }
}

- (IBAction)downloadSelected:(id)sender
{
}

@end
