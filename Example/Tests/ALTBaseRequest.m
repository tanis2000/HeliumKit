//
//  ALTBaseRequest.m
//  HeliumKit
//
//  Created by Valerio Santinelli on 28/07/14.
//  Copyright (c) 2014 Valerio Santinelli. All rights reserved.
//

#import "ALTBaseRequest.h"

@implementation ALTBaseRequest

+(NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{
             @"cacheKey": @"cacheKey",
             };
}

@end
