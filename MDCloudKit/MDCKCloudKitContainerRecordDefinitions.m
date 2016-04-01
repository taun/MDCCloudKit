//
//  MDCKCloudKitContainerRecordTypes.m
//  DaisyCloudAdmin
//
//  Created by Taun Chapman on 05/26/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

#import "MDCKCloudKitContainerRecordDefinitions.h"

@implementation MDCKCloudKitContainerRecordDefinitions

-(void)encodeWithCoder:(NSCoder *)aCoder
{
    if (_containerName) [aCoder encodeObject: self.containerName forKey: @"containerName"];

    if (_containerIdentifier) [aCoder encodeObject: self.containerIdentifier forKey: @"containerIdentifier"];
    
    if (_recordTypes && _recordTypes.count > 0) [aCoder encodeObject: self.recordTypes forKey: @"recordTypes"];
}

-(instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self) {
        
        [self decodeVersion1WithCoder:  aDecoder];
        
    }
    //    DDLogInfo(@"Loaded Fractal: %@",self.name);
    return self;
}

-(void) decodeVersion1WithCoder: (NSCoder*)aDecoder
{
    _containerName = [aDecoder decodeObjectForKey: @"containerName"];
    _containerIdentifier = [aDecoder decodeObjectForKey: @"containerIdentifier"];
    _recordTypes = [aDecoder decodeObjectForKey: @"recordTypes"];
}


-(NSMutableDictionary *)recordTypes
{
    if (!_recordTypes) {
        _recordTypes = [NSMutableDictionary new];
    }
    return _recordTypes;
}

@end
