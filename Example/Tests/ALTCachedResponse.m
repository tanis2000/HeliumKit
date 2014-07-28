//
//  ALTCachedResponse.m
//  HeliumKit
//
//  Created by Valerio Santinelli on 28/07/14.
//  Copyright (c) 2014 Valerio Santinelli. All rights reserved.
//

#import "ALTCachedResponse.h"

@implementation ALTCachedResponse

+(NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{
             @"cacheKey": @"CacheKey",
             @"isValid": @"IsValid",
             @"isLocalValid": @"IsLocalValid",
             };
}

@end
