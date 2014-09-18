//
//  ALTBaseProvider.m
//  HeliumKit
//
//  Created by Valerio Santinelli on 15/07/14.
//  Copyright (c) 2014 Altralogica s.r.l. All rights reserved.
//

#import "ALTBaseProvider.h"
#import "MTLFMDBAdapter.h"
#import "ALTObjectMapping.h"
#import "ALTRelationshipMapping.h"
#import "ALTRelationshipKeyMapping.h"
#import "ALTObjectMapper.h"

@interface ALTBaseProvider()

- (PMKPromise *)callWS:(ALTHTTPMethod)method;
- (PMKPromise *)mapObjects:(NSDictionary *)responseObject;

@end

@implementation ALTBaseProvider

- (instancetype)initWithDatabaseController:(ALTDatabaseController *)database
                andRequestOperationManager:(AFHTTPRequestOperationManager *)manager
                                andBaseURL:(NSString *)baseURL
{
    self = [super init];
    if (self) {
        _database = database;
        _manager = manager;
        _baseURL = baseURL;
    }
    return self;
}

- (NSString *)endPoint {
    NSAssert(NO, @"endPoint should be ovrridden");
    return @"";
}

- (PMKPromise *)fetchObjectsFromDb {
    NSAssert(NO, @"fetchObjectsFromDb has not been implemented. You can ignore this if you're using the response from the response mapper instead of the one from the database");
    return nil;
}

- (PMKPromise *)fetchData:(ALTHTTPMethod)method {
    return [PMKPromise new:^(PMKPromiseFulfiller fulfiller, PMKPromiseRejecter rejecter) {
        id fresh = [self downloadDataFromWS:method];
        if (_skipDatabase) {
            fulfiller(PMKManifold([NSNull null], fresh));
        } else {
            [self fetchObjectsFromDb].then(^(id cached) {
                fulfiller(PMKManifold(cached, fresh));
            });
        }
    }];
}

- (id)preProcessResult:(id)response
{
    return response;
}

- (NSArray *) objectMappings {
    NSAssert(NO, @"objectMappings should be overridden");
    return @[];
}

- (PMKPromise *)mapObjects:(NSDictionary *)responseObject
{
    return [PMKPromise new:^(PMKPromiseFulfiller fulfiller, PMKPromiseRejecter rejecter) {
        //ALTObjectMapping *testMapping = [ALTObjectMapping mappingForModel:ALTGenericResponse.class sourcePath:nil];
        //_objectMappings = [NSArray arrayWithObjects:self.objectMapping, /*testMapping,*/ nil];
        ALTObjectMapper *mapper = [[ALTObjectMapper alloc] init];
        ALTDatabaseController *db = self.database;
        if (_skipDatabase) {
            db = nil;
        }
        [mapper mapDictionary:responseObject withMappings:self.objectMappings inDatabase:db].then(^(id result) {
            fulfiller(result);
        });
    }];
}

- (PMKPromise *)downloadDataFromWS:(ALTHTTPMethod)method {
    return [PMKPromise new:^(PMKPromiseFulfiller fulfiller, PMKPromiseRejecter rejecter) {
        [self callWS:method].then(^(id responseObject, AFHTTPRequestOperation *operation) {
            return [self preProcessResult:responseObject];
        }).then(^(id responseObject) {
            return [self mapObjects:responseObject];
        }).then(^(id mappingResult) {
            if (_skipDatabase) {
                fulfiller(mappingResult);
            } else {
                [self fetchObjectsFromDb].then(^(id res) {
                    fulfiller(PMKManifold(mappingResult, res));
                });
            }
        }).catch(^(NSError *error) {
            rejecter(error);
        });
    }];
}

- (NSString *)requestType:(ALTHTTPMethod)method {
    if (method == ALTHTTPMethodGET) {
        return @"GET";
    } else if (method == ALTHTTPMethodPOST) {
        return @"POST";
    } else if (method == ALTHTTPMethodHEAD) {
        return @"HEAD";
    } else if (method == ALTHTTPMethodPUT) {
        return @"PUT";
    } else if (method == ALTHTTPMethodPATCH) {
        return @"PATCH";
    } else if (method == ALTHTTPMethodDELETE) {
        return @"DELETE";
    } else {
        @throw @"HTTP method not supported";
    }
}

- (PMKPromise *)callWS:(ALTHTTPMethod)method {
    return [PMKPromise new:^(PMKPromiseFulfiller fulfiller, PMKPromiseRejecter rejecter) {
        NSLog(@"API: %@", self.endPoint);
        NSDictionary *serializedRequest = [MTLJSONAdapter JSONDictionaryFromModel:self.request];
        NSLog(@"Serialized request: %@", serializedRequest);
        NSMutableURLRequest *request = [self.manager.requestSerializer requestWithMethod:[self requestType:method] URLString:[[NSURL URLWithString:self.endPoint relativeToURL:self.manager.baseURL] absoluteString] parameters:serializedRequest error:nil];
        AFHTTPRequestOperation *operation = [self.manager HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"Request completed: %@", operation.request.description);
            NSLog(@"Response: %@", responseObject);
            fulfiller(PMKManifold(responseObject, operation));
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Request: %@", operation.request);
            NSLog(@"Request params: %@", serializedRequest);
            NSLog(@"Error: %@", error);
            rejecter(error);
        }];
        
        _lastOperation = operation;
        [self.manager.operationQueue addOperation:operation];
    }];
}


@end
