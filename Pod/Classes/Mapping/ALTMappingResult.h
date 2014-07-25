//
//  ALTMappingResult.h
//  HeliumKit
//
//  Created by Valerio Santinelli on 18/07/14.
//  Copyright (c) 2014 Altralogica s.r.l. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ALTMappingResult : NSObject

- (instancetype)initWithDictionary:(NSDictionary *)objects;

- (NSDictionary *)dictionary;
@end
