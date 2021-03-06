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

@interface GMCache ()
{
    GMDiskCache * _diskCache;
    GMMemoryCache * _memCache;
}
@end

static GMCache * ST_GMCache_Default;

@implementation GMCache

#pragma -mark initialize methods

+ (instancetype)defaultCache {
    if (!ST_GMCache_Default) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            ST_GMCache_Default=[[self alloc] initWithIdentifier:GMCache_Identifier_Default];
        });
    }
    return ST_GMCache_Default;
}

- (id)initWithIdentifier:(NSString *)identifier {
    return [self initWithIdentifier:identifier directory:GMCache_Dicrectory_Default subPath:GMCache_SubPath_Default];
}

- (id)initWithIdentifier:(NSString *)identifier directory:(NSSearchPathDirectory)directory subPath:(NSString *)subPath {
    if (![identifier isKindOfClass:[NSString class]] || identifier.length==0)return nil;
    self=[self init];
    if (self) {
        _identifier=identifier;
        _directory=directory;
        _subPath=subPath;
        NSString * path=[[NSSearchPathForDirectoriesInDomains(_directory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:_subPath];
        _diskCache=[[GMDiskCache alloc] initWithIdentifier:_identifier path:path];
        _memCache=[GMMemoryCache new];
    }
    return self;
}

#pragma -mark (select,update,insert,delete) methods

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
        if ([_diskCache deleteObjectForCacheKey:key]) {
            [_memCache setObject:obj forKey:key];
        }
    }
}

- (id)objectForCacheKey:(NSString *)key {
    if (![key isKindOfClass:[NSString class]] || key.length==0)return nil;
    id obj=[_memCache objectForKey:key];
    if (!obj) {
        obj=[_diskCache objectForCacheKey:key];
        if (obj) {
            [_memCache setObject:obj forKey:key];
        }
    }
    return obj;
}

- (void)deleteObjectForCacheKey:(NSString *)key {
    if (![key isKindOfClass:[NSString class]] || key.length==0)return;
    if ([_diskCache deleteObjectForCacheKey:key]) {
        [_memCache removeObjectForKey:key];
    }
}

- (void)removeAllObjects {
    if ([_diskCache removeAllObjects]) {
        [_memCache removeAllObjects];
    }
}

#pragma -mark getters and setters

- (void)setSecured:(BOOL)secured {
    _secured=secured;
    _diskCache.secured=secured;
}

- (void)setDbThreshold:(NSUInteger)dbThreshold {
    _dbThreshold=dbThreshold;
    _diskCache.dbThreshold=dbThreshold;
}

@end
