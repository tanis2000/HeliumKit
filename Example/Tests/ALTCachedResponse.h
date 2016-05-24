//
//  ALTCachedResponse.h
//  HeliumKit
//
//  Created by Valerio Santinelli on 28/07/14.
//  Copyright (c) 2014 Valerio Santinelli. All rights reserved.
//

#import "MTLModel.h"
#import <Mantle/Mantle.h>
#import <Mantle/MTLJSONAdapter.h>

@interface ALTCachedResponse : MTLModel<MTLJSONSerializing>

@property (nonatomic, copy) NSString *cacheKey;
@property (nonatomic, copy) NSNumber *isValid;
@property (nonatomic, copy) NSNumber *isLocalValid;

@end
