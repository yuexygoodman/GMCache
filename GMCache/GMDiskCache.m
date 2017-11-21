//
//  GMDiskCache.m
//  GMCache
//
//  Created by Good Man on 2017/11/10.
//  Copyright © 2017年 Good Man. All rights reserved.
//

#import "GMDiskCache.h"
#import "FMDB.h"
#import "GMCacheSecurity.h"

@interface GMDiskCache ()
{
    NSString * _path;
    FMDatabaseQueue * _dbQueue;
}

@property(copy,nonatomic)NSString * secureKey;

@end

@implementation GMDiskCache

- (id)initWithIdentifier:(NSString *)identifier path:(NSString *)path {
    self=[self init];
    if (self) {
        _identifier=identifier;
        _path=path;
        _secureKey=[GMCacheSecurity secureKeyWithCacheIdentifier:_identifier];
        [self openDB];
    }
    return self;
}

- (BOOL)containsCacheKey:(NSString *)key {
    __block BOOL rst=NO;
    [_dbQueue inDatabase:^(FMDatabase * _Nonnull db) {
        FMResultSet * resultSet=[db executeQuery:@"select 1 from gm_cache where key=?",key];
        if (resultSet && resultSet.next) {
            rst=YES;
        }
        [resultSet close];
    }];
    return rst;
}

- (BOOL)cacheObject:(id) obj forKey:(NSString *) key {
    return [self cacheObject:obj forKey:key secured:self.secured];
}

- (BOOL)cacheObject:(id)obj forKey:(NSString *)key secured:(BOOL)secured {
    NSData * data=[NSKeyedArchiver archivedDataWithRootObject:obj];
    if (secured) {
        data=[GMCacheSecurity secureValue:data withKey:self.secureKey];
    }
    if (data) {
        __block BOOL rst;
        [_dbQueue inTransaction:^(FMDatabase * _Nonnull db, BOOL * _Nonnull rollback) {
            FMResultSet * resultSet=[db executeQuery:@"select * from gm_cache where key=?",key];
            if (resultSet && resultSet.next) {
                rst=[db executeUpdate:@"update gm_cache set value=?,update_time=?,secured=?,size=?",data,[NSDate new],@(secured),@(data.length)];
            }
            else {
                rst=[db executeUpdate:@"insert into gm_cache (key,value,secured,create_time,size) values(?,?,?,?,?)",key,data,@(secured),[NSDate new],@(data.length)];
            }
            [resultSet close];
        }];
        return rst;
    }
    return NO;
}

- (id)objectForCacheKey:(NSString *) key {
    __block id object=nil;
    [_dbQueue inDatabase:^(FMDatabase * _Nonnull db) {
        FMResultSet * resultSet=[db executeQuery:@"select * from gm_cache where key=?",key];
        if (resultSet && resultSet.next) {
            NSData * data=[resultSet dataForColumnIndex:1];
            BOOL secured=[resultSet boolForColumnIndex:2];
            if (secured) {
                data=[GMCacheSecurity unSecureValue:data withKey:self.secureKey];
            }
            if (data) {
                object=[NSKeyedUnarchiver unarchiveObjectWithData:data];
            }
            [db executeUpdate:@"update gm_cache set access_time=? where key=?",[NSDate new],key];
        }
        [resultSet close];
    }];
    return object;
}

- (BOOL)deleteObjectForCacheKey:(NSString *) key {
    __block BOOL rst;
    [_dbQueue inDatabase:^(FMDatabase * _Nonnull db) {
        rst=[db executeUpdate:@"delete from gm_cache where key=?",key];
    }];
    return rst;
}

- (BOOL)removeAllObjects {
    __block BOOL rst;
    [_dbQueue inDatabase:^(FMDatabase * _Nonnull db) {
        rst=[db executeUpdate:@"delete from gm_cache"];
    }];
    return rst;
}

- (BOOL)openDB {
    _dbQueue=[FMDatabaseQueue databaseQueueWithPath:[self dbPath]];
    if (_dbQueue) {
        NSString * initSql=@"CREATE TABLE IF NOT EXISTS gm_cache (\
        key varchar(50) PRIMARY KEY not null,\
        value BLOB,\
        secured BOOLEAN,\
        create_time DATE not null,\
        update_time DATE,\
        access_time DATE,\
        size INTEGER)";
        __block BOOL rst;
        [_dbQueue inDatabase:^(FMDatabase * _Nonnull db) {
            rst=[db executeUpdate:initSql];
        }];
        return rst;
    }
    return NO;
}

- (NSString *)dbPath {
    if (![[NSFileManager defaultManager] fileExistsAtPath:self.path isDirectory:NULL]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:self.path withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSString * fullPath=[[self.path stringByAppendingPathComponent:_identifier] stringByAppendingString:@".db"];
    return fullPath;
}

@end
