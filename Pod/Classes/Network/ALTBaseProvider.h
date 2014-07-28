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

typedef NS_ENUM(NSUInteger, ALTHTTPMethod) {
    ALTHTTPMethodGET = 0,
    ALTHTTPMethodPOST = 1,
    ALTHTTPMethodHEAD = 2,
    ALTHTTPMethodPUT = 3,
    ALTHTTPMethodPATCH = 4,
    ALTHTTPMethodDELETE = 5,
};

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

- (PMKPromise *)fetchData:(ALTHTTPMethod)method;
- (PMKPromise *)callWS:(ALTHTTPMethod)method;
- (PMKPromise *)mapObjects:(NSDictionary *)responseObject;
@end
