//  Created by Taun Chapman on 05/23/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MDCloudKit/MDLCloudKitManager.h>

@protocol MDCKCloudManagerAppModelProtocol <NSObject>

@property(nonatomic,readonly) MDLCloudKitManager                *cloudManager;

@end
