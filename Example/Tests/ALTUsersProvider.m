//
//  ALTUsersProvider.m
//  HeliumKit
//
//  Created by Valerio Santinelli on 28/07/14.
//  Copyright (c) 2014 Valerio Santinelli. All rights reserved.
//

#import "ALTUsersProvider.h"
#import "ALTUser.h"
#import <HeliumKit/ALTObjectMapping.h>

@implementation ALTUsersProvider

- (NSString *)endPoint {
    return [NSString stringWithFormat:@"%@%@", self.baseURL, @"users"];
}

- (PMKPromise *)fetchObjectsFromDb {
    return [PMKPromise new:^(PMKPromiseFulfiller fulfiller, PMKPromiseRejecter rejecter) {
        if (!self.skipDatabase) {
            [self.database fetch:@"user" returnClass:ALTUser.class].then(^(id res) {
                fulfiller(res);
            });
        } else {
            fulfiller(nil);
        }
    }];
}

- (NSArray *)objectMappings {
    ALTObjectMapping *mapping = [ALTObjectMapping mappingForModel:ALTUser.class sourcePath:nil];
    
    return @[mapping];
}

@end
