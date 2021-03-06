//
//  MDCKBaseCloudBrowserViewController.m
//  MDCloudKit
//
//  Created by Taun Chapman on 05/23/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

#import "MDCKBaseCloudBrowserViewController.h"
#import "MDLCloudKitManager.h"
#import "MDKUICollectionViewResizingFlowLayout.h"
#import "MDBResizingWidthFlowLayoutDelegate.h"


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
@property(nonatomic,assign) BOOL                                             networkTimeout;

@property (nonatomic,assign) CGSize                                          baseCellSize;

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
//    NSDate* fetchStartDate = [NSDate date];
    
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
             
//             NSTimeInterval fetchInterval = [fetchStartDate timeIntervalSinceNow];
             
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
                 if (self.networkTimeout || error.code != CKErrorOperationCancelled)
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
    if (self.presentedViewController)
    {
        // welcome screen is up or some other modally presented view and we need to defer the error box.
        self.fetchRequestError = error;
        self.handlingFetchRequestErrorWasPostponed = YES;
    }
    else
    {
        self.handlingFetchRequestErrorWasPostponed = NO;
        self.networkConnected = NO;
        BOOL giveRetryOption = NO;
        
        NSString *title;
        NSString *message;
        NSLog(@"%@ error code: %ld, %@",NSStringFromSelector(_cmd),(long)error.code,[error.userInfo debugDescription]);
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
                
        NSMutableArray* actions = [NSMutableArray new];
        
        if (giveRetryOption)
        {
            NSString* actionTitle = NSLocalizedString(@"Retry Now", @"Try the action again now");
            UIAlertAction* retryAction = [UIAlertAction actionWithTitle: actionTitle style: UIAlertActionStyleDefault handler:^(UIAlertAction * action)
                                          {
                                              //                                          [weakAlert dismissViewControllerAnimated:YES completion:nil];
                                              [self updateSearchResultsForSearchController: self.searchController];
                                          }];
            
            [actions addObject: retryAction];
        }
        
        NSString *okActionTitle = NSLocalizedString(@"Ok", nil);
        
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle: okActionTitle style: UIAlertActionStyleCancel handler:^(UIAlertAction * action)
                                        {
                                            //                                        [weakAlert dismissViewControllerAnimated:YES completion:nil];
                                        }];
        
        [actions addObject: defaultAction];
        
        [self presentFetchErrorAlertTitle: title message: message withActions: actions];
    }
}

-(void)presentFetchErrorAlertTitle: (NSString*)title message: (NSString*)message withActions: (NSMutableArray<UIAlertAction*>*)alertActions
{
  
    UIAlertController* alert = [UIAlertController alertControllerWithTitle: title
                                                                   message: message
                                                            preferredStyle: UIAlertControllerStyleAlert];

    for (UIAlertAction* action in alertActions)
    {
        [alert addAction: action];
    }
    
    [self presentViewController: alert animated: YES completion:^{
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
    UICollectionViewFlowLayout* layout = (UICollectionViewFlowLayout*)self.collectionView.collectionViewLayout;
    self.baseCellSize = CGSizeMake(layout.itemSize.width, layout.itemSize.height);
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

-(void) viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize: size withTransitionCoordinator: coordinator];
    
    // Important! need to invalidate before starting rotation animation, otherwise a crash due to cells not being where expected
//    [MDBResizingWidthFlowLayoutDelegate invalidateFlowLayoutAttributesForCollection: self.collectionView];

    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context){
        //
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context){
        //
        if (self.searchController.active)
        {
            [self.searchController.searchBar setNeedsLayout];
            [self.searchController.searchBar layoutIfNeeded];
        }
        [self updateCollectionViewOffsetForNavAndSearch];
    }];
    //    subLayer.position = self.fractalView.center;
}


-(void)startNetworkTimerWithInterval: (NSTimeInterval)timeout
{
    [self.activityIndicator startAnimating];
    self.networkTimeout = NO;
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
    self.networkTimeout = YES;
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
    MDCKBaseCloudBrowserViewController* __weak weakSelf = self;

    //    ALAuthorizationStatus cameraAuthStatus = [ALAssetsLibrary authorizationStatus];
    
    UIAlertAction* fractalCloud = [UIAlertAction actionWithTitle: NSLocalizedString(@"Go to iCloud Settings", nil) style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * action)
                                   {
                                       [weakAlert dismissViewControllerAnimated:YES completion:nil]; // because of popover mode
                                       [weakSelf sendUserToSystemiCloudSettings: sender];
                                   }];
    [alert addAction: fractalCloud];
    
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle: NSLocalizedString(@"Later Maybe", nil) style:UIAlertActionStyleCancel
                                                          handler:^(UIAlertAction * action)
                                    {
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
    NSURL* url = [NSURL URLWithString: UIApplicationOpenSettingsURLString];
    [[UIApplication sharedApplication] openURL: url options: @{} completionHandler:^(BOOL success) {
        return;
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
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    // Should have a test for layout type
    return [MDBResizingWidthFlowLayoutDelegate collectionView: collectionView layout: collectionViewLayout sizeForItemAtIndexPath: indexPath withBaseSize: self.baseCellSize];
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
    return [UICollectionViewCell new];
}

#pragma mark - UICollectionViewDelegate
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
