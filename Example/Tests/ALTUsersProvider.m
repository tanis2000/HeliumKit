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
        [self.database fetch:@"user" returnClass:self.objectMapping.modelClass].then(^(id res) {
            fulfiller(res);
        });
    }];
}

- (ALTObjectMapping *)objectMapping {
    ALTObjectMapping *mapping = [ALTObjectMapping mappingForModel:ALTUser.class sourcePath:nil];
    
    return mapping;
}

@end