//
//  ALTCachedUsersProvider.m
//  HeliumKit
//
//  Created by Valerio Santinelli on 28/07/14.
//  Copyright (c) 2014 Valerio Santinelli. All rights reserved.
//

#import "ALTCachedUsersProvider.h"
#import "ALTUser.h"
#import <HeliumKit/ALTObjectMapping.h>
#import "ALTCachedResponse.h"

@implementation ALTCachedUsersProvider

- (NSString *)endPoint {
    return [NSString stringWithFormat:@"%@%@", self.baseURL, @"cachedusers"];
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
    ALTObjectMapping *envMapping = [ALTObjectMapping mappingForModel:ALTCachedResponse.class sourcePath:nil];
    ALTObjectMapping *userMapping = [ALTObjectMapping mappingForModel:ALTUser.class sourcePath:@"OutputList"];
    
    return @[envMapping, userMapping];
}

@end
