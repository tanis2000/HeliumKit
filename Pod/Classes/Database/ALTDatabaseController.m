//
//  ALTDatabaseController.m
//  HeliumKit
//
//  Created by Valerio Santinelli on 15/07/14.
//  Copyright (c) 2014 Altralogica s.r.l. All rights reserved.
//

#import "ALTDatabaseController.h"
#import <MTLFMDBAdapter/MTLFMDBAdapter.h>

@implementation ALTDatabaseController

- (instancetype)init
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"%@ Failed to call designated initializer. Invoke initWithDatabasePath: instead.",
                                           NSStringFromClass([self class])]
                                 userInfo:nil];
}

- (instancetype)initWithDatabasePath:(NSString *)databasePath
                       creationBlock:(ALTDatabaseUpdateBlock)creationBlock
{
    self = [super init];
    if (self) {
        _databasePath = databasePath;
        if (!self.databasePath) {
            [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Missing database path and filename. You should call initWithDatabasePath: with the full path to the SQLite database file" userInfo:nil];
        }
        // Tell FMDB where the database is
        _queue = [FMDatabaseQueue databaseQueueWithPath:self.databasePath];
        
        // Run the starting creation scripts
        [self runDatabaseBlockInTransaction:creationBlock];
    }
    return self;
}

- (PMKPromise *)runDatabaseBlockInTransaction:(ALTDatabaseUpdateBlock)databaseBlock
{
    return [PMKPromise new:^(PMKPromiseFulfiller fullfiller, PMKPromiseRejecter rejecter) {
        [_queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
            databaseBlock(db, rollback);
            fullfiller(nil);
        }];
    }];
}

- (void)runDatabaseBlockInTransactionSync:(ALTDatabaseUpdateBlock)databaseBlock
{
    [_queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        databaseBlock(db, rollback);
    }];
}

- (PMKPromise *)runFetchForClass:(Class)returnClass fetchBlock:(ALTDatabaseFetchBlock)databaseBlock
{
    return [PMKPromise new:^(PMKPromiseFulfiller fullfiller, PMKPromiseRejecter rejecter) {
        [_queue inDatabase:^(FMDatabase *db) {
            FMResultSet *resultSet = databaseBlock(db);
            NSArray *fetchedObjects = [self databaseObjectsWithResultSet:resultSet
                                                                   class:returnClass];
            [resultSet close];
            fullfiller(fetchedObjects);
        }];
    }];
}

- (NSArray *)runFetchForClassSync:(Class)returnClass fetchBlock:(ALTDatabaseFetchBlock)databaseBlock
{
    __block NSArray *fetchedObjects = [NSArray array];
    [_queue inDatabase:^(FMDatabase *db) {
        FMResultSet *resultSet = databaseBlock(db);
        fetchedObjects = [self databaseObjectsWithResultSet:resultSet
                                                               class:returnClass];
        [resultSet close];
    }];
    return fetchedObjects;
}


- (NSArray *)databaseObjectsWithResultSet:(FMResultSet *)resultSet
                                    class:(Class)class
{
    NSMutableArray *s = [NSMutableArray array];
    while ([resultSet next]) {
        NSError *error = nil;
        id obj = [MTLFMDBAdapter modelOfClass:class fromFMResultSet:resultSet error:&error];
        [s addObject:obj];
    }
    return s;
}

-(PMKPromise *)fetch:(NSString *)tableName returnClass:(Class)returnClass
{
    return [PMKPromise new:^(PMKPromiseFulfiller fullfiller, PMKPromiseRejecter rejecter) {
        [_queue inDatabase:^(FMDatabase *db) {
            FMResultSet *res = [db executeQuery:[NSString stringWithFormat:@"select * from %@", tableName]];
            NSArray *s = [self databaseObjectsWithResultSet:res class:returnClass];
            fullfiller(s);
        }];
    }];
}

- (PMKPromise *)rawQuery:(NSString *)stmt returnClass:(Class)returnClass parameters:(NSArray *)parameters
{
    return [PMKPromise new:^(PMKPromiseFulfiller fullfiller, PMKPromiseRejecter rejecter) {
        [_queue inDatabase:^(FMDatabase *db) {
            FMResultSet *res = [db executeQuery:stmt withArgumentsInArray:parameters];
            NSArray *s = [self databaseObjectsWithResultSet:res class:returnClass];
            fullfiller(s);
        }];
    }];
}

- (PMKPromise *)rawQuery:(NSString *)stmt returnClass:(Class)returnClass
{
    return [self rawQuery:stmt returnClass:returnClass parameters:nil];
}


- (NSArray *)rawQuerySync:(NSString *)stmt returnClass:(Class)returnClass parameters:(NSArray *)parameters {
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    __block id obj = nil;
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    [self rawQuery:stmt returnClass:returnClass parameters:parameters].thenOn(queue, ^(NSArray *res){
        obj = res;
        dispatch_semaphore_signal(sem);
    });
    
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    return obj;
}

- (PMKPromise *)rawQuery:(NSString *)stmt parameters:(NSArray *)parameters
{
    return [PMKPromise new:^(PMKPromiseFulfiller fullfiller, PMKPromiseRejecter rejecter) {
        [_queue inDatabase:^(FMDatabase *db) {
            NSMutableArray *s = [NSMutableArray array];
            FMResultSet *res = [db executeQuery:stmt withArgumentsInArray:parameters];
            while ([res next]) {
                [s addObject:[res resultDictionary]];
            }
            fullfiller(s);
        }];
    }];
}

- (NSArray *)rawQuerySync:(NSString *)stmt parameters:(NSArray *)parameters {
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    __block id obj = nil;
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    [self rawQuery:stmt parameters:parameters].thenOn(queue, ^(NSArray *res){
        obj = res;
        dispatch_semaphore_signal(sem);
    });
    
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    return obj;
}

- (NSArray *)rawQuerySync:(NSString *)stmt returnClass:(Class)returnClass {
    return [self rawQuerySync:stmt returnClass:returnClass parameters:nil];
}

- (NSArray *)rawQuerySync:(NSString *)stmt {
    return [self rawQuerySync:stmt parameters:nil];
}


@end
