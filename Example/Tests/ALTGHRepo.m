//
//  ALTGHRepo.m
//  HeliumKit
//
//  Created by Valerio Santinelli on 28/07/14.
//  Copyright (c) 2014 Valerio Santinelli. All rights reserved.
//

#import "ALTGHRepo.h"

@implementation ALTGHRepo

+(NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{
             @"repoId": @"id",
             @"repoName": @"name",
             @"repoUrl": @"url",
             };
}

+(NSDictionary *)FMDBColumnsByPropertyKey {
    return @{
             @"repoId": @"id",
             @"repoName": @"name",
             @"repoUrl": @"url",
             };
}

+(NSArray *)FMDBPrimaryKeys {
    return @[@"id"];
}

+(NSString *)FMDBTableName {
    return @"ghrepo";
}
@end
