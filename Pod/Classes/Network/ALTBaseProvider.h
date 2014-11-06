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

/**
 The end point of the remote service we are calling
 
 @return an NSString containing the end pint of the remote service
 */
- (NSString *)endPoint;

/**
 Performs a SQL query on the database to retrieve the instances of the model of this provider. This can actually retrieve anything from SQLite and return an NSArray of models. This is usually used to return data after the remote service has been consumed and the data consolidated in the database. It can also be used to retrieve cached data before invoking the remote service.
 
 @return an NSArray of models
 */
- (PMKPromise *)fetchObjectsFromDb;

/**
 The actual mappings of the remote service.
 
 @return an NSArray of `ALTObjectMapping`
 */
- (NSArray *)objectMappings;

/**
 Override this method to preprocess the response from AFNetworking. As an example, you can use this to check for specific HTTP return codes or to manage cached responses on the database. We provide an example of the lattest in the test cases. You can also use this to delete orphaned objects.
 
 @param response the response as returned by AFNetworking
 
 @return the response modified by your code (or you can return the original response which is the default behavior)
 */
- (id)preProcessResult:(id)response;

@end

@interface ALTBaseProvider : NSObject<ALTBaseProviderDelegate>

/**
 The database controller that manages the queue where all fo the SQL statements are being executed
 */
@property(nonatomic, readonly) ALTDatabaseController *database;

/**
 The AFNetworking `AFHTTPRequestOperationManager` used by this class to perform all of the remote requests.
 */
@property(nonatomic, readonly) AFHTTPRequestOperationManager *manager;

/**
 The last AFNetworking `AFHTTPRequestOperation` that has been enqueued for processing. This can be used to cancel the operation.
 */
@property(nonatomic, readonly) AFHTTPRequestOperation *lastOperation;

/**
 The base URL of the service being called
 */
@property(nonatomic, strong, readonly) NSString *baseURL;

/**
 The model of the request being serialized by AFNetworking when calling the remote end point.
 */
@property(nonatomic, copy) MTLModel<MTLJSONSerializing> *request;

/**
 If YES, nothing will be written to SQLite. Objects will be parsed and their model representations will be available through `fetchData`. Default is NO.
 */
@property(nonatomic) BOOL skipDatabase;

/**
 Initialize the provider
 
 @param database an `ALTDatabaseController` instance used to perform all of the operations on the database
 @param manager  an `AFHTTPRequestOperationManager` instance used to perform all of the remote calls
 @param baseURL  an NSString with the base URL of the remote service
 
 @return an instance of `ALTBaseProvider`
 */
-(instancetype)initWithDatabaseController:(ALTDatabaseController *)database
               andRequestOperationManager:(AFHTTPRequestOperationManager *)manager
                               andBaseURL:(NSString *)baseURL;

/**
 Call the remote end point, retrieve the data, save it to the database and pass it over to the caller.
 
 The actual flow is the following (and can be overridden):
 
 1. start a request for the remote end point
 2. looks for the data in the database and returns a cached version if available
 3. once remote end point has finished transferring data, we pre-process it and hand it over to the caller
 4. the processed data is also being saved to the database
 5. the saved models are being fetched back from the database and handled back to the caller. 
 
 What happens is that 3 kind of data are made available to the caller in an async fashion using promises. 
 The first dataset is the cached data stored in the database before the call to the remote end point. It's possible to skip this step by setting self.skipDatabase to YES.
 The second dataset is the actual data returned by the remote end point. That data is only preprocessed and converted to the respective models, following relationships between the models, but they're still just in memory representation of the received data.
 The third dataset is the model actually fetched from the database after the preprocessed data has been saved to SQLite.
 
 @param method an `ALTHTTPMethod` for the kind of HTTP method to use (GET, POST, etc...)
 
 @return an instance of PMKPromise.
 */
- (PMKPromise *)fetchData:(ALTHTTPMethod)method;


@end
