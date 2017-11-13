//
//  GMDiskCache.h
//  GMCache
//
//  Created by Good Man on 2017/11/10.
//  Copyright © 2017年 Good Man. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GMDiskCache : NSObject

@property(copy,nonatomic,readonly)NSString * identifier;

@property(assign,nonatomic,readonly)NSString * path;

@property(assign,nonatomic)NSUInteger diskLimit;

@property(assign,nonatomic)NSUInteger cacheAge;

@property(assign,nonatomic)BOOL secured;

@property(assign,nonatomic)NSUInteger countLimit;

- (id)initWithIdentifier:(NSString *)identifier path:(NSString *)path;

- (BOOL)containsCacheKey:(NSString *)key;

- (BOOL)cacheObject:(id) obj forKey:(NSString *) key;

- (BOOL)cacheObject:(id)obj forKey:(NSString *)key secured:(BOOL)secured;

- (id)objectForCacheKey:(NSString *) key;

- (BOOL)deleteObjectForCacheKey:(NSString *) key;

- (BOOL)removeAllObjects;

@end
