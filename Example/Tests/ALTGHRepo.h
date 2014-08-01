//
//  ALTUser.h
//  HeliumKit
//
//  Created by Valerio Santinelli on 28/07/14.
//  Copyright (c) 2014 Valerio Santinelli. All rights reserved.
//

#import "MTLModel.h"
#import <Mantle/MTLJSONAdapter.h>
#import <MTLFMDBAdapter/MTLFMDBAdapter.h>

@interface ALTGHRepo : MTLModel<MTLJSONSerializing, MTLFMDBSerializing>

@property (nonatomic, copy) NSNumber *repoId;
@property (nonatomic, copy) NSString *repoName;
@property (nonatomic, copy) NSString *repoUrl;

@end
