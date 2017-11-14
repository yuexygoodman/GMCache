//
//  GMCacheProvider.h
//  GMCache
//
//  Created by Good Man on 2017/11/10.
//  Copyright © 2017年 Good Man. All rights reserved.
//

#import "GMCache.h"

@interface GMCacheProvider : NSObject

+ (BOOL)containsCacheIdentifier:(NSString *)identifier;

+ (GMCache *)cacheWithIdentifier:(NSString *)identifier;

+ (BOOL)saveCache:(GMCache *)cache;

@end
