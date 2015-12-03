//  Created by Taun Chapman on 05/26/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

#import "CloudAdminCSVUploader.h"

#import "MDCKCloudKitContainerRecordDefinitions.h"
#import "MDCKRecordFieldDefinition.h"
#import "MDCKRecordTypeDefinition.h"
#import "MDCKCSVDataObject.h"
#import "MDLCloudKitManager.h"

@import CloudKit;



@interface CloudAdminCSVUploader ()
@property(nonatomic,strong) NSMutableArray      *recordsToExport;
@property(nonatomic,strong) MDLCloudKitManager  *cloudKitManager;
@end

@implementation CloudAdminCSVUploader

- (instancetype)init {
    self = [super init];
    if (self) {
        // Add your subclass-specific initialization here.
        _cloudKitManager = [[MDLCloudKitManager alloc]initWithIdentifier: @"iCloud.com.moedae.Daisy-Sensor" andRecordType: nil];
    }
    return self;
}



- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError {
    // Insert code here to write your document to data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning nil.
    // You can also choose to override -fileWrapperOfType:error:, -writeToURL:ofType:error:, or -writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.
//    [NSException raise:@"UnimplementedMethod" format:@"%@ is unimplemented", NSStringFromSelector(_cmd)];
    
    NSMutableData* archiveData = [[NSMutableData alloc]init];
    NSKeyedArchiver* archiver = [[NSKeyedArchiver alloc]initForWritingWithMutableData: archiveData];
    archiver.outputFormat = NSPropertyListXMLFormat_v1_0;
    [archiver encodeObject: self.recordDefinitions forKey: @"recordDefinitions"];
    [archiver finishEncoding];
    
    return archiveData;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError {
    // Insert code here to read your document from the given data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning NO.
    // You can also choose to override -readFromFileWrapper:ofType:error: or -readFromURL:ofType:error: instead.
    // If you override either of these, you should also override -isEntireFileLoaded to return NO if the contents are lazily loaded.
    
//    [NSException raise:@"UnimplementedMethod" format:@"%@ is unimplemented", NSStringFromSelector(_cmd)];
    
    NSKeyedUnarchiver* unarchiver = [[NSKeyedUnarchiver alloc]initForReadingWithData: data];
    self.recordDefinitions = [unarchiver decodeObjectForKey: @"recordDefinitions"];
    
    return YES;
}

-(IBAction)bootstrapDaisyCKData:(id)sender
{
    self.recordDefinitions = [self createInitialDaisyCloudKitDefinitions];
    
    for (NSString* recordTypeKey in self.recordDefinitions.recordTypes)
    {
        MDCKRecordTypeDefinition* recordType = self.recordDefinitions.recordTypes[recordTypeKey];
        for (MDCKRecordFieldDefinition* field in recordType.fields)
        {
            if (field.isReference)
            {
                NSMutableArray* fetchedRecords = [NSMutableArray new];
                
                [self.cloudKitManager fetchPublicRecordsWithType: field.referenceRecordType
                                                       predicate: nil
                                                 sortDescriptors: nil
                                                       cloudKeys: @[field.referenceRecordKey]
                                                qualityOfService: NSQualityOfServiceBackground
                                                  perRecordBlock:^(CKRecord *record) {
                                                      [fetchedRecords addObject: record];
                                                  }
                                               completionHandler:^(CKQueryCursor* cursor, NSError *error) {
                                                   //
                                               }];
                
                field.potentialReferenceRecordsArray = fetchedRecords;
            }
        }
    }
}

-(MDCKCloudKitContainerRecordDefinitions*)createInitialDaisyCloudKitDefinitions
{
    MDCKCloudKitContainerRecordDefinitions* daisyCloudDefinitions = [MDCKCloudKitContainerRecordDefinitions new];
    
    MDCKRecordTypeDefinition* categoryRecord = [MDCKRecordTypeDefinition new];
    categoryRecord.typeString = @"DaisyCategory";
    {
        MDCKRecordFieldDefinition* catIdentifierField = [MDCKRecordFieldDefinition new];
        catIdentifierField.csvColumnIdentifier = @"Category_Name";
        catIdentifierField.fieldKeyString = @"identifier";
        catIdentifierField.dataClass = [NSString class];
        catIdentifierField.dataTransformers = @[@"trimWhiteSpace:", @"transformToLower:"];
        
        [categoryRecord.fields addObject: catIdentifierField];
        
        MDCKRecordFieldDefinition* catNameField = [MDCKRecordFieldDefinition new];
        catNameField.csvColumnIdentifier = @"Category_Description";
        catNameField.fieldKeyString = @"name";
        catNameField.dataClass = [NSString class];
        
        [categoryRecord.fields addObject: catNameField];
    }
    daisyCloudDefinitions.recordTypes[categoryRecord.typeString] = categoryRecord;
    

    MDCKRecordTypeDefinition* zoneRecord = [MDCKRecordTypeDefinition new];
    zoneRecord.typeString = @"DaisyZones";
    {
        MDCKRecordFieldDefinition* zoneIdentifierField = [MDCKRecordFieldDefinition new];
        zoneIdentifierField.csvColumnIdentifier = @"ZoneName";
        zoneIdentifierField.fieldKeyString = @"identifier";
        zoneIdentifierField.dataClass = [NSString class];
        zoneIdentifierField.dataTransformers = @[@"trimWhiteSpace:", @"transformToLower:"];
        
        [zoneRecord.fields addObject: zoneIdentifierField];

        MDCKRecordFieldDefinition* zoneNameField = [MDCKRecordFieldDefinition new];
        zoneNameField.csvColumnIdentifier = @"ZoneDescription";
        zoneNameField.fieldKeyString = @"name";
        zoneNameField.dataClass = [NSString class];
        
        [zoneRecord.fields addObject: zoneNameField];

        MDCKRecordFieldDefinition* zoneMinTempField = [MDCKRecordFieldDefinition new];
        zoneMinTempField.csvColumnIdentifier = @"Min_F";
        zoneMinTempField.fieldKeyString = @"temperatureMinInC";
        zoneMinTempField.dataClass = [NSNumber class];
        zoneMinTempField.dataTransformers = @[@"stringToNumber:", @"farenheitToCelsius:"];
        
        [zoneRecord.fields addObject: zoneMinTempField];

        MDCKRecordFieldDefinition* zoneMaxTempField = [MDCKRecordFieldDefinition new];
        zoneMaxTempField.csvColumnIdentifier = @"Max";
        zoneMaxTempField.fieldKeyString = @"temperatureMaxInC";
        zoneMaxTempField.dataClass = [NSNumber class];
        zoneMaxTempField.dataTransformers = @[@"stringToNumber:", @"farenheitToCelsius:"];
        
        [zoneRecord.fields addObject: zoneMaxTempField];
    }
    daisyCloudDefinitions.recordTypes[zoneRecord.typeString] = zoneRecord;
    
    
    MDCKRecordTypeDefinition* lightRecord = [MDCKRecordTypeDefinition new];
    lightRecord.typeString = @"DaisyLight";
    {
        MDCKRecordFieldDefinition* lightIdentifierField = [MDCKRecordFieldDefinition new];
        lightIdentifierField.csvColumnIdentifier = @"LightIndex";
        lightIdentifierField.fieldKeyString = @"identifier";
        lightIdentifierField.dataClass = [NSString class];
        lightIdentifierField.dataTransformers = @[@"trimWhiteSpace:", @"transformToLower:"];
        
        [lightRecord.fields addObject: lightIdentifierField];
        
        MDCKRecordFieldDefinition* lightNameField = [MDCKRecordFieldDefinition new];
        lightNameField.csvColumnIdentifier = @"LIGHT_TAG2";
        lightNameField.fieldKeyString = @"name";
        lightNameField.dataClass = [NSString class];
        
        [lightRecord.fields addObject: lightNameField];
        
        MDCKRecordFieldDefinition* lightMinField = [MDCKRecordFieldDefinition new];
        lightMinField.csvColumnIdentifier = @"LUX_MIN";
        lightMinField.fieldKeyString = @"minLightInLux";
        lightMinField.dataClass = [NSNumber class];
        lightMinField.dataTransformers = @[@"stringToNumber:"];
        
        [lightRecord.fields addObject: lightMinField];

        MDCKRecordFieldDefinition* lightMaxField = [MDCKRecordFieldDefinition new];
        lightMaxField.csvColumnIdentifier = @"LUX_MAX";
        lightMaxField.fieldKeyString = @"maxLightInLux";
        lightMaxField.dataClass = [NSNumber class];
        lightMaxField.dataTransformers = @[@"stringToNumber:"];
        
        [lightRecord.fields addObject: lightMaxField];
    }
    daisyCloudDefinitions.recordTypes[lightRecord.typeString] = lightRecord;

    MDCKRecordTypeDefinition* waterRecord = [MDCKRecordTypeDefinition new];
    waterRecord.typeString = @"DaisyWater";
    {
        MDCKRecordFieldDefinition* waterIdentifierField = [MDCKRecordFieldDefinition new];
        waterIdentifierField.csvColumnIdentifier = @"WaterIndex";
        waterIdentifierField.fieldKeyString = @"identifier";
        waterIdentifierField.dataClass = [NSString class];
        waterIdentifierField.dataTransformers = @[@"trimWhiteSpace:", @"transformToLower:"];
        
        [waterRecord.fields addObject: waterIdentifierField];
        
        MDCKRecordFieldDefinition* waterNameField = [MDCKRecordFieldDefinition new];
        waterNameField.csvColumnIdentifier = @"WATERING_TYPE_TAG";
        waterNameField.fieldKeyString = @"name";
        waterNameField.dataClass = [NSString class];
        
        [waterRecord.fields addObject: waterNameField];
    }
    daisyCloudDefinitions.recordTypes[waterRecord.typeString] = waterRecord;

    MDCKRecordTypeDefinition* plantRecord = [MDCKRecordTypeDefinition new];
    plantRecord.typeString = @"DaisyPlant";
    {
        MDCKRecordFieldDefinition* plantIdentifierField = [MDCKRecordFieldDefinition new];
        plantIdentifierField.csvColumnIdentifier = @"scientificName";
        plantIdentifierField.fieldKeyString = @"identifier";
        plantIdentifierField.dataClass = [NSString class];
        plantIdentifierField.dataTransformers = @[@"trimWhiteSpace:", @"transformToLower:"];
        
        [plantRecord.fields addObject: plantIdentifierField];
        
        MDCKRecordFieldDefinition* plantCommonNameLowerField = [MDCKRecordFieldDefinition new];
        plantCommonNameLowerField.csvColumnIdentifier = @"commonNames";
        plantCommonNameLowerField.fieldKeyString = @"commonNamesLower";
        plantCommonNameLowerField.dataClass = [NSArray class];
        plantCommonNameLowerField.dataTransformers = @[@"trimWhiteSpace:", @"transformToLower:", @"commaSeparatedToArray:"];
        
        [plantRecord.fields addObject: plantCommonNameLowerField];

        MDCKRecordFieldDefinition* plantCommonNameField = [MDCKRecordFieldDefinition new];
        plantCommonNameField.csvColumnIdentifier = @"commonNames";
        plantCommonNameField.fieldKeyString = @"commonNames";
        plantCommonNameField.dataClass = [NSArray class];
        plantCommonNameField.dataTransformers = @[@"trimWhiteSpace:", @"commaSeparatedToArray:"];
        
        [plantRecord.fields addObject: plantCommonNameField];
        
        MDCKRecordFieldDefinition* plantSciNameField = [MDCKRecordFieldDefinition new];
        plantSciNameField.csvColumnIdentifier = @"scientificName";
        plantSciNameField.fieldKeyString = @"scientificName";
        plantSciNameField.dataClass = [NSString class];
        plantSciNameField.dataTransformers = @[@"trimWhiteSpace:"];
        
        [plantRecord.fields addObject: plantSciNameField];

        MDCKRecordFieldDefinition* plantCategoryField = [MDCKRecordFieldDefinition new];
        plantCategoryField.csvColumnIdentifier = @"category";
        plantCategoryField.fieldKeyString = @"categoryReferences";
        plantCategoryField.reference = YES;
        plantCategoryField.referenceRecordType = @"DaisyCategory";
        plantCategoryField.referenceRecordKey = @"identifier";
        plantCategoryField.dataClass = [NSArray class];
        plantCategoryField.dataTransformers = @[@"trimWhiteSpace:", @"transformToLower:", @"spaceSeparatedToArray:"];
        
        [plantRecord.fields addObject: plantCategoryField];
        {
            MDCKRecordFieldDefinition* plantLightField = [MDCKRecordFieldDefinition new];
            plantLightField.csvColumnIdentifier = @"light";
            plantLightField.fieldKeyString = @"lightReferences";
            plantLightField.reference = YES;
            plantLightField.referenceRecordType = @"DaisyLight";
            plantLightField.referenceRecordKey = @"identifier";
            plantLightField.dataClass = [NSArray class];
            plantLightField.dataTransformers = @[@"trimWhiteSpace:", @"transformToLower:", @"spaceSeparatedToArray:"];
            
            [plantRecord.fields addObject: plantLightField];
        }
        {
            MDCKRecordFieldDefinition* plantZoneField = [MDCKRecordFieldDefinition new];
            plantZoneField.csvColumnIdentifier = @"zone";
            plantZoneField.fieldKeyString = @"zoneReferences";
            plantZoneField.reference = YES;
            plantZoneField.referenceRecordType = @"DaisyZones";
            plantZoneField.referenceRecordKey = @"identifier";
            plantZoneField.dataClass = [NSArray class];
            plantZoneField.dataTransformers = @[@"trimWhiteSpace:", @"transformToLower:", @"spaceSeparatedToArray:"];
            
            [plantRecord.fields addObject: plantZoneField];
        }
        {
            MDCKRecordFieldDefinition* plantWaterField = [MDCKRecordFieldDefinition new];
            plantWaterField.csvColumnIdentifier = @"water";
            plantWaterField.fieldKeyString = @"waterReferences";
            plantWaterField.reference = YES;
            plantWaterField.referenceRecordType = @"DaisyWater";
            plantWaterField.referenceRecordKey = @"identifier";
            plantWaterField.dataClass = [NSArray class];
            plantWaterField.dataTransformers = @[@"trimWhiteSpace:", @"transformToLower:", @"spaceSeparatedToArray:"];
            
            [plantRecord.fields addObject: plantWaterField];
        }
        {
            MDCKRecordFieldDefinition* plantWikiField = [MDCKRecordFieldDefinition new];
            plantWikiField.csvColumnIdentifier = @"wiki";
            plantWikiField.fieldKeyString = @"wiki";
            plantWikiField.dataClass = [NSString class];
            
            [plantRecord.fields addObject: plantWikiField];
        }
    }
    daisyCloudDefinitions.recordTypes[plantRecord.typeString] = plantRecord;

    
    return daisyCloudDefinitions;
}

-(IBAction)importCSVData:(id)sender
{
    
    // Create and configure the panel.
//    NSOpenPanel* panel = [NSOpenPanel openPanel];
//    [panel setCanChooseDirectories: NO];
//    [panel setAllowsMultipleSelection: NO];
//    [panel setMessage:@"Import a csv data file."];
//    
//    // Display the panel attached to the document's window.
//    [panel beginSheetModalForWindow:window completionHandler:^(NSInteger result){
//        if (result == NSFileHandlingPanelOKButton) {
//            NSURL* theDoc = [[panel URLs] firstObject];
//            
//            // Use the URLs to build a list of items to import.
//            [self importCSVURL: theDoc];
//        }
//        
//    }];
    
}

-(void)importCSVURL: (NSURL*)theCSVFile
{
    _importedCSVData = [MDCKCSVDataObject csvDataObjectWithContentsOfCSVURL: theCSVFile];
    NSDictionary* csvData = _importedCSVData.parsedColumns;
    NSLog(@"%@", csvData);
}

-(IBAction) sendDataToPublicCloudContainer:(id)sender
{
    self.recordsToExport = [NSMutableArray new];
    
    MDCKRecordTypeDefinition* categoryDefinition = self.recordDefinitions.recordTypes[@"DaisyPlant"];
    if (categoryDefinition)
    {
        NSDictionary* parsedData = self.importedCSVData.parsedColumns;
        NSUInteger recordCount = self.importedCSVData.numberOfImportedLines;
        
        if (recordCount > 1)
        {
            for (NSUInteger index=0; index < recordCount-1; index++)
            {
                CKRecord* record;
                record = [[CKRecord alloc] initWithRecordType: categoryDefinition.typeString];
#pragma message "TODO this should all be in the FieldDefinition class"
                for (MDCKRecordFieldDefinition* fieldDef in categoryDefinition.fields)
                {
                    NSString* recordFieldKey = fieldDef.fieldKeyString;
                    
                    id untransformedValue = parsedData[fieldDef.csvColumnIdentifier][index];
                    id recordFieldValue = [fieldDef applyTransformersTo: untransformedValue];

                    if (!fieldDef.isReference)
                    {
                        if (recordFieldValue) record[recordFieldKey] = recordFieldValue;
                    }
                    else if (fieldDef.isReference && [recordFieldValue count] > 0)
                    {
                        NSMutableArray* referenceRecords = [NSMutableArray new];
                        for (NSString* identifier in recordFieldValue)
                        {
                            CKReference* reference = [fieldDef referenceRecordForIdentifier: identifier];
                            if (reference) [referenceRecords addObject: reference];
                        }
                        record[recordFieldKey] = referenceRecords;
                    }
                }
                
                [self.recordsToExport addObject: record];

                NSLog(@"LineNumber: %lu; Record: %@",index,record);
            }
            
            NSMutableArray* cloudKeys = [NSMutableArray new];
            for (MDCKRecordFieldDefinition* fieldDef in categoryDefinition.fields)
            {
                [cloudKeys addObject: fieldDef.fieldKeyString];
            }
            
#pragma message "Remove most of following code? Why fetch before saving but do nothing with fetched records?"
            
            NSMutableArray* fetchedRecords = [NSMutableArray new];
            
            [self.cloudKitManager fetchPublicRecordsWithType: categoryDefinition.typeString
                                                   predicate: nil
                                             sortDescriptors: nil
                                                   cloudKeys: cloudKeys
                                            qualityOfService: NSQualityOfServiceUserInitiated
                                              perRecordBlock:^(CKRecord *record) {
                                                  [fetchedRecords addObject: record];
                                              }
                                           completionHandler:^(CKQueryCursor* cursor, NSError *error) {
                                               //
                                           }];
            
            [self compareExportRecordsOfType: categoryDefinition.typeString toExistingRecords: fetchedRecords];
        }
    }
}

/*!
 Saves records in property recordsToExport
 
 @param recordType     not used!
 @param currentRecords not used!
 */
-(void)compareExportRecordsOfType: (NSString*)recordType toExistingRecords: (NSArray*)currentRecords
{
//    NSMutableArray* recordsToAdd = [NSMutableArray new];
//    NSMutableArray* recordsToUpdate = [NSMutableArray new];
    
    NSLog(@"Existing Records of type: %@; %@", recordType, currentRecords);
    
    if (self.applyExport)
    {
//        self.cloudKitManager.cloudKitRecordType = recordType;
        
        [self.cloudKitManager savePublicRecords: self.recordsToExport qualityOfService: NSQualityOfServiceUserInitiated withCompletionHandler:^(NSError *error) {
            NSLog(@"Saved Records: %@; Error:%@", self.recordsToExport, error);
        }];
    }
}


@end
