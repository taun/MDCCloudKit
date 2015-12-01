//  Created by Taun Chapman on 05/26/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

@import UIKit;


@class MDCKCloudKitContainerRecordDefinitions;
@class MDCKCSVDataObject;

@interface CloudAdminCSVUploader : NSObject

/*!
 Definition of the CloudKit CKRecordType and attributes
 */
@property(nonatomic,strong) MDCKCloudKitContainerRecordDefinitions    *recordDefinitions;
/*!
 Data to be exported to the cloud
 */
@property(nonatomic,strong) MDCKCSVDataObject                         *importedCSVData;

@property(nonatomic,assign) BOOL                                      applyExport;

-(IBAction) bootstrapDaisyCKData:(id)sender;
-(IBAction) importCSVData:(id)sender;
-(IBAction) sendDataToPublicCloudContainer:(id)sender;

@end

