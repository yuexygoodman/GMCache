//
//  GMDiskCache.m
//  GMCache
//
//  Created by Good Man on 2017/11/10.
//  Copyright © 2017年 Good Man. All rights reserved.
//

#import "GMDiskCache.h"
#import <FMDB/FMDB.h>
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
        [self openDB];
    }
    return self;
}

- (NSString *)secureKey {
    if (!_secureKey) {
        _secureKey=[GMCacheSecurity secureKeyWithCacheIdentifier:self.identifier];
    }
    return _secureKey;
}

- (BOOL)containsCacheKey:(NSString *)key {
    __block BOOL rst=NO;
    [_dbQueue inDatabase:^(FMDatabase * _Nonnull db) {
        FMResultSet * resultSet=[db executeQuery:@"select 1 from gm_cache where key=?",key];
        if (resultSet && resultSet.next) {
            rst=YES;
            [resultSet close];
        }
    }];
    return rst;
}

- (BOOL)cacheObject:(id) obj forKey:(NSString *) key {
    return [self cacheObject:obj forKey:key secured:NO];
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
                [resultSet close];
                rst=[db executeUpdate:@"update gm_cache set value=?,access_time=?,secured=?",data,[NSDate new],@(secured)];
            }
            else {
                rst=[db executeUpdate:@"insert into gm_cache (key,value,secured,create_time) values(?,?,?,?)",key,data,@(secured),[NSDate new]];
            }
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
            NSDate * create_time=[resultSet dateForColumnIndex:3];
            [resultSet close];
            if ([[NSDate dateWithTimeInterval:self.cacheAge sinceDate:create_time] compare:[NSDate new]]==NSOrderedAscending) {
                if (secured) {
                    data=[GMCacheSecurity unSecureValue:data withKey:self.secureKey];
                }
            }
            if (data) {
                object=[NSKeyedUnarchiver unarchiveObjectWithData:data];
            }
        }
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
        access_time DATE)";
        __block BOOL rst;
        [_dbQueue inDatabase:^(FMDatabase * _Nonnull db) {
            rst=[db executeUpdate:initSql];
        }];
        return rst;
    }
    return NO;
}

- (NSString *)dbPath {
    NSString * fullPath=[[self.path stringByAppendingPathComponent:_identifier] stringByAppendingString:@".db"];
    return fullPath;
}

@end
