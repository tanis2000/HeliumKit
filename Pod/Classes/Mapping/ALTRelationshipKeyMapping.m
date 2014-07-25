//
//  ALTRelationshipKeyMapping.m
//  HeliumKit
//
//  Created by Valerio Santinelli on 17/07/14.
//  Copyright (c) 2014 Altralogica s.r.l. All rights reserved.
//

#import "ALTRelationshipKeyMapping.h"

@implementation ALTRelationshipKeyMapping

+(instancetype)keyWithMasterKey:(NSString *)masterKey detailKey:(NSString *)detailKey
{
    ALTRelationshipKeyMapping *rel = [[self alloc] initWithMasterKey:masterKey detailKey:detailKey];
    return rel;
}

- (instancetype)initWithMasterKey:(NSString *)masterKey detailKey:(NSString *)detailKey
{
    self = [super init];
    if (self) {
        _masterKey = masterKey;
        _detailKey = detailKey;
    }
    return self;
}

@end
