//
//  ALTMappingResult.m
//  HeliumKit
//
//  Created by Valerio Santinelli on 18/07/14.
//  Copyright (c) 2014 Altralogica s.r.l. All rights reserved.
//

#import "ALTMappingResult.h"

@interface ALTMappingResult ()

@property (nonatomic, strong) NSDictionary *mappedObjects;

@end

@implementation ALTMappingResult

- (instancetype)initWithDictionary:(NSDictionary *)objects
{
    self = [super init];
    if (self) {
        _mappedObjects = objects;
    }
    return self;
}

- (NSDictionary *)dictionary {
    return [_mappedObjects copy];
}
@end
