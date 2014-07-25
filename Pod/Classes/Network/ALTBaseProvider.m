//
//  ALTBaseProvider.m
//  HeliumKit
//
//  Created by Valerio Santinelli on 15/07/14.
//  Copyright (c) 2014 Altralogica s.r.l. All rights reserved.
//

#import "ALTBaseProvider.h"
#import "MTLFMDBAdapter.h"
#import "ALTObjectMapping.h"
#import "ALTRelationshipMapping.h"
#import "ALTRelationshipKeyMapping.h"
#import "ALTObjectMapper.h"

@implementation ALTBaseProvider

- (instancetype)initWithDatabaseController:(ALTDatabaseController *)database
                andRequestOperationManager:(AFHTTPRequestOperationManager *)manager
                                andBaseURL:(NSString *)baseURL
{
    self = [super init];
    if (self) {
        _database = database;
        _manager = manager;
        _baseURL = baseURL;
    }
    return self;
}

- (NSString *)endPoint {
    NSAssert(NO, @"endPoint should be ovrridden");
    return @"";
}

/*
- (PMKPromise *)saveModel:(id)model {
    return [PMKPromise new:^(PMKPromiseFulfiller fulfiller, PMKPromiseRejecter rejecter) {
        [self.database runDatabaseBlockInTransaction:^(FMDatabase *database) {
            NSString *deleteStatement = [MTLFMDBAdapter deleteStatementForModel:model];
            NSArray *pkValues = [MTLFMDBAdapter primaryKeysValues:model];
            NSString *insertStatement = [MTLFMDBAdapter insertStatementForModel:model];
            NSArray *colValues = [MTLFMDBAdapter columnValues:model];
            
            BOOL ok = NO;
            ok = [database executeUpdate:deleteStatement withArgumentsInArray:pkValues];
            if (!ok) {
                NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:deleteStatement, @"deleteStatement", pkValues, @"pkValues", nil];
                NSError *error = [[NSError alloc] initWithDomain:@"" code:1 userInfo:userInfo];
                rejecter(error);
            }
            ok = [database executeUpdate:insertStatement withArgumentsInArray:colValues];
            if (!ok) {
                NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:insertStatement, @"insertStatement", colValues, @"colValues", nil];
                NSError *error = [[NSError alloc] initWithDomain:@"" code:1 userInfo:userInfo];
                rejecter(error);
            }
        }].then(^(){
            fulfiller(nil);
        });
    }];
}
*/

- (PMKPromise *)fetchObjectsFromDb {
    NSAssert(NO, @"fetchObjectsFromDb has not been implemented. You can ignore this if you're using the response from the response mapper instead of the one from the database");
    return nil;
}

- (ALTObjectMapping *)objectMapping {
    NSAssert(NO, @"objectMapping should be overridden");
    return nil;
}

- (PMKPromise *)deleteOrphans {
    NSAssert(NO, @"deleteOrphans has not been implemented");
    return nil;
}

- (PMKPromise *)fetchData {
    return [PMKPromise new:^(PMKPromiseFulfiller fulfiller, PMKPromiseRejecter rejecter) {
        id fresh = [self downloadDataFromWS];
        [self fetchObjectsFromDb].then(^(id cached) {
            fulfiller(PMKManifold(cached, fresh));
        });
    }];
}

