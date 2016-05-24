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
#import "ALTCachedUsersProvider.h"
#import "ALTUserWithRepo.h"
#import "ALTRepo.h"
#import "ALTUserWithRepoProvider.h"
#import "ALTGHRepo.h"
#import "ALTGHRepoProvider.h"

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
                                                               "(pk integer primary key , userId text unique, name text, email text)"];
                                                              [db executeUpdate:@"create table if not exists repository "
                                                               "(id text unique, userId text, url text)"];
                                                          }];
        
    });

    afterEach(^{
        [_database runDatabaseBlockInTransaction:^(FMDatabase *database, BOOL *rollback) {
            [database executeUpdate:@"drop table if exists user"];
            [database executeUpdate:@"drop table if exists repository"];
        }];
    });

    it(@"can store json into db", ^ {
        waitUntil(^(DoneCallback done) {
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
            expect(error).to.beNil();
            done();
        });
        });

    });
    
    it(@"can store and retrieve a class from the database", ^ {
        waitUntil(^(DoneCallback done) {
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
        });
        });
    });
    
    it(@"can load json with the POST method", ^ {
        waitUntil(^(DoneCallback done) {
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
            expect(error).to.beNil();
            done();
        });
        });
    });

    it(@"can load a json without storing it in the database", ^ {
        waitUntil(^(DoneCallback done) {
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
            expect(error).to.beNil();
            done();
        });
        });
    });
    
    
    it(@"can store a json into db and cache the next request", ^ {
        waitUntil(^(DoneCallback done) {
        ALTCachedUsersProvider *provider = [[ALTCachedUsersProvider alloc] initWithDatabaseController:_database andRequestOperationManager:_manager andBaseURL:@"http://localhost:4567/"];
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
        }).then(^{
            request.cacheKey = @"CACHE1234";
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
        }).catch(^(NSError *error) {
            NSLog(@"Failed with error: %@", [error localizedDescription]);
            expect(error).to.beNil();
            done();
        });
        });
    });
    
    it(@"can store related json data into db", ^ {
        waitUntil(^(DoneCallback done) {
        ALTUserWithRepoProvider *provider = [[ALTUserWithRepoProvider alloc] initWithDatabaseController:_database andRequestOperationManager:_manager andBaseURL:@"http://localhost:4567/"];
        ALTBaseRequest *request = [[ALTBaseRequest alloc] init];
        provider.request = request;
        [provider fetchData:ALTHTTPMethodGET].then(^(NSArray *cachedData, PMKPromise *freshData) {
            // cachedData contains data already in the db
            return freshData;
        }).then(^(id mappingResult, NSArray *freshData) {
            NSLog(@"%@", freshData);
            expect(freshData).to.beKindOf(NSArray.class);
            expect(freshData).to.haveCountOf(2);
            ALTUserWithRepo *secondUser = freshData[1];
            expect(secondUser.name).to.equal(@"Steve Jobs");
            __block NSArray *repos;
            repos = [_database runFetchForClassSync:ALTRepo.class fetchBlock:^FMResultSet *(FMDatabase *database) {
                return [database executeQuery:@"select * from repository order by id"];
            }];
            expect(repos).to.haveCountOf(4);
            ALTRepo *repo = repos[0];
            expect(repo.url).to.equal(@"http://www.github.com/tanis2000/repo1");
            done();
        }).catch(^(NSError *error) {
            NSLog(@"Failed with error: %@", [error localizedDescription]);
            expect(error).to.beNil();
            done();
        });
        });
        
    });

    // The following test is meant as a mock-up to test a new feature we're working on. You should be able to retrieve the same structure you downloaded from the web service when accessing the data directly from the database
    /*
    it(@"can store related json data into db and the data in the db is the same as the one from the web wervice", ^AsyncBlock {
        ALTUserWithRepoProvider *provider = [[ALTUserWithRepoProvider alloc] initWithDatabaseController:_database andRequestOperationManager:_manager andBaseURL:@"http://localhost:4567/"];
        ALTBaseRequest *request = [[ALTBaseRequest alloc] init];
        provider.request = request;
        __block NSArray *dbData = nil;
        [provider fetchData:ALTHTTPMethodGET].then(^(NSArray *cachedData, PMKPromise *freshData) {
            // cachedData contains data already in the db
            dbData = cachedData;
            return freshData;
        }).then(^(id mappingResult, NSArray *freshData) {
            NSLog(@"%@", dbData);
            NSLog(@"%@", freshData);
            expect(dbData).to.beKindOf(NSArray.class);
            expect(dbData).to.haveCountOf(2);
            expect(freshData).to.beKindOf(NSArray.class);
            expect(freshData).to.haveCountOf(2);
            ALTUserWithRepo *secondUser = freshData[1];
            expect(secondUser.name).to.equal(@"Steve Jobs");
            __block NSArray *repos;
            repos = [_database runFetchForClassSync:ALTRepo.class fetchBlock:^FMResultSet *(FMDatabase *database) {
                return [database executeQuery:@"select * from repository order by id"];
            }];
            expect(repos).to.haveCountOf(4);
            ALTRepo *repo = repos[0];
            expect(repo.url).to.equal(@"http://www.github.com/tanis2000/repo1");
            done();
        }).catch(^(NSError *error) {
            NSLog(@"Failed with error: %@", [error localizedDescription]);
            expect(error).to.beNil();
            done();
        });
        
    });
     */
    
    it(@"can cancel the last AFNetworking operation", ^ {
        waitUntil(^(DoneCallback done) {
        ALTUsersProvider *provider = [[ALTUsersProvider alloc] initWithDatabaseController:_database andRequestOperationManager:_manager andBaseURL:@"http://localhost:4567/"];
        ALTBaseRequest *request = [[ALTBaseRequest alloc] init];
        provider.request = request;
        [provider fetchData:ALTHTTPMethodGET].then(^(NSArray *cachedData, PMKPromise *freshData) {
            // cachedData contains data already in the db
            return freshData;
        }).then(^(id mappingResult, NSArray *freshData) {
            NSLog(@"%@", freshData);
        }).catch(^(NSError *error) {
            NSLog(@"Failed with error: %@", [error localizedDescription]);
            expect(error.code).to.equal(-999);
            done();
        });
        [provider.lastOperation cancel];
        expect(provider.lastOperation.isCancelled).to.beTruthy();
        });
    });
    
    
    it(@"Can insert new row whit Promise", ^
    {
        waitUntil(^(DoneCallback done) {
        PMKPromise * promise =[_database insertQuery:@"insert into user (userid, name, email) values (?, ?, ?)"
                                          parameters:@[[NSNumber numberWithInt:999], @"Valerio Santinelli", @"email@provider.com"]];
        promise.then(^(NSNumber*num)
                     {
                         expect(num.integerValue).to.beGreaterThan(0);
                         done();
                     }).catch(^(NSError *error) {
                         NSLog(@"Failed with error: %@", [error localizedDescription]);
                         expect(error.code).to.equal(-999);
                         done();
                     });
        });
    });
    
    it(@"Can insert new row", ^
    {
        waitUntil(^(DoneCallback done) {
        NSError *error = nil;
        NSNumber* pk = [_database insertQuerySync:@"insert into user (userid, name, email) values (?, ?, ?)"
                                       parameters:@[[NSNumber numberWithInt:999], @"Valerio Santinelli", @"email@provider.com"]
                                            error:&error];
        
        expect(pk.integerValue).to.beGreaterThan(0);
        expect(error).to.beNil();
        done();
        });
    });
    
});


