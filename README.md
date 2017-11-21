# GMCache
一、GMCache是一个用于IOS应用程序存储应用数据的库，它具有以下特定：  
1、有内存缓存和物理缓存两级缓存机制，不需要每次都去查询数据库，减少了I/O操作。    
2、物理存储基于sqlite数据库，使用了开源的FMDataBase，方便数据的管理。    
3、增删改查是线程安全的。  
4、提供了安全存储的机制，使用者可以通过secured参数来设置当前要存储的数据是否需要加密，GMCache对应每一份缓存都会随机生成一个密钥，密钥放在钥匙串中，使用者每次存储敏感信息，数据都会通过密钥进行AES256加密，然后安全的存储在sqlite数据库中。  
5、支持NSValue,NSString,NSArray,NSDictionary等,及实现了NSCoding协议的所有自定义对象。  
  
二、基本的使用  
可以通过[GMCache defaultCache]获取库中默认的缓存，也可以通过以下方式自定义缓存：  
`[[GMCache alloc] initWithIdentifier:@"my cache identifier"];`    
`[[GMCache alloc] initWithIdentifier:@"my cache identifier" directory:@"NSSearchDirectory Enum" subPath:@"my subdirectory"];`      

1、保存数据   
 `[[GMCache defaultCache] cacheObject:@"my object" forKey:@"my key"];//数据存储在内存缓存中和数据库中`   
 `[[GMCache defaultCache] cacheObject:@"my object" forKey:@"my key" toDisk:NO];//数据只存储到了内存缓存中`        
 `[[GMCache defaultCache] cacheObject:@"my object" forKey:@"my key" secured:YES];//数据存储在内存缓存中，并在加密后存储到数据库中`   
2、获取数据   
 `[[GMCache defaultCache] objectForCacheKey:@"my key"];`   
3、判断是否存在   
 `[[GMCache defaultCache] containsCacheKey:@"my key"];`    
4、删除数据   
`[[GMCache defaultCache] deleteObjectForCacheKey:@"my key"];`   
 `[[GMCache defaultCache] removeAllObjects];`   
   
三、后续   
1、会考虑增加文件存储的方式，来存储较大的文件，而不是直接存储到数据库中。   
2、会考虑增加存储时间、内存花销、物理缓存花销、存储数据总数等限制。   
3、会考虑增加cache迁移和自动清理等功能。   
4、其它有用的优化。   

