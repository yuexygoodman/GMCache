//
//  GMCacheSecurity.m
//  GMCache
//
//  Created by Good Man on 2017/11/10.
//  Copyright © 2017年 Good Man. All rights reserved.
//

#import "GMCacheSecurity.h"
#import <Security/Security.h>
#import <CommonCrypto/CommonCrypto.h>

@implementation GMCacheSecurity

#pragma -mark public methods

+ (NSString *)secureKeyWithCacheIdentifier:(NSString *)identifier {
    if (![identifier isKindOfClass:[NSString class]] || identifier.length==0)return nil;
    NSString * secureKey=[self getKeyWithIdentifier:identifier];
    if (secureKey.length==0) {
        secureKey=[self generatedAESKey];
        [self saveKey:secureKey forIdentifier:identifier];
    }
    return secureKey;
}

+ (NSData *)secureValue:(NSData *)data withKey:(NSString *)secureKey {
    if (![data isKindOfClass:[NSData class]]
        || data.length==0
        || ![secureKey isKindOfClass:[NSString class]]
        || secureKey.length==0)return nil;
    return [self encryptWithData:data key:secureKey];
}

+ (NSData *)unSecureValue:(NSData *)data withKey:(NSString *)secureKey {
    if (![data isKindOfClass:[NSData class]]
        || data.length==0
        || ![secureKey isKindOfClass:[NSString class]]
        || secureKey.length==0)return nil;
    return [self decryptWithData:data key:secureKey];
}

#pragma -mark AES 256

+ (NSString *)generatedAESKey {
    char aesKey[32];
    for (int i=0; i<32; i++) {
        int num=arc4random()%93+33;
        aesKey[i]=num;
        i++;
    }
    return [NSString stringWithCString:aesKey encoding:NSUTF8StringEncoding];
}

+ (NSData *)encryptWithData:(NSData *)data key:(NSString *)secureKey {
    char keyPtr[kCCKeySizeAES256+1];
    bzero(keyPtr, sizeof(keyPtr));
    [secureKey getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF8StringEncoding];
    NSUInteger dataLength = [data length];
    size_t bufferSize = dataLength + kCCBlockSizeAES128;
    void *buffer = malloc(bufferSize);
    const void *vkey = keyPtr;
    const void *iv = (const void *) keyPtr; //
    size_t numBytesEncrypted = 0;
    CCCryptorStatus cryptStatus = CCCrypt(kCCEncrypt, kCCAlgorithmAES128,
                                          kCCOptionPKCS7Padding | kCCOptionECBMode,
                                          vkey,
                                          kCCKeySizeAES256,
                                          iv,
                                          [data bytes],
                                          dataLength,
                                          buffer,
                                          bufferSize,
                                          &numBytesEncrypted);
    if (cryptStatus == kCCSuccess) {
        return [NSData dataWithBytesNoCopy:buffer length:numBytesEncrypted];
    }
    free(buffer);
    return nil;
}

+ (NSData *)decryptWithData:(NSData *)data key:(NSString *)secureKey {
    char keyPtr[kCCKeySizeAES256+1];
    bzero(keyPtr, sizeof(keyPtr));
    
    [secureKey getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF8StringEncoding];
    
    NSUInteger dataLength = [data length];
    
    size_t bufferSize = dataLength + kCCBlockSizeAES128;
    void *buffer = malloc(bufferSize);
    const void *vkey = keyPtr;
    const void *iv = (const void *) keyPtr; //
    size_t numBytesDecrypted = 0;
    CCCryptorStatus cryptStatus = CCCrypt(kCCDecrypt,
                                          kCCAlgorithmAES128,
                                          kCCOptionPKCS7Padding | kCCOptionECBMode,
                                          vkey,
                                          kCCKeySizeAES256,
                                          iv,
                                          [data bytes],
                                          dataLength,
                                          buffer,
                                          bufferSize,
                                          &numBytesDecrypted);
    if (cryptStatus == kCCSuccess) {
        return [NSData dataWithBytesNoCopy:buffer length:numBytesDecrypted];
    }
    free(buffer);
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

+ (void)saveKey:(NSString *)key forIdentifier:(NSString *)identifier {
    
}

+ (NSString *)getKeyWithIdentifier:(NSString *)identifier {
    return nil;
}

@end
