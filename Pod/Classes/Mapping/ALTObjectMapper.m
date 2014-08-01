//
//  ALTObjectMapper.m
//  HeliumKit
//
//  Created by Valerio Santinelli on 18/07/14.
//  Copyright (c) 2014 Altralogica s.r.l. All rights reserved.
//

#import <Mantle/Mantle.h>
#import "ALTObjectMapper.h"
#import "ALTRelationshipMapping.h"
#import "ALTObjectMapping.h"
#import "MTLFMDBAdapter.h"
#import "ALTDatabaseController.h"
#import "ALTRelationshipKeyMapping.h"
#import "ALTMappingResult.h"

@implementation ALTObjectMapper

- (PMKPromise *) mapDictionary:(NSDictionary *)sourceDict withMappings:(NSArray *)mappings inDatabase:(ALTDatabaseController *)database {
    return [PMKPromise new:^(PMKPromiseFulfiller fulfiller, PMKPromiseRejecter rejecter) {
        self.database = database;
        NSMutableDictionary *container = [NSMutableDictionary dictionary];
        NSMutableArray *promises = [NSMutableArray array];
        for (ALTObjectMapping *mapping in mappings) {
            id promise = [self saveToDb:sourceDict mapping:mapping];
            [promises addObject:promise];
        }
        [PMKPromise when:promises].then(^(NSArray *res) {
            int i = 0;
            for (id result in res) {
                ALTObjectMapping *mapping = [mappings objectAtIndex:i];
                id sourcePath = mapping.modelClass;
                if (sourcePath == nil) {
                    sourcePath = [NSNull null];
                }
                [container setObject:result forKey:sourcePath];
                i++;
            }
            fulfiller([[ALTMappingResult alloc] initWithDictionary:container]);
        });
    }];
}

- (PMKPromise *)saveModel:(id)model {
    return [PMKPromise new:^(PMKPromiseFulfiller fulfiller, PMKPromiseRejecter rejecter) {
        [self.database runDatabaseBlockInTransaction:^(FMDatabase *database, BOOL *rollback) {
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
    [self.database runDatabaseBlockInTransaction:^(FMDatabase *database, BOOL *rollback) {
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
    if ([obj conformsToProtocol:@protocol(MTLFMDBSerializing)] && self.database != nil) {
        [self saveModel:obj];
    }
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

- (id)convertAndSave:(id)inputData mapping:(ALTObjectMapping *)mapping error:(NSError **)error {
    error = nil;
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

- (PMKPromise *)saveToDb:(NSDictionary *)responseObject mapping:(ALTObjectMapping *)mapping {
    return [PMKPromise new:^(PMKPromiseFulfiller fulfiller, PMKPromiseRejecter rejecter) {
        NSError *error = nil;
        id obj = [self convertAndSave:responseObject mapping:mapping error:&error];
        if (error != nil) {
            rejecter(error);
        }
        fulfiller(obj);
    }];
}

@end
