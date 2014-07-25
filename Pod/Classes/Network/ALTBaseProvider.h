//
//  ALTBaseProvider.h
//  HeliumKit
//
//  Created by Valerio Santinelli on 15/07/14.
//  Copyright (c) 2014 Altralogica s.r.l. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Mantle/Mantle.h>
#import <AFNetworking/AFNetworking.h>
#import "ALTDatabaseController.h"

@class ALTObjectMapping;

@protocol ALTBaseProviderDelegate <NSObject>

@required
- (NSString *)endPoint;
//- (PMKPromise *)saveModel:(id)model;
- (PMKPromise *)fetchObjectsFromDb;
- (ALTObjectMapping *)objectMapping;

@optional
- (PMKPromise *)deleteOrphans;

@end

@interface ALTBaseProvider : NSObject<ALTBaseProviderDelegate>

@property(nonatomic, readonly) ALTDatabaseController *database;
@property(nonatomic, readonly) AFHTTPRequestOperationManager *manager;
@property(nonatomic, strong, readonly) NSString *baseURL;
@property(nonatomic, readonly) NSArray *objectMappings;

@property(nonatomic) BOOL deleteOrphanedObjects;
@property(nonatomic, copy) MTLModel<MTLJSONSerializing> *request;
@property(nonatomic, copy) NSString *additionalId;

-(instancetype)initWithDatabaseController:(ALTDatabaseController *)database
               andRequestOperationManager:(AFHTTPRequestOperationManager *)manager
                               andBaseURL:(NSString *)baseURL;

- (PMKPromise *)fetchData;
- (PMKPromise *)callWS;
- (PMKPromise *)mapObjects:(NSDictionary *)responseObject;
@end
