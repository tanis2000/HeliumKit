//
//  HeliumKitTests.m
//  HeliumKitTests
//
//  Created by Valerio Santinelli on 07/25/2014.
//  Copyright (c) 2014 Valerio Santinelli. All rights reserved.
//

#import <HeliumKit/ALTDatabaseController.h>
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
                                                          creationBlock:^(FMDatabase *db) {
                                                              [db executeUpdate:@"create table if not exists user "
                                                               "(userId text unique, name text, email text)"];
                                                          }];
        
        /*
        [_database runFetchForClass:ALTLabel.class fetchBlock:^FMResultSet *(FMDatabase *database) {
            return [database executeQuery:@"select * from label limit 1"];
        }].then(^(NSArray *res){
            NSLog(@"%@", res);
        });
         */
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
});

/*
describe(@"these will fail", ^{

    it(@"can do maths", ^{
        expect(1).to.equal(2);
    });

    it(@"can read", ^{
        expect(@"number").to.equal(@"string");
    });
    
    it(@"will wait and fail", ^AsyncBlock {
        
    });
});

describe(@"these will pass", ^{
    
    it(@"can do maths", ^{
        expect(1).beLessThan(23);
    });
    
    it(@"can read", ^{
        expect(@"team").toNot.contain(@"I");
    });
    
    it(@"will wait and succeed", ^AsyncBlock {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
            done();
        });
    });
});
*/

SpecEnd
