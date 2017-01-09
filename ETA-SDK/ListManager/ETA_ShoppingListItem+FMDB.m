//
//  ETA_ShoppingListItem+FMDB.m
//  ETA-SDK
//
//  Created by Laurie Hufford on 7/22/13.
//  Copyright (c) 2013 eTilbudsavis. All rights reserved.
//

#import "ETA_ShoppingListItem+FMDB.h"
#import "ETA_Log.h"

#import "FMDatabase.h"
#import "FMResultSet.h"

#define kSLI_ID                 @"id"
#define kSLI_ERN                @"ern"
#define kSLI_MODIFIED           @"modified"
#define kSLI_DESCRIPTION        @"description"
#define kSLI_COUNT              @"count"
#define kSLI_TICK               @"tick"
#define kSLI_OFFER_ID           @"offer_id"
#define kSLI_CREATOR            @"creator"
#define kSLI_SHOPPING_LIST_ID   @"shopping_list_id"
#define kSLI_STATE              @"state"
#define kSLI_PREV_ITEM_ID       @"previous_item_id"
#define kSLI_META               @"meta"
#define kSLI_USERID             @"userID"


NSString* const kETA_ListItem_DBQuery_UserID = kSLI_USERID;
NSString* const kETA_ListItem_DBQuery_SyncState = kSLI_STATE;
NSString* const kETA_ListItem_DBQuery_ListID = kSLI_SHOPPING_LIST_ID;
NSString* const kETA_ListItem_DBQuery_PrevItemID = kSLI_PREV_ITEM_ID;
NSString* const kETA_ListItem_DBQuery_OfferID = kSLI_OFFER_ID;

@implementation ETA_ShoppingListItem (FMDB)

+ (NSArray*) dbFieldNames
{
    return @[kSLI_ID,
             kSLI_ERN,
             kSLI_MODIFIED,
             kSLI_DESCRIPTION,
             kSLI_COUNT,
             kSLI_TICK,
             kSLI_OFFER_ID,
             kSLI_CREATOR,
             kSLI_SHOPPING_LIST_ID,
             kSLI_STATE,
             kSLI_PREV_ITEM_ID,
             kSLI_META,
             kSLI_USERID,
             ];
}

+ (NSDictionary *)JSONKeyPathsByDBFieldName
{
    return @{kSLI_ID: @"id",
             kSLI_ERN: @"ern",
             kSLI_MODIFIED: @"modified",
             kSLI_DESCRIPTION: @"description",
             kSLI_COUNT: @"count",
             kSLI_TICK: @"tick",
             kSLI_OFFER_ID: @"offer_id",
             kSLI_CREATOR: @"creator",
             kSLI_SHOPPING_LIST_ID: @"shopping_list_id",
             kSLI_STATE: @"state",
             kSLI_PREV_ITEM_ID: @"previous_id",
             kSLI_META: @"meta",
             kSLI_USERID: @"syncUserID",
             };
}

#pragma mark - Converters

