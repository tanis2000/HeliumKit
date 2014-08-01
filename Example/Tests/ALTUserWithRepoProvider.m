//
//  ALTUsersProvider.m
//  HeliumKit
//
//  Created by Valerio Santinelli on 28/07/14.
//  Copyright (c) 2014 Valerio Santinelli. All rights reserved.
//

#import "ALTUserWithRepoProvider.h"
#import "ALTUserWithRepo.h"
#import "ALTRepo.h"
#import <HeliumKit/ALTObjectMapping.h>
#import <HeliumKit/ALTRelationshipMapping.h>
#import <HeliumKit/ALTRelationshipKeyMapping.h>

@implementation ALTUserWithRepoProvider

- (NSString *)endPoint {
    return [NSString stringWithFormat:@"%@%@", self.baseURL, @"userswithrepo"];
}

- (PMKPromise *)fetchObjectsFromDb {
    return [PMKPromise new:^(PMKPromiseFulfiller fulfiller, PMKPromiseRejecter rejecter) {
        if (!self.skipDatabase) {
            [self.database fetch:@"user" returnClass:ALTUserWithRepo.class].then(^(id res) {
                fulfiller(res);
            });
        } else {
            fulfiller(nil);
        }
    }];
}

- (NSArray *)objectMappings {
    ALTObjectMapping *mapping = [ALTObjectMapping mappingForModel:ALTUserWithRepo.class sourcePath:nil];
    ALTObjectMapping *repoMapping = [ALTObjectMapping mappingForModel:ALTRepo.class sourcePath:nil];
    
    ALTRelationshipKeyMapping *repoKey = [ALTRelationshipKeyMapping keyWithMasterKey:@"userId" detailKey:@"userId"];

    [mapping addRelationship:[ALTRelationshipMapping relationshipWithSourcePath:@"repo" destinationPath:@"repositories" objectMapping:repoMapping relationshipKeys:@[repoKey]]];

    return @[mapping];
}

@end
