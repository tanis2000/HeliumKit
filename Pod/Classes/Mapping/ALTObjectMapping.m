//
//  ALTObjectMapping.m
//  HeliumKit
//
//  Created by Valerio Santinelli on 17/07/14.
//  Copyright (c) 2014 Altralogica s.r.l. All rights reserved.
//

#import "ALTObjectMapping.h"
#import "ALTRelationshipMapping.h"

@implementation ALTObjectMapping

+(instancetype)mappingForModel:(Class)modelClass
                    sourcePath:(NSString *)sourcePath
{
    ALTObjectMapping *mapping = [[self alloc] initWithModel:modelClass sourcePath:sourcePath];
    return mapping;
}

- (instancetype)initWithModel:(Class)modelClass
                   sourcePath:(NSString *)sourcePath
{
    self = [super init];
    if (self) {
        _modelClass = modelClass;
        _sourcePath = sourcePath;
        _relationships = [NSMutableArray array];
    }
    return self;
}

- (void)addRelationship:(ALTRelationshipMapping *)relationship
{
    [_relationships addObject:relationship];
}
@end
