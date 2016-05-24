//
//  ALTGHRepoProvider.m
//  HeliumKit
//
//  Created by Valerio Santinelli on 28/07/14.
//  Copyright (c) 2014 Valerio Santinelli. All rights reserved.
//

#import "ALTGHRepoProvider.h"
#import "ALTGHRepo.h"
#import <HeliumKit/ALTObjectMapping.h>
#import <HeliumKit/ALTDatabaseController.h>

@implementation ALTGHRepoProvider

- (NSString *)endPoint {
    return [NSString stringWithFormat:@"%@%@", self.baseURL, @"/users/tanis2000/repos"];
}

- (PMKPromise *)fetchObjectsFromDb {
    return [PMKPromise new:^(PMKPromiseFulfiller fulfiller, PMKPromiseRejecter rejecter) {
        if (!self.skipDatabase) {
            [self.database fetch:@"ghrepo" returnClass:ALTGHRepo.class].then(^(id res) {
                fulfiller(res);
            });
        } else {
            fulfiller(nil);
        }
    }];
}

- (NSArray *)objectMappings {
    ALTObjectMapping *mapping = [ALTObjectMapping mappingForModel:ALTGHRepo.class sourcePath:nil];
    
    return @[mapping];
}

@end
