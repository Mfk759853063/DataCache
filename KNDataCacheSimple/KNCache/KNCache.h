//
//  KNCache.h
//  KNDataCacheSimple
//
//  Created by hzdlapple2 on 16/1/8.
//  Copyright © 2016年 hzdlapple2. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^KNCacheCompletionVoidBlock)(void);
typedef void(^KNCacheCompletionDataBlock)(id data);

@interface KNCache : NSObject

+ (instancetype)shareCache;

- (void)saveData:(id)data forKey:(NSString *)key;

- (void)saveData:(id)data forKey:(NSString *)key useBlock:(KNCacheCompletionVoidBlock)completion;

- (id)dataForKey:(NSString *)key;

- (void)clearDataWithCompletionBlock:(KNCacheCompletionVoidBlock)completion;

- (void)getSizeWithCompletionBlock:(KNCacheCompletionDataBlock)completion;


@end
