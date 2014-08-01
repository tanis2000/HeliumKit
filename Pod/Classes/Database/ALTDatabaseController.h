//
//  ALTDatabaseController.h
//  HeliumKit
//
//  Created by Valerio Santinelli on 15/07/14.
//  Copyright (c) 2014 Altralogica s.r.l. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <FMDB/FMDB.h>
#import <PromiseKit/PromiseKit.h>

typedef void (^ALTDatabaseUpdateBlock)(FMDatabase *database, BOOL *rollback);
typedef FMResultSet *(^ALTDatabaseFetchBlock)(FMDatabase *database);
typedef void (^ALTDatabaseCompletionBlock)(void);

/**
 This is a standard database controller to make it easy to manage SQLite through FMDB without having to worry
 about thread-safety. Every operation on the database is handled in a single FMDatabaseQueue to make
 sure that they get done in order.
 */
@interface ALTDatabaseController : NSObject

/**
 The main queue all the operations are run against.
 */
@property (nonatomic, readonly, strong) FMDatabaseQueue *queue;

/**
 The full path and filename of the SQLite database.
 */
@property (nonatomic, readonly, copy) NSString *databasePath;

/**
 Default initializer. Creates and instance of `ALTDatabaseController` and sets up the database and main queue.
 The database is created if missing.
 
 @param databasePath full path and filename of the SQLite database
 @param creationBlock a block that will be invoked after opening/creating the database to perform operations like 
 @return an instance of `ALTDatabaseController`
 */
- (instancetype)initWithDatabasePath:(NSString *)databasePath
                       creationBlock:(ALTDatabaseUpdateBlock)creationBlock;

/**
 Run a database block that doesn't return a query result. Everything is wrapped up in a transaction block.
 
 @param databaseBlock an `ALTDatabaseUpdateBlock` to run
 
 @return a `PMKPromise` fulfilled once the block has been executed.
 */
- (PMKPromise *)runDatabaseBlockInTransaction:(ALTDatabaseUpdateBlock)databaseBlock;

/**
 Run a database block that doesn't return a query result. Everything is wrapped up in a transaction block. This is the same as `runDatabaseBlockInTransaction` except that it's being run synchronously.
 
 @param databaseBlock an `ALTDatabaseUpdateBlock` to run
 
 @return a `PMKPromise` fulfilled once the block has been executed.
 */
- (void)runDatabaseBlockInTransactionSync:(ALTDatabaseUpdateBlock)databaseBlock;

/**
 Execute a query block on the database and returns an NSArray of model objects.
 Model objects should be subclasses of `MTLModel` and implement the `MTLFMDBSerializing` protocol

 @param returnClass   the class of the objects returned from the database query
 @param databaseBlock a block containing a query to run against the database that must return an `FMResultSet`
 
 @return an NSArray of objects of class returnClass
 */
- (PMKPromise *)runFetchForClass:(Class)returnClass fetchBlock:(ALTDatabaseFetchBlock)databaseBlock;

/**
 Execute a query block on the database and returns an NSArray of model objects.
 This is the same as `runFetchForClass` but is run synchronously.
 Model objects should be subclasses of `MTLModel` and implement the `MTLFMDBSerializing` protocol
 
 @param returnClass   the class of the objects returned from the database query
 @param databaseBlock a block containing a query to run against the database that must return an `FMResultSet`
 
 @return an NSArray of objects of class returnClass
 */
- (NSArray *)runFetchForClassSync:(Class)returnClass fetchBlock:(ALTDatabaseFetchBlock)databaseBlock;

/**
 Helper to run a SQL SELECT * statement against a table.
 
 @param tableName   the name of the table
 @param returnClass class of the model objects returned
 
 @return an NSArray of models
 */
- (PMKPromise *)fetch:(NSString *)tableName returnClass:(Class)returnClass;

- (PMKPromise *)rawQuery:(NSString *)stmt returnClass:(Class)returnClass parameters:(NSArray *)parameters;

- (PMKPromise *)rawQuery:(NSString *)stmt returnClass:(Class)returnClass;

- (PMKPromise *)rawQuery:(NSString *)stmt parameters:(NSArray *)parameters;

- (NSArray *)rawQuerySync:(NSString *)stmt returnClass:(Class)returnClass parameters:(NSArray *)parameters;

- (NSArray *)rawQuerySync:(NSString *)stmt returnClass:(Class)returnClass;

- (NSArray *)rawQuerySync:(NSString *)stmt parameters:(NSArray *)parameters;

- (NSArray *)rawQuerySync:(NSString *)stmt;


@end
