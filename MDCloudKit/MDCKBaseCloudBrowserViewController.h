//  Created by Taun Chapman on 05/23/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MDCKCloudManagerAppModelProtocol.H"

/*!
 Base class for searching CloudKit app public container.
 
 Includes search and downloading.
 
 Needs better search, categorisation by user, latest, rated? Categories need to be handled by a subclass or delegate.
 */
@interface MDCKBaseCloudBrowserViewController : UIViewController <UICollectionViewDataSource,
                                                                    UICollectionViewDelegate,
                                                                    UICollectionViewDelegateFlowLayout,
                                                                    UISearchResultsUpdating,
                                                                    UISearchControllerDelegate,
                                                                    UISearchBarDelegate>

/*!
 Application Global model
 */
@property (nonatomic,strong) id<MDCKCloudManagerAppModelProtocol>           appModel;
/*!
 Fetched public cloud records
 */
@property(nonatomic,readonly,strong) NSMutableArray                         *publicCloudRecords;
/*!
 Keys to fetch of public records
 */
@property(nonatomic,strong) NSArray                                         *cloudDownloadKeys;
/*!
 Whether connected to the network
 */
@property(nonatomic,assign,getter=isNetworkConnected) BOOL                  networkConnected;
/*!
 Cloud search controller
 */
@property(nonatomic,strong) UISearchController                              *searchController;
/*!
 The collectionView for showing the records
 */
@property (weak, nonatomic) IBOutlet UICollectionView                       *collectionView;
/*!
 Fetch activity indicator
 */
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView                *activityIndicator;
/*!
 Search bar view container
 */
@property (weak, nonatomic) IBOutlet UIView                                 *searchBarContainer;
/*!
 Outlet for search bar height to make appear and disappear
 */
@property (weak, nonatomic) IBOutlet NSLayoutConstraint                     *searchBarContainerHeightConstraint;
/*!
 Standard search button
 */
@property (weak, nonatomic) IBOutlet UIBarButtonItem                        *searchButton;
/*!
 button outlet enabled and disabled based on whether there is a current selection
 */
@property (weak, nonatomic) IBOutlet UIBarButtonItem                        *getSelectedButton;
/*!
 Setup the search bar controller
 */
-(void)setupSearchController;
/*!
 Setup the search bar controller
 */
-(void)updateCollectionViewOffsetForNavAndSearch;
/*!
 Fetch the cloud records
 
 @param predicate   search predicate
 @param descriptors sort descriptors
 */
-(void) fetchCloudRecordsWithPredicate: ( NSPredicate* _Nullable )predicate sortDescriptors: (NSArray* _Nullable)descriptors timeout: (NSTimeInterval) timeout;
/*!
 For use by subclasses
 */
-(void) handleFetchRequestSuccess;
/*!
 For use by subclasses
 
 @param error the fetch error
 */
-(void) handleFetchRequestError: (NSError*)error;
/*!
 Download action
 
 @param sender the button sender
 */
- (IBAction)downloadSelected:(id _Nullable)sender;
/*!
 Activate the search
 
 @param sender button sender
 */
- (IBAction)activateSearch:(id _Nullable)sender;

@end
