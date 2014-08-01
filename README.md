# HeliumKit

[![CI Status](http://img.shields.io/travis/tanis2000/HeliumKit.svg?style=flat)](https://travis-ci.org/tanis2000/HeliumKit)
[![Version](https://img.shields.io/cocoapods/v/HeliumKit.svg?style=flat)](http://cocoadocs.org/docsets/HeliumKit)
[![License](https://img.shields.io/cocoapods/l/HeliumKit.svg?style=flat)](http://cocoadocs.org/docsets/HeliumKit)
[![Platform](https://img.shields.io/cocoapods/p/HeliumKit.svg?style=flat)](http://cocoadocs.org/docsets/HeliumKit)

## About

HeliumKit is a lightweight framework that sits between your web services and the business logic of your app.

**WARNING!** HeliumKit is still in **alpha** version and API might change any time.

It provides basic mapping to automate conversion from DTO coming from your web services into object models of your business domain. We decided to streamline the process by adopting some libraries and frameworks:

- [PromiseKit](https://github.com/mxcl/PromiseKit) to manage all the async code
- [FMDB](https://github.com/ccgus/fmdb) to store data in SQLite
- [Mantle](https://github.com/Mantle/Mantle) to convert models to and from JSON representation
- [MTLFMDBAdapter](https://github.com/tanis2000/MTLFMDBAdapter) to convert models into SQL statements to feed to FMDB
- [AFNetworking](https://github.com/AFNetworking/AFNetworking) to manage web service API calls

The main focus is to keep this framework as lightweight as possible and at the same time make it flexible enough for you to craft the perfect solution to your data transfer and storage layer. Many ideas come from RestKit as I've been using that framework for commercial apps before. But I've never been fond of Core Data as the storage architecture. I'm way too used to good old SQL statements and I can't live with the threading issues that you have to fight against when using Core Data. Core Data is great, but it's not for me.

HeliumKit can simply keep your data in in-memory models or it can write them to SQLite as needed. That's completely configurable. I tried to keep in mind the convention over configuration paradigm as I hate boilerplate code.
I hope you find this framework just as useful as I do. Contributions and pull requests are welcome!

## Introduction

HeliumKit is pretty much the result of my frustration with other REST mapping frameworks and Core Data. The article [On Using SQLite and FMDB Instead of Core Data](http://www.objc.io/issue-4/SQLite-instead-of-core-data.html) by [Brent Simmons](http://inessential.com/) sums up what I think about Core Data and why I try to avoid using it whenever possible. I've also drawn inspiration from that article to come up with the [ALTDatabaseController](https://github.com/tanis2000/HeliumKit/blob/develop/Pod/Classes/Database/ALTDatabaseController.h) class. 

## Quick start

Here's a quick example of what you can do with HeliumKit.

### Your first data provider

Create a new provider to read the repository of my user from GitHub. The first thing to do is to create the model:

ALTGHRepo.h
```obj-c
#import "MTLModel.h"
#import <Mantle/MTLJSONAdapter.h>
#import <MTLFMDBAdapter/MTLFMDBAdapter.h>

@interface ALTGHRepo : MTLModel<MTLJSONSerializing, MTLFMDBSerializing>

@property (nonatomic, copy) NSNumber *repoId;
@property (nonatomic, copy) NSString *repoName;
@property (nonatomic, copy) NSString *repoUrl;

@end
``` 

ALTGHRepo.m
```obj-c
#import "ALTGHRepo.h"

@implementation ALTGHRepo

+(NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{
             @"repoId": @"id",
             @"repoName": @"name",
             @"repoUrl": @"url",
             };
}

+(NSDictionary *)FMDBColumnsByPropertyKey {
    return @{
             @"repoId": @"id",
             @"repoName": @"name",
             @"repoUrl": @"url",
             };
}

+(NSArray *)FMDBPrimaryKeys {
    return @[@"id"];
}

+(NSString *)FMDBTableName {
    return @"ghrepo";
}
@end
```

Next you need to create the provider itself:

ALTGHRepoProvider.h
```obj-c
#import "ALTBaseProvider.h"

@interface ALTGHRepoProvider : ALTBaseProvider

@end
```

ALTGHRepoProvider.m
```obj-c
#import "ALTGHRepoProvider.h"
#import "ALTGHRepo.h"
#import <HeliumKit/ALTObjectMapping.h>

@implementation ALTGHRepoProvider

- (NSString *)endPoint {
    return [NSString stringWithFormat:@"%@%@", self.baseURL, @"/users/tanis2000/repos"];
}

- (PMKPromise *)fetchObjectsFromDb {
    return [PMKPromise new:^(PMKPromiseFulfiller fulfiller, PMKPromiseRejecter rejecter) {
        if (!self.skipDatabase) {
            [self.database fetch:@"ghrepo" returnClass:ALTGHRepo.class].then(^(id res) {
                fulfiller(res);
            });
        } else {
            fulfiller(nil);
        }
    }];
}

- (NSArray *)objectMappings {
    ALTObjectMapping *mapping = [ALTObjectMapping mappingForModel:ALTGHRepo.class sourcePath:nil];
    
    return @[mapping];
}
```

To test this, add the following code to your business logic layer:

```obj-c
ALTDatabaseController *_database;
AFHTTPRequestOperationManager *_manager;

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
                                                      [db executeUpdate:@"create table if not exists ghrepo "
                                                       "(id text unique, name text, url text)"];
                                                  }];

ALTGHRepoProvider *provider = [[ALTGHRepoProvider alloc] initWithDatabaseController:_database andRequestOperationManager:_manager andBaseURL:@"https://api.github.com"];
ALTBaseRequest *request = [[ALTBaseRequest alloc] init];
provider.request = request;
[provider fetchData:ALTHTTPMethodGET].then(^(NSArray *cachedData, PMKPromise *freshData) {
    // cachedData contains data already in the db
    return freshData;
}).then(^(id mappingResult, NSArray *freshData) {
	// freshData contains the data that has been grabbed from the remote service and saved into the database
    NSLog(@"%@", freshData);
}).catch(^(NSError *error) {
    NSLog(@"Failed with error: %@", [error localizedDescription]);
});

```

## Limitations

HeliumKit isn't a one-stop-do-it-all solution. It does a few things pretty well but that's all there is to it. This is not a full ORM solution nor is it a complete replacement of Core Data.

What HeliumKit does not do:

- there's no support for models that are children of other models. The data being loaded from the database is an NSArray of instances of models returned by a SQL query. We're not retrieving associated models. BUT! If you work directly with the data returned by the web service, that data will contain all of the related classes as well.

## Usage

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Installation

HeliumKit is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

    pod "HeliumKit"

## Author

Valerio Santinelli, santinelli@altralogica.it

## License

HeliumKit is available under the MIT license. See the LICENSE file for more info.

