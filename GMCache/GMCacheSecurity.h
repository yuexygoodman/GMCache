//
//  GMCacheSecurity.h
//  GMCache
//
//  Created by Good Man on 2017/11/10.
//  Copyright © 2017年 Good Man. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GMCacheSecurity : NSObject

+ (NSString *)secureKeyWithCacheIdentifier:(NSString *)identifier;

+ (NSData *)secureValue:(NSData *)data withKey:(NSString *)secureKey;

+ (NSData *)unSecureValue:(NSData *)data withKey:(NSString *)secureKey;

@end