/*
- (void)deleteChildren:(ALTRelationshipMapping *)relationship masterModel:(MTLModel *)masterModel {
    if (relationship.relationshipKeys == nil) return;
    Class detailClass = relationship.objectMapping.modelClass;
    NSAssert(![detailClass instancesRespondToSelector:@selector(FMDBTableName)], @"Class %@ does not conform to MTLFMDBSerializing. Missing FMDBTableName.", NSStringFromClass(detailClass));
    NSString *detailTableName = [detailClass FMDBTableName];
    NSMutableArray *keys = [NSMutableArray array];
    NSMutableArray *values = [NSMutableArray array];
    for (ALTRelationshipKeyMapping *key in relationship.relationshipKeys) {
        id masterValue = [masterModel valueForKeyPath:key.masterKey];
        NSString *match = [NSString stringWithFormat:@"%@ = ?", key.detailKey];
        [keys addObject:match];
        [values addObject:masterValue];
    }
    NSString *stmt = [NSString stringWithFormat:@"delete from %@ where %@", detailTableName, [keys componentsJoinedByString:@" AND "]];
    [self.database runDatabaseBlockInTransaction:^(FMDatabase *database) {
        [database executeUpdate:stmt withArgumentsInArray:values];
    }];
}

- (MTLModel *)convertAndSaveModel:(Class)modelClass fromJSONDictionary:(NSDictionary *)dict {
    NSError *error = nil;
    id obj = [MTLJSONAdapter modelOfClass:modelClass fromJSONDictionary:dict error:&error];
    if (error != nil) {
        NSAssert(NO, [error localizedFailureReason]);
        return nil;
    }
    [self saveModel:obj];
    return obj;
}

- (void)convertAndSaveRelationships:(NSArray *)relationships withData:(NSDictionary *)inputData model:(MTLModel *)model {
    for (ALTRelationshipMapping *rel in relationships) {
        [self deleteChildren:rel masterModel:model];
        id relData = [inputData objectForKey:rel.sourcePath];
        if ([relData isKindOfClass:[NSArray class]]) {
            for (NSDictionary *d in relData) {
                id relObj = [self convertAndSaveModel:rel.objectMapping.modelClass fromJSONDictionary:d];
                NSSet *origProp = [model valueForKey:rel.destinationPath];
                NSMutableSet *prop = [origProp mutableCopy];
                if (prop == nil) {
                    prop = [NSMutableSet set];
                }
                [prop addObject:relObj];
                [model setValue:prop forKeyPath:rel.destinationPath];
                [self convertAndSaveRelationships:rel.objectMapping.relationships withData:d model:relObj];
            }
        } else if ([relData isKindOfClass:[NSDictionary class]]) {
            id relObj = [self convertAndSaveModel:rel.objectMapping.modelClass fromJSONDictionary:relData];
            [model setValue:relObj forKeyPath:rel.destinationPath];
            [self convertAndSaveRelationships:rel.objectMapping.relationships withData:relData model:relObj];
        }
    }
}

- (id)convertAndSave:(id)inputData error:(NSError **)error {
    error = nil;
    ALTObjectMapping *mapping = [self objectMapping];
    id startData = inputData;
    if (mapping.sourcePath != nil) {
        startData = [inputData objectForKey:mapping.sourcePath];
    }
    
    if ([startData isKindOfClass:[NSDictionary class]]) {
        id obj = [self convertAndSaveModel:mapping.modelClass fromJSONDictionary:startData];
        NSAssert(obj, @"Conversion from JSON to model %@ failed", NSStringFromClass(mapping.modelClass));
        [self convertAndSaveRelationships:mapping.relationships withData:startData model:obj];
        return obj;
    } else if ([startData isKindOfClass:[NSArray class]]) {
        NSMutableArray *arr = [NSMutableArray array];
        for (NSDictionary *d in startData) {
            id obj = [self convertAndSaveModel:mapping.modelClass fromJSONDictionary:d];
            [self convertAndSaveRelationships:mapping.relationships withData:d model:obj];
            [arr addObject:obj];
        }
        return arr;
    } else if ([startData isKindOfClass:[NSNull class]]) {
        return nil;
    } else {
        NSAssert(NO, @"Unrecognized class for JSON response");
    }
    return nil;
}

- (PMKPromise *)saveToDb:(NSDictionary *)responseObject {
    return [PMKPromise new:^(PMKPromiseFulfiller fulfiller, PMKPromiseRejecter rejecter) {
        NSError *error = nil;
        id obj = [self convertAndSave:responseObject error:&error];
        if (error != nil) {
            rejecter(error);
        }
        fulfiller(obj);
    }];
}
 */

