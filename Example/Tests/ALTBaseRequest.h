//
//  ALTBaseRequest.h
//  HeliumKit
//
//  Created by Valerio Santinelli on 28/07/14.
//  Copyright (c) 2014 Valerio Santinelli. All rights reserved.
//

#import "MTLModel.h"
#import <Mantle/MTLJSONAdapter.h>

@interface ALTBaseRequest : MTLModel<MTLJSONSerializing>

@property (nonatomic, copy) NSString *cacheKey;

@end
