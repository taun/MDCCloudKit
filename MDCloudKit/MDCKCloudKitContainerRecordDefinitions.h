//
//  MDCKCloudKitContainerRecordTypes.h
//  DaisyCloudAdmin
//
//  Created by Taun Chapman on 05/26/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MDCKCloudKitContainerRecordDefinitions : NSObject

@property NSString                      *containerName;
@property NSString                      *containerIdentifier;
@property(nonatomic) NSMutableDictionary*recordTypes;

@end