- (PMKPromise *)mapObjects:(NSDictionary *)responseObject
{
    return [PMKPromise new:^(PMKPromiseFulfiller fulfiller, PMKPromiseRejecter rejecter) {
        //ALTObjectMapping *testMapping = [ALTObjectMapping mappingForModel:ALTGenericResponse.class sourcePath:nil];
        _objectMappings = [NSArray arrayWithObjects:self.objectMapping, /*testMapping,*/ nil];
        ALTObjectMapper *mapper = [[ALTObjectMapper alloc] init];
        [mapper mapDictionary:responseObject withMappings:self.objectMappings inDatabase:self.database].then(^(id result) {
            fulfiller(result);
        });
    }];
}

- (NSString *)loadFromDbCache:(MTLModel *)request additionalId:(NSString *)additionalId cacheKey:(NSString *)cacheKey
{
    if (additionalId == nil) {
        additionalId = @"";
    }
    NSString *stmt = @"select * from cache where endpoint = ? and additionalid = ? and cachekey = ?";
    NSArray *params = @[self.endPoint, additionalId, cacheKey];
    NSArray *res = [_database rawQuerySync:stmt parameters:params];
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
    [_database rawQuerySync:deleteStmt parameters:deleteParams];
    
    
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
    [_database rawQuerySync:stmt parameters:params];
}

- (NSDictionary *)manageCache:(NSDictionary *)responseObject
{
    NSDictionary *res = responseObject;
    if (responseObject != nil) {
        BOOL valid = [[responseObject objectForKey:@"IsValidLocalCache"] boolValue];
        NSString *cacheKey = [responseObject objectForKey:@"CacheKey"];
        if (valid) {
            NSString *data = [self loadFromDbCache:_request additionalId:_additionalId cacheKey:cacheKey];
            if (data == nil) {
                return res;
            }
            NSError *error = nil;
            res = [NSJSONSerialization JSONObjectWithData:[data dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
            if (res == nil) {
                @throw @"Error converting JSON string to data";
            }
        } else {
            [self saveToDbCache:_request response:responseObject additionalId:_additionalId cacheKey:cacheKey];
        }
    }
    return res;
}

- (PMKPromise *)downloadDataFromWS {
    return [PMKPromise new:^(PMKPromiseFulfiller fulfiller, PMKPromiseRejecter rejecter) {
        self.callWS.then(^(id responseObject, AFHTTPRequestOperation *operation) {
            responseObject = [self manageCache:responseObject];
            if (self.deleteOrphanedObjects) {
                [self deleteOrphans].then(^() {
                    return responseObject;
                });
            }
            return responseObject;
        }).then(^(id responseObject) {
            return [self mapObjects:responseObject];
        }).then(^(id mappingResult) {
            [self fetchObjectsFromDb].then(^(id res) {
                fulfiller(PMKManifold(mappingResult, res));
                //fulfiller(res);
            });
        }).catch(^(NSError *error) {
            rejecter(error);
        });
    }];
}

- (PMKPromise *)callWS {
    return [PMKPromise new:^(PMKPromiseFulfiller fulfiller, PMKPromiseRejecter rejecter) {
        NSLog(@"API: %@", self.endPoint);
        NSDictionary *serializedRequest = [MTLJSONAdapter JSONDictionaryFromModel:self.request];
        NSLog(@"Serialized request: %@", serializedRequest);
        [self.manager POST:self.endPoint parameters:serializedRequest success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"Request completed: %@", operation.request.description);
            NSLog(@"Response: %@", responseObject);
            fulfiller(PMKManifold(responseObject, operation));
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Request: %@", operation.request);
            NSLog(@"Request params: %@", serializedRequest);
            NSLog(@"Error: %@", error);
            rejecter(error);
        }];
        
    }];
}


@end
