//  Created by Taun Chapman on 05/23/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MDCloudKit/MDCKCloudManagerAppModelProtocol.H>

@interface MDCKBaseCloudBrowserViewController : UIViewController <UICollectionViewDataSource,
                                                                    UICollectionViewDelegate,
                                                                    UICollectionViewDelegateFlowLayout,
                                                                    UISearchResultsUpdating,
                                                                    UISearchControllerDelegate,
                                                                    UISearchBarDelegate>

@property (nonatomic,strong) id<MDCKCloudManagerAppModelProtocol>           appModel;
@property(nonatomic,strong) NSArray                                         *publicCloudRecords;
@property(nonatomic,strong) NSArray                                         *cloudDownloadKeys;
@property(nonatomic,assign,getter=isNetworkConnected) BOOL                  networkConnected;
@property(nonatomic,strong) UISearchController                              *searchController;

@property (weak, nonatomic) IBOutlet UICollectionView                       *collectionView;

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView                *activityIndicator;
@property (weak, nonatomic) IBOutlet UIView                                 *searchBarContainer;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint                     *searchBarContainerHeightConstraint;
@property (weak, nonatomic) IBOutlet UIBarButtonItem                        *searchButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem                        *getSelectedButton;

-(void)setupSearchController;
-(void)fetchCloudRecordsWithPredicate: (NSPredicate*)predicate andSortDescriptors: (NSArray*)descriptors;

- (IBAction)downloadSelected:(id)sender;
- (IBAction)activateSearch:(id)sender;

@end
