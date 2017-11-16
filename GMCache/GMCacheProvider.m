//
//  GMCacheProvider.m
//  GMCache
//
//  Created by Good Man on 2017/11/10.
//  Copyright © 2017年 Good Man. All rights reserved.
//

#import "GMCacheProvider.h"
#import <FMDB/FMDB.h>
#import "GMCache.h"

#define GMCache_Caches_Default @"caches.GMCache.goodman.db"

#define Lock(identifier) dispatch_semaphore_t semaphore=[ST_GMCache_Semephores objectForKey:identifier];\
if (!semaphore) {\
    semaphore=dispatch_semaphore_create(1);\
}\
dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)

#define UnLock() dispatch_semaphore_signal(semaphore)

static NSMutableDictionary * ST_GMCache_Semephores;
static NSCache * ST_GMCache_MapTable;
static FMDatabaseQueue * ST_GMCache_DBQueue;

@implementation GMCacheProvider

#pragma -mark to initialize static varable and open database

+ (void)initialize {
    if (!ST_GMCache_MapTable) {
        ST_GMCache_MapTable=[NSCache new];
        ST_GMCache_Semephores=[NSMutableDictionary new];
        [self openDB];
    }
}

#pragma -mark get or save cache objects

+ (GMCache *)cacheWithIdentifier:(NSString *)identifier {
    if (![identifier isKindOfClass:[NSString class]] || identifier.length==0)return nil;
    Lock(identifier);
    GMCache * cache=[ST_GMCache_MapTable objectForKey:identifier];
    NSLog(@"cache:%@",cache);
    if (!cache) {
        cache=[self getCacheFromDisk:identifier];
    }
    UnLock();
    return cache;
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
            rst=[db executeUpdate:@"update gm_caches set cache_age=?,disk_limit=?,mem_limit=?,count_limit=?",@(cache.cacheAge),@(cache.diskLimit),@(cache.memoryLimit),@(cache.countLimit)];
        }
        else {
            rst=[db executeUpdate:@"insert into gm_caches (identifier,directory,subpath,cache_age,disk_limit,mem_limit,count_limit) values(?,?,?,?,?,?)",cache.identifier,cache.directory,cache.subPath?cache.subPath:@"",@(cache.cacheAge),@(cache.diskLimit),@(cache.memoryLimit),@(cache.countLimit)];
        }
    }];
    return rst;
}

+ (GMCache *)getCacheFromDisk:(NSString *)identifier {
    if (![identifier isKindOfClass:[NSString class]] || identifier.length==0)return nil;
    __block NSSearchPathDirectory directory;
    __block NSString * subPath;
    __block NSUInteger cache_age;
    __block NSUInteger disk_limit;
    __block NSUInteger mem_limit;;
    __block NSUInteger count_limit;
    __block BOOL rst=NO;
    [ST_GMCache_DBQueue inDatabase:^(FMDatabase * _Nonnull db) {
        FMResultSet * resultSet=[db executeQuery:@"select directory,subpath,cache_age,disk_limit,mem_limit,count_limit from gm_caches where identifier=?",identifier];
        if (resultSet && [resultSet next]) {
            rst=YES;
            directory=[resultSet longForColumnIndex:0];
            subPath=[resultSet stringForColumnIndex:1];
            cache_age=[resultSet longForColumnIndex:2];
            disk_limit=[resultSet longForColumnIndex:3];
            mem_limit=[resultSet longForColumnIndex:4];
            count_limit=[resultSet longForColumnIndex:5];
            [resultSet close];
        }
    }];
    if (rst) {
        GMCache * cache=[[GMCache alloc] initWithIdentifier:identifier directory:directory subPath:subPath];
        cache.diskLimit=disk_limit;
        cache.memoryLimit=mem_limit;
        cache.cacheAge=cache_age;
        cache.countLimit=count_limit;
        return cache;
    }
    return nil;
}

#pragma -mark open database and initialize default data

+ (BOOL)openDB {
    NSString * dbPath=[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
    if (dbPath.length>0) {
        dbPath=[dbPath stringByAppendingPathComponent:GMCache_Caches_Default];
        ST_GMCache_DBQueue=[FMDatabaseQueue databaseQueueWithPath:dbPath];
        if (ST_GMCache_DBQueue) {
            NSString * initSql=@"CREATE TABLE IF NOT EXISTS gm_caches ( \
            identifier varchar(50) PRIMARY KEY not null,\
            directory INTEGER,\
            subpath text,\
            cache_age INTEGER,\
            disk_limit INTEGER,\
            mem_limit INTEGER,\
            count_limit INTEGER)";
            __block BOOL update=NO;
            [ST_GMCache_DBQueue inTransaction:^(FMDatabase * _Nonnull db, BOOL * _Nonnull rollback) {
                update=[db executeUpdate:initSql];
                if (!update){*rollback=YES;return;};
                FMResultSet * resultSet=[db executeQuery:@"select 1 from gm_caches where identifier=?",GMCache_Identifier_Default];
                if (!resultSet || !resultSet.next) {
                    [resultSet close];
                    if (![db executeUpdate:@"insert into gm_caches (identifier,directory,subpath,cache_age,disk_limit,mem_limit,count_limit) values(?,?,?,?,?,?)",GMCache_Identifier_Default,@(GMCache_Dicrectory_Default),GMCache_SubPath_Default?GMCache_SubPath_Default:@"",@(GMCache_CacheAge_Default),@(GMCache_DiskLimit_Default),@(GMCache_MemLimit_Default),@(GMCache_CountLimit_Default)]) {
                        *rollback=YES;
                        return;
                    }
                }
                update=YES;
            }];
            return update;
        }
    }
    return NO;
}

@end
