//
//  ALTRelationshipMapping.h
//  HeliumKit
//
//  Created by Valerio Santinelli on 17/07/14.
//  Copyright (c) 2014 Altralogica s.r.l. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ALTObjectMapping;

@interface ALTRelationshipMapping : NSObject

@property (nonatomic, strong, readonly) NSString *sourcePath;
@property (nonatomic, strong, readonly) NSString *destinationPath;
@property (nonatomic, strong, readonly) ALTObjectMapping *objectMapping;
@property (nonatomic, strong, readonly) NSArray *relationshipKeys;


+(instancetype)relationshipWithSourcePath:(NSString *)sourcePath destinationPath:(NSString *)destinationPath objectMapping:(ALTObjectMapping *)objectMapping;
+(instancetype)relationshipWithSourcePath:(NSString *)sourcePath destinationPath:(NSString *)destinationPath objectMapping:(ALTObjectMapping *)objectMapping relationshipKeys:(NSArray *)relationshipKeys;

@end
