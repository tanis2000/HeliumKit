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
- (PMKPromise *)fetchObjectsFromDb;
- (NSArray *)objectMappings;

/**
 Override this method to preprocess the response from AFNetworking. As an example, you can use this to check for specific HTTP return codes or to manage cached responses on the database. We provide an example of the lattest in the test cases. You can also use this to delete orphaned objects.
 
 @param response the response as returned by AFNetworking
 
 @return the response modified by your code (or you can return the original response which is the default behavior)
 */
- (id)preProcessResult:(id)response;

@end

@interface ALTBaseProvider : NSObject<ALTBaseProviderDelegate>

@property(nonatomic, readonly) ALTDatabaseController *database;
@property(nonatomic, readonly) AFHTTPRequestOperationManager *manager;
@property(nonatomic, strong, readonly) NSString *baseURL;
//@property(nonatomic, readonly) NSArray *objectMappings;

@property(nonatomic) BOOL deleteOrphanedObjects;
@property(nonatomic, copy) MTLModel<MTLJSONSerializing> *request;

/**
 If YES, nothing will be written to SQLite. Objects will be parsed and their model representations will be available through `fetchData`. Default is NO.
 */
@property(nonatomic) BOOL skipDatabase;

-(instancetype)initWithDatabaseController:(ALTDatabaseController *)database
               andRequestOperationManager:(AFHTTPRequestOperationManager *)manager
                               andBaseURL:(NSString *)baseURL;

- (PMKPromise *)fetchData:(ALTHTTPMethod)method;
- (PMKPromise *)callWS:(ALTHTTPMethod)method;
- (PMKPromise *)mapObjects:(NSDictionary *)responseObject;
@end
