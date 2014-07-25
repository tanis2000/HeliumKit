//
//  ALTObjectMapping.h
//  HeliumKit
//
//  Created by Valerio Santinelli on 17/07/14.
//  Copyright (c) 2014 Altralogica s.r.l. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ALTRelationshipMapping;

@interface ALTObjectMapping : NSObject

@property (nonatomic, strong, readonly) NSString *sourcePath;
@property (nonatomic, readonly) Class modelClass;
@property (nonatomic, strong, readonly) NSMutableArray *relationships;

+(instancetype)mappingForModel:(Class)modelClass sourcePath:(NSString *)sourcePath;

- (void)addRelationship:(ALTRelationshipMapping *)relationship;

@end
