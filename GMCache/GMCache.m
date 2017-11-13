//
//  GMCache.m
//  GMCache
//
//  Created by Good Man on 2017/11/9.
//  Copyright © 2017年 Good Man. All rights reserved.
//

#import "GMCache.h"
#import "GMDiskCache.h"
#import "GMMemoryCache.h"
#import "GMCacheProvider.h"

#define GMCache_Identifier_Default @"default.identifier.gmcache.goodman"
#define GMCache_DiskLimit NSIntegerMax
#define GMCache_MemLimit NSIntegerMax

@interface GMCache ()
{
    GMDiskCache * _diskCache;
    GMMemoryCache * _memCache;
    dispatch_queue_t _cacheQueue;
}
@end

@implementation GMCache

+ (instancetype)defaultCache {
    GMCache *defaultCache=[self cacheWithIdentifier:GMCache_Identifier_Default];
    if (!defaultCache) {
        defaultCache=[[self alloc] initWithIdentifier:GMCache_Identifier_Default];
    }
    return defaultCache;
}

+ (instancetype)cacheWithIdentifier:(NSString *)identifier {
    if (![identifier isKindOfClass:[NSString class]] || identifier.length==0)return nil;
    return [GMCacheProvider cacheWithIdentifier:identifier];
}

- (id)initWithIdentifier:(NSString *)identifier {
    NSString * defaultPath=[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    if (defaultPath.length==0)return nil;
    return [self initWithIdentifier:identifier path:defaultPath];
}

- (id)initWithIdentifier:(NSString *)identifier path:(NSString *)path {
    if (![identifier isKindOfClass:[NSString class]] || identifier.length==0)return nil;
    if ([[self class] cacheWithIdentifier:identifier]) {
        return nil;
    }
    self=[self init];
    if (self) {
        _identifier=identifier;
        _path=path;
        _cacheQueue=dispatch_queue_create([identifier UTF8String], NULL);
        _diskCache=[[GMDiskCache alloc] initWithIdentifier:_identifier path:_path];
        _memCache=[GMMemoryCache new];
        [GMCacheProvider saveCache:self];
    }
    return self;
}

- (BOOL)containsCacheKey:(NSString *)key {
    if (![key isKindOfClass:[NSString class]] || key.length==0)return NO;
    if (![_memCache objectForKey:key]) {
        return [_diskCache containsCacheKey:key];
    }
    return YES;
}

- (void)cacheObject:(id)obj forKey:(NSString *)key {
    [self cacheObject:obj forKey:key toDisk:YES];
}

- (void)cacheObject:(id)obj forKey:(NSString *)key toDisk:(BOOL)toDisk {
    [self cacheObject:obj forKey:key toDisk:toDisk secured:NO];
}

- (void)cacheObject:(id)obj forKey:(NSString *)key secured:(BOOL)secured {
    [self cacheObject:obj forKey:key toDisk:YES secured:secured];
}

- (void)cacheObject:(id)obj forKey:(NSString *)key toDisk:(BOOL)toDisk secured:(BOOL)secured {
    if (![key isKindOfClass:[NSString class]] || key.length==0)return;
    if (![obj conformsToProtocol:@protocol(NSCoding)])return;
    if (toDisk) {
        if ([_diskCache cacheObject:obj forKey:key secured:secured]) {
            [_memCache setObject:obj forKey:key];
        }
    }
    else{
        [_memCache setObject:obj forKey:key];
    }
}

- (id)ObjectForCacheKey:(NSString *)key {
    if (![key isKindOfClass:[NSString class]] || key.length==0)return nil;
    id obj=[_memCache objectForKey:key];
    if (!obj) {
        obj=[_diskCache objectForCacheKey:key];
    }
    return obj;
}

- (BOOL)deleteObjectForCacheKey:(NSString *)key {
    if (![key isKindOfClass:[NSString class]] || key.length==0)return NO;
    if ([_diskCache deleteObjectForCacheKey:key]) {
        [_memCache removeObjectForKey:key];
        return YES;
    }
    return NO;
}

- (BOOL)removeAllObjects {
    if ([_diskCache removeAllObjects]) {
        [_memCache removeAllObjects];
        return YES;
    }
    return NO;
}

@end
