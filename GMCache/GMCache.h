//
//  GMCache.h
//  GMCache
//
//  Created by Good Man on 2017/11/9.
//  Copyright © 2017年 Good Man. All rights reserved.
//

#import <Foundation/Foundation.h>

#define GMCache_Identifier_Default @"default.identifier.gmcache.goodman"
#define GMCache_Dicrectory_Default NSCachesDirectory
#define GMCache_SubPath_Default @"GMCache"
#define GMCache_Secured_Default NO

/**
 `GMCache` object is used to cache the data associated with a key,you can adopt it for url cache,local data cache,and so on.
 */
@interface GMCache : NSObject

@property(copy,nonatomic,readonly)NSString * identifier;

@property(assign,nonatomic,readonly)NSSearchPathDirectory directory;

@property(copy,nonatomic,readonly)NSString * subPath;

@property(assign,nonatomic)BOOL secured;

/**
 Return the global default cache.
 
 @return `GMPCache` object
 */
+ (instancetype)defaultCache;

/**
 Initialize a new cache with identifier

 @param identifier An unique key for cache.
 @return obj.
 */
- (id)initWithIdentifier:(NSString *)identifier;

/**
 Initialize a new cache with identifier and a custom path.

 @param identifier The identifier of a cache.
 @param directory NSSearchPathDirectory
 @param subPath a sub path appended to directory
 @return object
 */
- (id)initWithIdentifier:(NSString *)identifier directory:(NSSearchPathDirectory)directory subPath:(NSString *)subPath;

/**
 If current cache contains the key.

 @param key A unique string or a string refered in a class of cache operations.
 @return BoolObject
 */
- (BOOL)containsCacheKey:(NSString *)key;

/**
 Save the Object associated with a key,be holden in memory and disk,none secured.
 
 @param obj Object
 @param key A unique string or a string refered in a class of cache operations.
 */
- (void)cacheObject:(id) obj forKey:(NSString *) key;

/**
 Save the Object associated with a key and none secured

 @param obj Object
 @param key A unique string or a string refered in a class of cache operations.
 @param toDisk If you only want to save the Object to memory,set toDisk as YES.
 */
- (void)cacheObject:(id)obj forKey:(NSString *)key toDisk:(BOOL)toDisk;

/**
 Save the Object associated with a key,be holden in memory and disk.

 @param obj Object
 @param key A unique string or a string refered in a class of cache operations.
 @param secured If you want to save the Object in security,set secured as YES.
 */
- (void)cacheObject:(id)obj forKey:(NSString *)key secured:(BOOL)secured;

/**
 Get the Object associated with a key.
 
 @param key A unique string or a string refered in a class of cache operations.
 @return Object
 */
- (id)objectForCacheKey:(NSString *) key;

/**
 Delete the cache for a key.
 
 @param key A unique string or a string refered in a class of cache operations.
 */
- (void)deleteObjectForCacheKey:(NSString *) key;

/**
 Remove all objects cached.
 */
- (void)removeAllObjects;


@end
