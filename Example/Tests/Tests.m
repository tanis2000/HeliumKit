//
//  HeliumKitTests.m
//  HeliumKitTests
//
//  Created by Valerio Santinelli on 07/25/2014.
//  Copyright (c) 2014 Valerio Santinelli. All rights reserved.
//

#import <HeliumKit/ALTDatabaseController.h>
#import <HeliumKit/ALTMappingResult.h>
#import <AFNetworking/AFNetworking.h>
#import "ALTUser.h"
#import "ALTUsersProvider.h"
#import "ALTBaseRequest.h"

ALTDatabaseController *_database;
AFHTTPRequestOperationManager *_manager;

SpecBegin(InitialSpecs)

describe(@"main tests", ^{
    beforeEach(^{
        _manager = [AFHTTPRequestOperationManager manager];
        _manager.responseSerializer = [AFJSONResponseSerializer serializer];
        _manager.requestSerializer = [AFJSONRequestSerializer serializer];
        [_manager.requestSerializer setValue:@"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/32.0.1700.102 Safari/537.36" forHTTPHeaderField:@"User-Agent"];
        [_manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [_manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];
        
        // Grab the Documents folder
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        
        // Sets the database filename
        NSString *filePath = [documentsDirectory stringByAppendingPathComponent:@"Test.sqlite"];
        
        _database = [[ALTDatabaseController alloc] initWithDatabasePath:filePath
                                                          creationBlock:^(FMDatabase *db, BOOL *rollback) {
                                                              [db executeUpdate:@"create table if not exists user "
                                                               "(userId text unique, name text, email text)"];
                                                          }];
        
    });

    afterEach(^{
        [_database runDatabaseBlockInTransaction:^(FMDatabase *database, BOOL *rollback) {
            [database executeUpdate:@"drop table if exists user"];
        }];
    });

    it(@"can store json into db", ^AsyncBlock {
        ALTUsersProvider *provider = [[ALTUsersProvider alloc] initWithDatabaseController:_database andRequestOperationManager:_manager andBaseURL:@"http://localhost:4567/"];
        ALTBaseRequest *request = [[ALTBaseRequest alloc] init];
        provider.request = request;
        [provider fetchData:ALTHTTPMethodGET].then(^(NSArray *cachedData, PMKPromise *freshData) {
            // cachedData contains data already in the db
            return freshData;
        }).then(^(id mappingResult, NSArray *freshData) {
            NSLog(@"%@", freshData);
            expect(freshData).to.beKindOf(NSArray.class);
            expect(freshData).to.haveCountOf(2);
            ALTUser *secondUser = freshData[1];
            expect(secondUser.name).to.equal(@"Steve Jobs");
            done();
        }).catch(^(NSError *error) {
            NSLog(@"Failed with error: %@", [error localizedDescription]);
            done();
        });

    });
    
    it(@"can store and retrieve a class from the database", ^AsyncBlock {
        [_database runDatabaseBlockInTransaction:^(FMDatabase *database, BOOL *rollback) {
            [database executeUpdate:@"insert into user (userid, name, email) values (?, ?, ?)" withArgumentsInArray:@[[NSNumber numberWithInt:999], @"Valerio Santinelli", @"email@provider.com"]];
            *rollback = NO;
        }].then(^(id res) {
            NSLog(@"%@", res);
            id res2 = [_database runFetchForClass:ALTUser.class fetchBlock:^FMResultSet *(FMDatabase *database) {
                return [database executeQuery:@"select * from user where userId = 999"];
            }];
            return res2;
        }).then(^(NSArray *res){
            NSLog(@"%@", res);
            expect(res).toNot.beNil();
            expect(res).to.haveCountOf(1);
            if (res != nil && res.count > 0) {
                ALTUser *user = res[0];
                expect(user).to.notTo.beNil();
                expect(user.name).to.equal(@"Valerio Santinelli");
            }
            done();
        });;
    });
    
    it(@"can load json with the POST method", ^AsyncBlock {
        ALTUsersProvider *provider = [[ALTUsersProvider alloc] initWithDatabaseController:_database andRequestOperationManager:_manager andBaseURL:@"http://localhost:4567/"];
        ALTBaseRequest *request = [[ALTBaseRequest alloc] init];
        provider.request = request;
        [provider fetchData:ALTHTTPMethodPOST].then(^(NSArray *cachedData, PMKPromise *freshData) {
            // cachedData contains data already in the db
            return freshData;
        }).then(^(id mappingResult, NSArray *freshData) {
            NSLog(@"%@", freshData);
            expect(freshData).to.beKindOf(NSArray.class);
            expect(freshData).to.haveCountOf(2);
            ALTUser *secondUser = freshData[1];
            expect(secondUser.name).to.equal(@"Steve Jobs");
            done();
        }).catch(^(NSError *error) {
            NSLog(@"Failed with error: %@", [error localizedDescription]);
            done();
        });
        
    });

    it(@"can load a json without storing it in the database", ^AsyncBlock {
        ALTUsersProvider *provider = [[ALTUsersProvider alloc] initWithDatabaseController:nil andRequestOperationManager:_manager andBaseURL:@"http://localhost:4567/"];
        ALTBaseRequest *request = [[ALTBaseRequest alloc] init];
        provider.request = request;
        provider.skipDatabase = YES;
        [provider fetchData:ALTHTTPMethodGET].then(^(NSArray *cachedData, PMKPromise *freshData) {
            // cachedData will always contain zero results as we're skipping the database calls
            return freshData;
        }).then(^(ALTMappingResult *mappingResult, NSArray *freshData) {
            NSLog(@"%@", mappingResult);
            expect(mappingResult).to.beKindOf(ALTMappingResult.class);
            NSDictionary *d = mappingResult.dictionary;
            expect(d).to.haveCountOf(1);
            NSArray *ar = [d objectForKey:ALTUser.class];
            expect(ar).to.haveCountOf(2);
            ALTUser *secondUser = ar[1];
            expect(secondUser.name).to.equal(@"Steve Jobs");
            done();
        }).catch(^(NSError *error) {
            NSLog(@"Failed with error: %@", [error localizedDescription]);
            done();
        });
        
    });

});


SpecEnd
