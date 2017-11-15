//
//  GMCacheProvider.m
//  GMCache
//
//  Created by Good Man on 2017/11/10.
//  Copyright © 2017年 Good Man. All rights reserved.
//

#import "GMCacheProvider.h"
#import "FMDB.h"
#import "GMCache.h"

static NSMapTable * ST_GMCache_MapTable;
static FMDatabaseQueue * ST_GMCache_DBQueue;

@implementation GMCacheProvider

+ (void)initialize {
    if (!ST_GMCache_MapTable) {
        ST_GMCache_MapTable=[[NSMapTable alloc] initWithKeyOptions:NSPointerFunctionsStrongMemory valueOptions:NSPointerFunctionsStrongMemory capacity:1];
        [self openDB];
    }
}

+ (BOOL)containsCacheIdentifier:(NSString *)identifier {
    if (![identifier isKindOfClass:[NSString class]] || identifier.length==0)return NO;
    if ([ST_GMCache_MapTable objectForKey:identifier])return YES;
    __block BOOL rst=NO;
    [ST_GMCache_DBQueue inDatabase:^(FMDatabase * _Nonnull db) {
        FMResultSet * resultSet=[db executeQuery:@"select 1 from gm_caches where identifier=?",identifier];
        if (resultSet && resultSet.next) {
            rst=YES;
            [resultSet close];
        }
    }];
    return rst;
}

+ (GMCache *)cacheWithIdentifier:(NSString *)identifier {
    if (![identifier isKindOfClass:[NSString class]] || identifier.length==0)return nil;
    GMCache * cache=[ST_GMCache_MapTable objectForKey:identifier];
    NSLog(@"cache:%@",cache);
    if (!cache) {
        cache=[self getCacheFromDisk:identifier];
    }
    return cache;
}

+ (BOOL)openDB {
    NSString * dbPath=[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
    if (dbPath.length>0) {
        dbPath=[dbPath stringByAppendingPathComponent:@"caches_GMCache_goodman.db"];
        ST_GMCache_DBQueue=[FMDatabaseQueue databaseQueueWithPath:dbPath];
        if (ST_GMCache_DBQueue) {
            NSString * initSql=@"CREATE TABLE IF NOT EXISTS gm_caches ( \
            identifier varchar(50) PRIMARY KEY not null,\
            path text not null,\
            cache_age INTEGER,\
            disk_limit INTEGER,\
            mem_limit INTEGER,\
            count_limit INTEGER)";
            __block BOOL update=NO;
            [ST_GMCache_DBQueue inDatabase:^(FMDatabase * _Nonnull db) {
                update=[db executeUpdate:initSql];
            }];
            return update;
        }
    }
    return NO;
}

+ (BOOL)saveCache:(GMCache *)cache {
    [ST_GMCache_MapTable setObject:cache forKey:cache.identifier];
    return [self saveCacheToDisk:cache];
}

+ (BOOL)saveCacheToDisk:(GMCache *)cache {
    __block BOOL rst=NO;
    [ST_GMCache_DBQueue inDatabase:^(FMDatabase * _Nonnull db) {
        FMResultSet *resultSet=[db executeQuery:@"select 1 from gm_caches where identifier=?",cache.identifier];
        if (resultSet && resultSet.next) {
            [resultSet close];
            rst=[db executeUpdate:@"update gm_caches set cache_age=?,disk_limit=?,mem_limit=?,count_limit=?",@(cache.cacheAge),@(cache.diskLimit),@(cache.memoryLimit),@(0)];
        }
        else {
            rst=[db executeUpdate:@"insert into gm_caches (identifier,path,cache_age,disk_limit,mem_limit,count_limit) values(?,?,?,?,?,?)",cache.identifier,cache.path,@(cache.cacheAge),@(cache.diskLimit),@(cache.memoryLimit),@(0)];
        }
    }];
    return rst;
}

+ (GMCache *)getCacheFromDisk:(NSString *)identifier {
    if (![identifier isKindOfClass:[NSString class]] || identifier.length==0)return nil;
    __block NSString * path;
    __block NSUInteger cache_age;
    __block NSUInteger disk_limit;
    __block NSUInteger mem_limit;;
    __block NSUInteger count_limit;
    __block BOOL rst=NO;
    [ST_GMCache_DBQueue inDatabase:^(FMDatabase * _Nonnull db) {
        FMResultSet * resultSet=[db executeQuery:@"select * from gm_caches where identifier=?",identifier];
        if (resultSet && [resultSet next]) {
            rst=YES;
            path=[resultSet stringForColumnIndex:1];
            cache_age=[resultSet longForColumnIndex:2];
            disk_limit=[resultSet longForColumnIndex:3];
            mem_limit=[resultSet longForColumnIndex:4];
            count_limit=[resultSet longForColumnIndex:5];
            [resultSet close];
        }
    }];
    if (rst) {
        GMCache * cache=[[GMCache alloc] initWithIdentifier:identifier path:path];
        cache.diskLimit=disk_limit;
        cache.memoryLimit=mem_limit;
        cache.cacheAge=cache_age;
        return cache;
    }
    return nil;
}

@end
