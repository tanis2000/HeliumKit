//
//  ALTObjectMapper.h
//  HeliumKit
//
//  Created by Valerio Santinelli on 18/07/14.
//  Copyright (c) 2014 Altralogica s.r.l. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <PromiseKit/PromiseKit.h>

@class ALTMappingResult;
@class ALTDatabaseController;

@interface ALTObjectMapper : NSObject

@property (nonatomic, weak) ALTDatabaseController *database;

-(PMKPromise *)mapDictionary:(NSDictionary *)sourceDict withMappings:(NSArray *)mappings inDatabase:(ALTDatabaseController *)database;

@end
