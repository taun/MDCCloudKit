//  Created by Taun Chapman on 05/26/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

#import "MDCKRecordTypeDefinition.h"

@implementation MDCKRecordTypeDefinition

-(void)encodeWithCoder:(NSCoder *)aCoder
{
    if (_typeString) [aCoder encodeObject: _typeString forKey: @"typeString"];

    if (_fields && _fields.count > 0) [aCoder encodeObject: _fields forKey: @"fields"];
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
    _typeString = [aDecoder decodeObjectForKey: @"typeString"];
    _fields = [aDecoder decodeObjectForKey: @"fields"];
}

-(NSMutableSet *)fields
{
    if (!_fields) {
        _fields = [NSMutableSet new];
    }
    return _fields;
}

@end
