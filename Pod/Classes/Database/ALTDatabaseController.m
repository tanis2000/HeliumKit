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



+ (FMResultSet*)executeQuesryInDB:(FMDatabase*)db stmt:(NSString *)stmt
                       parameters:(NSArray *)parameters error:(NSError**)outErr
{
    FMResultSet *res = [db executeQuery:stmt withArgumentsInArray:parameters];
    if(res == nil && outErr)
        *outErr = [db lastError] ;
    return res;
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
        NSAssert(obj != nil, @"MTLFMDBAdapter returned nil while mapping a model to class %@. Internal error:%@", class, error.localizedDescription);
        [s addObject:obj];
    }
    return s;
}

-(PMKPromise *)fetch:(NSString *)tableName returnClass:(Class)returnClass
{
    return [PMKPromise new:^(PMKPromiseFulfiller fullfiller, PMKPromiseRejecter rejecter) {
        [_queue inDatabase:^(FMDatabase *db) {
            NSError *error = nil;
            FMResultSet *res = [[self class]executeQuesryInDB:db stmt:[NSString stringWithFormat:@"select * from %@", tableName] parameters:nil error:&error];
            if(error != nil)
            {
                rejecter(error);
            }
            else
            {
                NSArray *s = [self databaseObjectsWithResultSet:res class:returnClass];
                fullfiller(s);
            }
        }];
    }];
}

- (PMKPromise *)rawQuery:(NSString *)stmt returnClass:(Class)returnClass parameters:(NSArray *)parameters
{
    return [PMKPromise new:^(PMKPromiseFulfiller fullfiller, PMKPromiseRejecter rejecter) {
        [_queue inDatabase:^(FMDatabase *db) {
            NSError *error = nil;
            FMResultSet *res = [[self class]executeQuesryInDB:db stmt:stmt parameters:parameters error:&error];
            if(error != nil)
            {
                rejecter(error);
            }
            else
            {
                NSArray *s = [self databaseObjectsWithResultSet:res class:returnClass];
                fullfiller(s);
            }
        }];
    }];
}

- (PMKPromise *)rawQuery:(NSString *)stmt returnClass:(Class)returnClass
{
    return [self rawQuery:stmt returnClass:returnClass parameters:nil];
}


- (NSArray *)rawQuerySync:(NSString *)stmt returnClass:(Class)returnClass parameters:(NSArray *)parameters error:(NSError**)error  {
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    __block id obj = nil;
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    [self rawQuery:stmt returnClass:returnClass parameters:parameters].thenOn(queue, ^(NSArray *res){
        obj = res;
        dispatch_semaphore_signal(sem);
    }).catchOn(queue, ^(NSError *outErr)
             {
                 if(error)
                     *error = outErr;
                 dispatch_semaphore_signal(sem);
             });
    
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    return obj;
}

- (NSArray *)rawQuerySync:(NSString *)stmt returnClass:(Class)returnClass parameters:(NSArray *)parameters
{
    return [self rawQuerySync:stmt returnClass:returnClass parameters:parameters error:nil];
}



- (PMKPromise *)rawQuery:(NSString *)stmt parameters:(NSArray *)parameters
{
    return [PMKPromise new:^(PMKPromiseFulfiller fullfiller, PMKPromiseRejecter rejecter) {
        [_queue inDatabase:^(FMDatabase *db) {
            NSMutableArray *s = [NSMutableArray array];
            NSError *error = nil;
            FMResultSet *res = [[self class]executeQuesryInDB:db stmt:stmt parameters:parameters error:&error];
            if(error != nil)
            {
                rejecter(error);
            }
            else
            {
                while ([res next]) {
                    [s addObject:[res resultDictionary]];
                }
                fullfiller(s);
            }
        }];
    }];
}

- (NSArray *)rawQuerySync:(NSString *)stmt parameters:(NSArray *)parameters error:(NSError**)error  {
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    __block id obj = nil;
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    [self rawQuery:stmt parameters:parameters].thenOn(queue, ^(NSArray *res){
        obj = res;
        dispatch_semaphore_signal(sem);
    }).catchOn(queue, ^(NSError *outErr)
             {
                 if(error)
                     *error = outErr;
                 dispatch_semaphore_signal(sem);
             });
    
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    return obj;
}
- (NSArray *)rawQuerySync:(NSString *)stmt parameters:(NSArray *)parameters
{
    return [self rawQuerySync:stmt parameters:parameters error:nil];
}



- (NSArray *)rawQuerySync:(NSString *)stmt returnClass:(Class)returnClass error:(NSError**)error {
    return [self rawQuerySync:stmt returnClass:returnClass parameters:nil error:error];
}
- (NSArray *)rawQuerySync:(NSString *)stmt returnClass:(Class)returnClass
{
    return [self rawQuerySync:stmt returnClass:returnClass error:nil];
}


- (NSArray *)rawQuerySync:(NSString *)stmt error:(NSError**)error  {
    return [self rawQuerySync:stmt parameters:nil error:error];
}
- (NSArray *)rawQuerySync:(NSString *)stmt
{
    return [self rawQuerySync:stmt error:nil];
}


- (PMKPromise *)insertQuery:(NSString *)stmt parameters:(NSArray *)parameters
{
    return [PMKPromise new:^(PMKPromiseFulfiller fullfiller, PMKPromiseRejecter rejecter) {
        [_queue inDatabase:^(FMDatabase *db) {
            NSMutableArray *s = [NSMutableArray array];
            NSError *error = nil;
            FMResultSet *res = [[self class]executeQuesryInDB:db stmt:stmt parameters:parameters error:&error];
            if(error != nil)
            {
                rejecter(error);
            }
            else{
                while ([res next]) {
                    [s addObject:[res resultDictionary]];
                }
                NSNumber * key = [NSNumber numberWithLongLong:[db lastInsertRowId]];
                fullfiller(key);
            }
        }];
    }];
}

- (NSNumber *)insertQuerySync:(NSString *)stmt parameters:(NSArray *)parameters error:(NSError**)error {
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    __block id obj = nil;
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    [self insertQuery:stmt parameters:parameters].thenOn(queue, ^(NSNumber *res){
        obj = res;
        dispatch_semaphore_signal(sem);
    }).catchOn(queue, ^(NSError *outErr)
             {
                 if(error)
                     *error = outErr;
                 dispatch_semaphore_signal(sem);
             });
    
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    return obj;
}

- (NSNumber *)insertQuerySync:(NSString *)stmt parameters:(NSArray *)parameters
{
    return [self insertQuerySync:stmt parameters:parameters error:nil];
}


@end