SpecEnd

SpecBegin(GitHubTests)

describe(@"GitHub API tests", ^{
    beforeEach(^{
        _manager = [AFHTTPRequestOperationManager manager];
        _manager.responseSerializer = [AFJSONResponseSerializer serializer];
        _manager.requestSerializer = [AFJSONRequestSerializer serializer];
        [_manager.requestSerializer setValue:@"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/32.0.1700.102 Safari/537.36" forHTTPHeaderField:@"User-Agent"];
        [_manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [_manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];
        [_manager.requestSerializer setValue:@"token 0d8ccc304223565cf382aec4700f413815dcfc1a" forHTTPHeaderField:@"Authorization"];
        
        // Grab the Documents folder
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        
        // Sets the database filename
        NSString *filePath = [documentsDirectory stringByAppendingPathComponent:@"Test.sqlite"];
        
        _database = [[ALTDatabaseController alloc] initWithDatabasePath:filePath
                                                          creationBlock:^(FMDatabase *db, BOOL *rollback) {
                                                              [db executeUpdate:@"create table if not exists ghrepo "
                                                               "(id text unique, name text, url text)"];
                                                          }];
        
    });
    
    afterEach(^{
        [_database runDatabaseBlockInTransaction:^(FMDatabase *database, BOOL *rollback) {
            //[database executeUpdate:@"drop table if exists ghrepo"];
        }];
    });
    
    it(@"can store the list of my repos into db", ^ {
        waitUntil(^(DoneCallback done) {
        ALTGHRepoProvider *provider = [[ALTGHRepoProvider alloc] initWithDatabaseController:_database andRequestOperationManager:_manager andBaseURL:@"https://api.github.com"];
        ALTBaseRequest *request = [[ALTBaseRequest alloc] init];
        provider.request = request;
        [provider fetchData:ALTHTTPMethodGET].then(^(NSArray *cachedData, PMKPromise *freshData) {
            // cachedData contains data already in the db
            return freshData;
        }).then(^(id mappingResult, NSArray *freshData) {
            NSLog(@"%@", freshData);
            expect(freshData).to.beKindOf(NSArray.class);
            expect(freshData.count).to.beGreaterThan(10);
            ALTGHRepo *firstRepo = freshData[0];
            expect(firstRepo.repoName).to.equal(@"android-flip");
            done();
        }).catch(^(NSError *error) {
            NSLog(@"Failed with error: %@", [error localizedDescription]);
            expect(error).to.beNil();
            done();
        });
        });
    });
    
});
SpecEnd
