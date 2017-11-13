//
//  GMCacheSecurity.m
//  GMCache
//
//  Created by Good Man on 2017/11/10.
//  Copyright © 2017年 Good Man. All rights reserved.
//

#import "GMCacheSecurity.h"
#import <Security/Security.h>

@implementation GMCacheSecurity

#pragma -mark public methods

+ (NSString *)secureKeyWithCacheIdentifier:(NSString *)identifier {
    return nil;
}

+ (NSData *)secureValue:(NSData *)data withKey:(NSString *)secureKey {
    return nil;
}

+ (NSData *)unSecureValue:(NSData *)data withKey:(NSString *)secureKey {
    return nil;
}

#pragma -mark generate a random AES key

+ (NSString *)generatedAESKeyWithIdentifier:(NSString *)identifer {
    return nil;
}

#pragma -mark acess keychain

+ (NSDictionary *)keyChainSettingWithIdentifier:(NSString *)identifier {
    NSMutableDictionary *keyChainQueryDictaionary = [[NSMutableDictionary alloc]init];
    [keyChainQueryDictaionary setObject:(id)kSecClassGenericPassword forKey:(id)kSecClass];
    [keyChainQueryDictaionary setObject:identifier forKey:(id)kSecAttrService];
    [keyChainQueryDictaionary setObject:@"security.GMCache.goodman" forKey:(id)kSecAttrAccount];
    return keyChainQueryDictaionary;
}

+ (void)saveData:(NSData *) data forIdentifier:(NSString *)identifier {
    
}

+ (NSData *)getDataWithIdentifier:(NSString *)identifier {
    return nil;
}

@end
