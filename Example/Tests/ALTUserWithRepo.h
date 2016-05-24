//
//  ALTUser.h
//  HeliumKit
//
//  Created by Valerio Santinelli on 28/07/14.
//  Copyright (c) 2014 Valerio Santinelli. All rights reserved.
//

#import "MTLModel.h"
#import <Mantle/Mantle.h>
#import <Mantle/MTLJSONAdapter.h>
#import <MTLFMDBAdapter/MTLFMDBAdapter.h>

@interface ALTUserWithRepo : MTLModel<MTLJSONSerializing, MTLFMDBSerializing>

@property (nonatomic, copy) NSNumber *userId;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *email;
@property (nonatomic, copy) NSSet *repositories;

@end
