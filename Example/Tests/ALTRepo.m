//
//  ALTUser.m
//  HeliumKit
//
//  Created by Valerio Santinelli on 28/07/14.
//  Copyright (c) 2014 Valerio Santinelli. All rights reserved.
//

#import "ALTRepo.h"

@implementation ALTRepo

+(NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{
             @"repoId": @"id",
             @"userId": @"user_id",
             @"url": @"url",
             };
}

+(NSDictionary *)FMDBColumnsByPropertyKey {
    return @{
             @"repoId": @"id",
             @"userId": @"userId",
             @"url": @"url",
             };
}

+(NSArray *)FMDBPrimaryKeys {
    return @[@"id"];
}

+(NSString *)FMDBTableName {
    return @"repository";
}
@end
