//
//  ALTRelationshipMapping.m
//  HeliumKit
//
//  Created by Valerio Santinelli on 17/07/14.
//  Copyright (c) 2014 Altralogica s.r.l. All rights reserved.
//

#import "ALTRelationshipMapping.h"

@implementation ALTRelationshipMapping

+(instancetype)relationshipWithSourcePath:(NSString *)sourcePath destinationPath:(NSString *)destinationPath objectMapping:(ALTObjectMapping *)objectMapping relationshipKeys:(NSArray *)relationshipKeys {
    ALTRelationshipMapping *rel = [[self alloc] initWithSourcePath:sourcePath destinationPath:destinationPath objectMapping:objectMapping relationshipKeys:relationshipKeys];
    return rel;
}

+(instancetype)relationshipWithSourcePath:(NSString *)sourcePath destinationPath:(NSString *)destinationPath objectMapping:(ALTObjectMapping *)objectMapping {
    ALTRelationshipMapping *rel = [[self alloc] initWithSourcePath:sourcePath destinationPath:destinationPath objectMapping:objectMapping];
    return rel;
}

- (instancetype)initWithSourcePath:(NSString *)sourcePath destinationPath:(NSString *)destinationPath objectMapping:(ALTObjectMapping *)objectMapping
{
    self = [self initWithSourcePath:sourcePath destinationPath:destinationPath objectMapping:objectMapping relationshipKeys:nil];
    return self;
}

- (instancetype)initWithSourcePath:(NSString *)sourcePath destinationPath:(NSString *)destinationPath objectMapping:(ALTObjectMapping *)objectMapping relationshipKeys:(NSArray *)relationshipKeys
{
    self = [super init];
    if (self) {
        _sourcePath = sourcePath;
        _destinationPath = destinationPath;
        _objectMapping = objectMapping;
        _relationshipKeys = relationshipKeys;
    }
    return self;
}

@end
