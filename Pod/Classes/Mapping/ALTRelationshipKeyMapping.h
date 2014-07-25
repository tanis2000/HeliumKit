//
//  ALTRelationshipKeyMapping.h
//  HeliumKit
//
//  Created by Valerio Santinelli on 17/07/14.
//  Copyright (c) 2014 Altralogica s.r.l. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ALTRelationshipKeyMapping : NSObject

@property (nonatomic, strong, readonly) NSString *masterKey;
@property (nonatomic, strong, readonly) NSString *detailKey;

+(instancetype)keyWithMasterKey:(NSString *)masterKey detailKey:(NSString *)detailKey;

@end
