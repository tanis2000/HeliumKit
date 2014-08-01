//
//  ALTUser.m
//  HeliumKit
//
//  Created by Valerio Santinelli on 28/07/14.
//  Copyright (c) 2014 Valerio Santinelli. All rights reserved.
//

#import "ALTUser.h"

@implementation ALTUser

+(NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{
             @"userId": @"id",
             @"name": @"name",
             @"email": @"email",
             };
}

+(NSDictionary *)FMDBColumnsByPropertyKey {
    return @{
             @"userId": @"userId",
             @"name": @"name",
             @"email": @"email",
             };
}

+(NSArray *)FMDBPrimaryKeys {
    return @[@"userId"];
}

+(NSString *)FMDBTableName {
    return @"user";
}
@end
