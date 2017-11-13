//
//  GMKeyChain.h
//  GMCache
//
//  Created by Good Man on 2017/11/13.
//  Copyright © 2017年 Good Man. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GMKeyChain : NSObject

+ (void)saveObject:(id)obj forKey:(NSString *)key;

+ (id)objectForKey:(NSString *)key;

@end
