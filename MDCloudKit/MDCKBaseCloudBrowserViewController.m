//
//  MDCKBaseCloudBrowserViewController.m
//  MDCloudKit
//
//  Created by Taun Chapman on 05/23/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

#import "MDCKBaseCloudBrowserViewController.h"
#import "MDLCloudKitManager.h"

@interface MDCKBaseCloudBrowserViewController ()

@property(nonatomic,readwrite,strong) NSMutableArray                         *publicCloudRecords;
@property(nonatomic,strong) NSMutableDictionary                              *publicRecordsCacheByRecordIDName;

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

-(void) fetchCloudRecordsWithPredicate: (NSPredicate*)predicate andSortDescriptors: (NSArray*)descriptors
{
    self.getSelectedButton.enabled = NO;
    NSDate* fetchStartDate = [NSDate date];
    
    [self.appModel.cloudKitManager fetchPublicRecordsWithPredicate: predicate sortDescriptors: descriptors cloudKeys: self.cloudDownloadKeys perRecordBlock:^(CKRecord *record) {
        //
        if (record)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                // would this ever get called if there was not a valid record?
                self.networkConnected = YES;
                
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
    } completionHandler:^(NSArray *records, NSError* error)
     {
         [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible: NO];
         [self.activityIndicator stopAnimating];
         
         if (!error)
         {
             if (self.publicCloudRecords.count > 0)
             {
                 self.searchButton.enabled = YES;
             }
         }
         else
         {
             self.networkConnected = NO;
             NSString *title;
             NSString *message;
             NSLog(@"%@ %@",NSStringFromSelector(_cmd),[error.userInfo debugDescription]);
             CKErrorCode code = error.code;
             
             switch (code) {
                 case CKErrorInternalError:
                     title = NSLocalizedString(@"Network problem", nil);
                     message = @"Please try again in couple of minutes";
                     break;
                     
                 case CKErrorPartialFailure:
                     title = NSLocalizedString(@"Network problem", nil);
                     message = @"Please try again in couple of minutes";
                     break;
                     
                 case CKErrorNetworkUnavailable:
                     title = NSLocalizedString(@"No Network", nil);
                     message = @"Please try again when connected to a network";
                     break;
                     
                 case CKErrorNetworkFailure:
                     title = NSLocalizedString(@"Network problem", nil);
                     message = @"Please try again in couple of minutes";
                     break;
                     
                 case CKErrorServiceUnavailable:
                     title = NSLocalizedString(@"Cloud Unavailable", nil);
                     message = @"iCloud is temporarily unavailable. Please try again in couple of minutes";
                     break;
                     
                 case CKErrorRequestRateLimited:
                     title = NSLocalizedString(@"Cloud Unavailable", nil);
                     message = [NSString stringWithFormat: @"iCloud is temporarily unavailable. Please try again in %@ seconds",error.userInfo[@"CKRetryAfter"]];
                     break;
                     
                 case CKErrorZoneBusy:
                     title = NSLocalizedString(@"Too Much Traffic", nil);
                     message = @"Please try again in couple of minutes";
                     break;
                     
                 default:
                     title = NSLocalizedString(@"Problem with the Cloud", nil);
                     message = @"Please try again later.";
                     break;
             }
             
             NSString *okActionTitle = NSLocalizedString(@"OK", nil);
             
             UIAlertController* alert = [UIAlertController alertControllerWithTitle: title
                                                                            message: message
                                                                     preferredStyle: UIAlertControllerStyleAlert];
             
             [alert addAction:[UIAlertAction actionWithTitle: okActionTitle style: UIAlertActionStyleCancel handler:nil]];
             
             [self presentViewController: alert animated: YES completion:^{
                 //
             }];
         }
         NSTimeInterval fetchInterval = [fetchStartDate timeIntervalSinceNow];
         NSLog(@"FractalScapes optimizer cloud fetch time interval: %f", fetchInterval);
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
    
    [self updateCollectionViewOffsetForNavAndSearch];
}

-(void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
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
                                       [weakAlert dismissViewControllerAnimated:YES completion:nil]; // because of popover mode
                                       [self sendUserToSystemiCloudSettings: sender];
                                   }];
    [alert addAction: fractalCloud];
    
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"Later Maybe" style:UIAlertActionStyleCancel
                                                          handler:^(UIAlertAction * action)
                                    {
                                        [weakAlert dismissViewControllerAnimated:YES completion:nil]; // because of popover mode
                                    }];
    [alert addAction: defaultAction];
    
    UIPopoverPresentationController* ppc = alert.popoverPresentationController;
    ppc.barButtonItem = sender;
    ppc.permittedArrowDirections = UIPopoverArrowDirectionAny;
    
    [self presentViewController:alert animated:YES completion:nil];
}

-(void)sendUserToSystemiCloudSettings: (id)sender
{
    [[UIApplication sharedApplication] openURL: [NSURL URLWithString:@"prefs:root=iCloud"]];
}


-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.searchController.delegate = nil;
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

-(void)didDismissSearchController:(UISearchController *)searchController
{
    [self updateCollectionViewOffsetForNavAndSearch];
    self.tabBarController.tabBar.hidden = NO;
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    self.searchController.active = NO;
}

- (IBAction)activateSearch:(id)sender
{
    self.searchController.active = !self.searchController.active;
}

#pragma mark - UISearchResultsUpdating
- (void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
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
    return self.isNetworkConnected ? 1 : 0;
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