+ (ETA_ShoppingListItem*) shoppingListItemFromResultSet:(FMResultSet*)res
{
    if (!res)
        return nil;
    
    NSDictionary* resDict = [res resultDictionary];
    
    NSMutableDictionary* jsonDict = [NSMutableDictionary dictionaryWithCapacity:resDict.count];
    
    [jsonDict setValue:[res stringForColumn:kSLI_ID] forKey:@"id"];
    [jsonDict setValue:[res stringForColumn:kSLI_ERN] forKey:@"ern"];
    [jsonDict setValue:[res stringForColumn:kSLI_MODIFIED] forKey:@"modified"];
    [jsonDict setValue:[res stringForColumn:kSLI_DESCRIPTION] forKey:@"description"];
    [jsonDict setValue:@([res intForColumn:kSLI_COUNT]) forKey:@"count"];
    [jsonDict setValue:@([res intForColumn:kSLI_TICK]) forKey:@"tick"];
    [jsonDict setValue:[res stringForColumn:kSLI_OFFER_ID] forKey:@"offer_id"];
    [jsonDict setValue:[res stringForColumn:kSLI_CREATOR] forKey:@"creator"];
    [jsonDict setValue:[res stringForColumn:kSLI_SHOPPING_LIST_ID] forKey:@"shopping_list_id"];
    [jsonDict setValue:[res stringForColumn:kSLI_PREV_ITEM_ID] forKey:@"previous_id"];
    
    NSString* metaJSONString = [res stringForColumn:kSLI_META];
    if (metaJSONString)
    {
        id metaDict = [NSJSONSerialization JSONObjectWithData:[metaJSONString dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
        if (metaDict)
            jsonDict[@"meta"] = metaDict;
    }
    
    ETA_ShoppingListItem* item = [ETA_ShoppingListItem objectFromJSONDictionary:jsonDict];
    // state & sync is not part of the JSON parsing, so set manually
    item.state = (ETA_DBSyncState)[res longForColumn:kSLI_STATE];
    item.syncUserID = [res stringForColumn:kSLI_USERID];
    return item;
}

- (NSDictionary*) dbParameterDictionary
{
    // get the json-ified values for the item
    NSMutableDictionary* jsonDict = [[self JSONDictionary] mutableCopy];
    jsonDict[@"state"] = @(self.state);
    jsonDict[@"syncUserID"] = self.syncUserID ?: NSNull.null;
    jsonDict[@"tick"] = @(self.tick); // because server's json needs to be in string form 'true' / 'false'
    jsonDict[@"offer_id"] = (self.offerID) ?: NSNull.null; // because server can't handle json with NULL or nil
    
    // convert meta dict into string
    if (self.meta)
    {
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:self.meta options:0 error:nil];
        [jsonDict setValue:jsonData ? [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding] : nil forKey:@"meta"];
    }
    
    
    NSDictionary* jsonKeysByFieldNames = [[self class] JSONKeyPathsByDBFieldName];
    
    // map the json keys -> db keys
    NSMutableDictionary* params = [NSMutableDictionary dictionaryWithCapacity:jsonKeysByFieldNames.count];
    [jsonKeysByFieldNames enumerateKeysAndObjectsUsingBlock:^(NSString* fieldName, NSString* JSONKeyPath, BOOL *stop) {
        id val = nil;
        if (JSONKeyPath)
            val = [jsonDict valueForKeyPath:JSONKeyPath];
        
        if (!val)
            val = NSNull.null;
        
        params[fieldName] = val;
    }];
    return params;
}

#pragma mark - table operations

+ (BOOL) createTable:(NSString*)tableName inDB:(FMDatabase*)db
{
    NSString* fieldsStr = [@[kSLI_ID, @"text primary key,",
                             kSLI_ERN, @"text not null,",
                             kSLI_MODIFIED, @"text not null,",
                             kSLI_DESCRIPTION, @"text,",
                             kSLI_COUNT, @"integer not null,",
                             kSLI_TICK, @"integer not null,",
                             kSLI_OFFER_ID, @"text,",
                             kSLI_CREATOR, @"text,",
                             kSLI_SHOPPING_LIST_ID, @"text not null,",
                             kSLI_STATE, @"integer not null,",
                             kSLI_PREV_ITEM_ID, @"text,",
                             kSLI_META, @"text,",
                             kSLI_USERID, @"text"
                             ] componentsJoinedByString:@" "];
    
    NSString* queryStr = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@(%@);", tableName, fieldsStr];
    BOOL success = [db executeUpdate:queryStr];
    if (!success)
    {
        ETASDKLogError(@"[ETA_ShoppingListItem+FMDB] Unable to create table '%@': %@", tableName, db.lastError);
    }
    return success;
}

+ (BOOL) clearTable:(NSString*)tableName inDB:(FMDatabase*)db
{
    NSString* queryStr = [NSString stringWithFormat:@"DELETE FROM %@;", tableName];
    BOOL success = [db executeUpdate:queryStr];
    if (!success)
        ETASDKLogError(@"[ETA_ShoppingListItem+FMDB] Unable to empty table '%@': %@", tableName, db.lastError);
    
    return success;
}


#pragma mark - Getters

+ (ETA_ShoppingListItem*) getItemWithID:(NSString*)itemID fromTable:(NSString*)tableName inDB:(FMDatabase*)db
{
    if (!itemID || !tableName || !db)
        return nil;
    
    NSString* query = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@=?", tableName, kSLI_ID];
    
    FMResultSet* s = [db executeQuery:query, itemID];
    ETA_ShoppingListItem* res = nil;
    if ([s next])
        res = [self shoppingListItemFromResultSet:s];
    [s close];
    
    return res;
}

+ (NSArray*) getAllItemsWhere:(NSDictionary*)whereKeyValues fromTable:(NSString*)tableName inDB:(FMDatabase*)db
{
    if (!tableName || !db)
        return nil;
    
    NSMutableDictionary* params = [NSMutableDictionary new];
    
    NSString* query = [NSString stringWithFormat:@"SELECT * FROM %@", tableName];
    
    if (whereKeyValues.count)
    {
        NSMutableArray* WHERE = [NSMutableArray array];
        
        NSArray* possibleWhereKeys = @[kETA_ListItem_DBQuery_UserID,
                                       kETA_ListItem_DBQuery_SyncState,
                                       kETA_ListItem_DBQuery_ListID,
                                       kETA_ListItem_DBQuery_PrevItemID,
                                       kETA_ListItem_DBQuery_OfferID];
        
        for (NSString* whereKey in possibleWhereKeys)
        {
            id whereVal = whereKeyValues[whereKey];
            if (!whereVal)
                continue;
            if ([whereVal isEqual:NSNull.null])
            {
                [WHERE addObject:[NSString stringWithFormat:@"%@ IS NULL", whereKey]];
            }
            else if ([whereVal isKindOfClass:NSString.class] || [query isKindOfClass:NSNumber.class])
            {
                [WHERE addObject:[NSString stringWithFormat:@"%@ == :%@", whereKey, whereKey]];
                params[whereKey] = whereVal;
            }
            else if ([whereVal isKindOfClass:NSArray.class] && ((NSArray*)whereVal).count > 0)
            {
                [WHERE addObject:[NSString stringWithFormat:@"%@ IN (%@)", whereKey, [(NSArray*)whereVal componentsJoinedByString:@","]]];
            }
        }
        
        if (WHERE.count)
            query = [query stringByAppendingString:[NSString stringWithFormat:@" WHERE %@", [WHERE componentsJoinedByString:@" AND "]]];
    }
    
    FMResultSet* s = [db executeQuery:query withParameterDictionary:params];
    NSMutableArray* items = [NSMutableArray array];
    while ([s next])
    {
        ETA_ShoppingListItem* item = [self shoppingListItemFromResultSet:s];
        if (item)
            [items addObject:item];
    }
    [s close];
    return items;
}

#pragma mark - Setters

// replace or insert an item in the db with 'list'. returns success or failure.
+ (BOOL) insertOrReplaceItem:(ETA_ShoppingListItem*)item intoTable:(NSString*)tableName inDB:(FMDatabase*)db error:(NSError * __autoreleasing *)error
{
    NSDictionary* params = [item dbParameterDictionary];
    
    NSString* query = [NSString stringWithFormat:@"INSERT OR REPLACE INTO %@ VALUES (:%@)", tableName, [[self dbFieldNames] componentsJoinedByString:@", :"]];
    BOOL success = [db executeUpdate:query withParameterDictionary:params];
    if (!success) {
        if (error)
            *error = db.lastError;
        ETASDKLogError(@"[ETA_ShoppingListItem+FMDB] Unable to Insert/Replace Item %@: %@", params, db.lastError);
    }
    return success;
}

+ (BOOL) deleteItem:(NSString*)itemID fromTable:(NSString*)tableName inDB:(FMDatabase*)db error:(NSError * __autoreleasing *)error
{
    NSString* query = [NSString stringWithFormat:@"DELETE FROM %@ WHERE %@=?", tableName, kSLI_ID];
    
    BOOL success = [db executeUpdate:query, itemID];
    if (!success) {
        if (error)
            *error = db.lastError;
        ETASDKLogError(@"[ETA_ShoppingListItem+FMDB] Unable to Delete Item %@: %@", itemID, db.lastError);
    }
    
    return success;
}

@end