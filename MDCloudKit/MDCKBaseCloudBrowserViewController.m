//
//  MDCKBaseCloudBrowserViewController.m
//  MDCloudKit
//
//  Created by Taun Chapman on 05/23/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

#import "MDCKBaseCloudBrowserViewController.h"

@interface MDCKBaseCloudBrowserViewController ()

@end

@implementation MDCKBaseCloudBrowserViewController


-(void) fetchCloudRecordsWithPredicate: (NSPredicate*)predicate andSortDescriptors: (NSArray*)descriptors
{
    self.getSelectedButton.enabled = NO;
    
    [self.appModel.cloudManager fetchPublicRecordsWithPredicate: predicate sortDescriptor: descriptors cloudKeys: self.cloudDownloadKeys completionHandler:^(NSArray *records, NSError* error)
     {
         [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible: NO];
         [self.activityIndicator stopAnimating];
         
         if (!error)
         {
             self.publicCloudRecords = records;
             self.networkConnected = YES;
             
             if (self.collectionView.numberOfSections >= 1)
             {
                 [self.collectionView reloadSections: [NSIndexSet indexSetWithIndex: 0]];
             } else
             {
                 [self.collectionView reloadData];
             }
             
             if (self.publicCloudRecords.count > 0)
             {
                 self.searchButton.enabled = YES;
             }
             
         } else
         {
             self.networkConnected = NO;
             NSString *title;
             NSString *message;
             
             if (error.code == 4)
             {
                 title = NSLocalizedString(@"Can't Browse", nil);
                 message = error.localizedDescription;
             } else
             {
                 title = NSLocalizedString(@"Can't Browse", nil);
                 message = error.localizedDescription;
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
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible: YES];
    [self.activityIndicator startAnimating];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self updateCollectionViewOffsetForNavAndSearch];
}

-(void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self updateSearchResultsForSearchController: self.searchController];
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
