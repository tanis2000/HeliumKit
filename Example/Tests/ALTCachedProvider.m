//
//  ALTCachedProvider.m
//  HeliumKit
//
//  Created by Valerio Santinelli on 28/07/14.
//  Copyright (c) 2014 Valerio Santinelli. All rights reserved.
//

#import "ALTCachedProvider.h"

@implementation ALTCachedProvider

- (NSString *)loadFromDbCache:(MTLModel *)request additionalId:(NSString *)additionalId cacheKey:(NSString *)cacheKey
{
    if (additionalId == nil) {
        additionalId = @"";
    }
    NSString *stmt = @"select * from cache where endpoint = ? and additionalid = ? and cachekey = ?";
    NSArray *params = @[self.endPoint, additionalId, cacheKey];
    NSArray *res = [self.database rawQuerySync:stmt parameters:params];
    if (res.count == 0) {
        NSLog(@"There was a problem reading from the local cache with the following parameters: %@", params);
        return nil;
    }
    NSDictionary *rs = [res objectAtIndex:0];
    NSString *cachedData = [rs valueForKey:@"response"];
    return cachedData;
}

- (void)saveToDbCache:(MTLModel *)request response:(NSDictionary *)response additionalId:(NSString *)additionalId cacheKey:(NSString *)cacheKey
{
    if (additionalId == nil) {
        additionalId = @"";
    }
    
    // Remove old cached data
    NSString *deleteStmt = @"delete from cache where endpoint = ? and additionalid = ? and cachekey = ?";
    NSArray *deleteParams = @[self.endPoint, additionalId, cacheKey];
    [self.database rawQuerySync:deleteStmt parameters:deleteParams];
    
    
    NSString *stmt = @"insert into cache (endpoint, additionalid, cachekey, response) values (?, ?, ?, ?)";
    
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:response
                                                       options:NSJSONWritingPrettyPrinted // Pass 0 if you don't care about the readability of the generated string
                                                         error:&error];
    
    if (! jsonData) {
        NSLog(@"Got an error: %@", error);
        @throw @"Cannot serialize request dictionary to JSON string";
    }
    NSString *responseString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    
    NSArray *params = @[self.endPoint, additionalId, cacheKey, responseString];
    [self.database rawQuerySync:stmt parameters:params];
}

- (NSDictionary *)manageCache:(NSDictionary *)responseObject
{
    NSDictionary *res = responseObject;
    if (responseObject != nil) {
        BOOL valid = [[responseObject objectForKey:@"IsValidLocalCache"] boolValue];
        NSString *cacheKey = [responseObject objectForKey:@"CacheKey"];
        if (valid) {
            NSString *data = [self loadFromDbCache:self.request additionalId:self.additionalId cacheKey:cacheKey];
            if (data == nil) {
                return res;
            }
            NSError *error = nil;
            res = [NSJSONSerialization JSONObjectWithData:[data dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
            if (res == nil) {
                @throw @"Error converting JSON string to data";
            }
        } else {
            [self saveToDbCache:self.request response:responseObject additionalId:self.additionalId cacheKey:cacheKey];
        }
    }
    return res;
}


@end
