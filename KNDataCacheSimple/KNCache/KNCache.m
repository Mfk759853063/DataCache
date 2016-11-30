//
//  KNCache.m
//  KNDataCacheSimple
//
//  Created by hzdlapple2 on 16/1/8.
//  Copyright © 2016年 hzdlapple2. All rights reserved.
//

#import "KNCache.h"
#import "UIKit/UIKit.h"
// 一年
static const NSInteger kDefaultCacheMaxAge = 60 * 60 *24 * 7 * 52;

@interface KNCache ()

@property (strong, nonatomic) dispatch_queue_t ioQueue;
@property (strong, nonatomic) NSString *diskPath;
@property (assign, nonatomic) NSInteger maxCacheAge;
@property (strong, nonatomic) NSCache *memoryCache;
@property (strong, nonatomic) NSFileManager *fileManager;

@end

@implementation KNCache

+ (instancetype)shareCache {
    static dispatch_once_t onceToken;
    static KNCache *instance;
    dispatch_once(&onceToken, ^{
        instance = [self new];
    });
    
    return instance;
}

- (instancetype)init {
    return [self initWithNameSpace:@"KNCache"];
}

- (instancetype)initWithNameSpace:(NSString *)nameSpace {
    self = [super init];
    if (self) {
        // init path
        NSString *cacheDirectory = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
        self.ioQueue = dispatch_queue_create("com.kncache.ioqueue", DISPATCH_QUEUE_SERIAL);
        self.diskPath = [cacheDirectory stringByAppendingPathComponent:nameSpace];
        NSLog(@"KNCache DiskPath is %@ \n",self.diskPath);
        self.maxCacheAge = kDefaultCacheMaxAge;
        self.memoryCache = [[NSCache alloc] init];
        self.memoryCache.name = nameSpace;
        dispatch_async(self.ioQueue, ^{
            self.fileManager = [NSFileManager new];
        });
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(clearMemory)
                                                     name:UIApplicationDidReceiveMemoryWarningNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(backgroundCleanDisk)
                                                     name:UIApplicationDidEnterBackgroundNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)getSizeWithCompletionBlock:(KNCacheCompletionDataBlock)completion {
    dispatch_async(self.ioQueue, ^{
        unsigned long long size = 0;
        NSDirectoryEnumerator *fileEnumerator = [self.fileManager enumeratorAtPath:self.diskPath];
        for (NSString *name in fileEnumerator)
        {
            NSString *fileName = [self cacheFileName:name inDiskPath:self.diskPath];
            NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:fileName error:nil];
            size += [attrs fileSize];
        }
        completion?completion(@(size)):nil;
    });
    
}

- (NSString *)cacheFileName:(NSString *)fileName inDiskPath:(NSString *)diskPath {
    return [diskPath stringByAppendingPathComponent:fileName];
}

#pragma mark - Clear

- (void)backgroundCleanDisk {
    UIApplication *application = [UIApplication sharedApplication];
    __block UIBackgroundTaskIdentifier bgTask = [application beginBackgroundTaskWithExpirationHandler:^{
        [application endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
    }];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self clearDiskIfNeedClear];
    });
}

- (void)clearMemory {
    [self.memoryCache removeAllObjects];
}

- (void)clearDiskIfNeedClear {
    dispatch_async(self.ioQueue, ^{
        NSFileManager *fileManager = self.fileManager;
        NSURL *diskCacheUrl = [NSURL fileURLWithPath:self.diskPath isDirectory:YES];
        NSArray *propertyKeys = @[NSURLIsDirectoryKey,NSURLContentModificationDateKey,NSURLTotalFileAllocatedSizeKey];
        NSDirectoryEnumerator *fileEnumerator = [fileManager enumeratorAtURL:diskCacheUrl includingPropertiesForKeys:propertyKeys options:NSDirectoryEnumerationSkipsHiddenFiles errorHandler:nil];
        NSDate *expirationDate = [NSDate dateWithTimeIntervalSinceNow:-self.maxCacheAge];
        for (NSURL *fileUrl in fileEnumerator) {
            NSDictionary *resource = [fileUrl resourceValuesForKeys:propertyKeys error:nil];
            if ([resource[NSURLIsDirectoryKey] boolValue]) {
                continue;
            }
            NSDate *modificationDate = resource[NSURLContentModificationDateKey];
            if ([[modificationDate earlierDate:expirationDate] isEqualToDate:modificationDate]) {
                [fileManager removeItemAtURL:fileUrl error:nil];
                continue;
            }
        }
    });
}

- (void)clearAllDiskData {
    dispatch_async(self.ioQueue, ^{
        [self.fileManager removeItemAtPath:self.diskPath error:nil];
        [[NSFileManager defaultManager] createDirectoryAtPath:self.diskPath
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:NULL];
    });
}

- (void)clearDataWithCompletionBlock:(KNCacheCompletionVoidBlock)completion {
    [self clearMemory];
    dispatch_async(self.ioQueue, ^{
        [self clearAllDiskData];
        completion?completion():nil;
    });
}

#pragma mark - delete

- (void)deleteDataForKey:(NSString *)key {
    if (key) {
        [self.memoryCache removeObjectForKey:key];
    }
    dispatch_async(self.ioQueue, ^{
        NSString *filePath = [self cacheFileName:key inDiskPath:self.diskPath];
        if (filePath) {
            [self.fileManager removeItemAtPath:filePath error:nil];
        }
    });
}

#pragma mark - store

- (void)saveData:(id)data forKey:(NSString *)key {
    [self saveData:data forKey:key completion:nil toDisk:YES];
}

- (void)saveData:(id)data forKey:(NSString *)key useBlock:(KNCacheCompletionVoidBlock)completion {
    [self saveData:data forKey:key completion:completion toDisk:YES];
}

- (void)saveData:(id<NSCoding>)data forKey:(NSString *)key completion:(KNCacheCompletionVoidBlock)completion toDisk:(BOOL)toDisk {
    if (!data) {
        return;
    }
    [self.memoryCache setObject:data forKey:key];
    if (toDisk) {
        dispatch_async(self.ioQueue, ^{
            NSData *fileData = [NSKeyedArchiver archivedDataWithRootObject:data];
            if (![self.fileManager fileExistsAtPath:self.diskPath]) {
                [self.fileManager createDirectoryAtPath:self.diskPath withIntermediateDirectories:YES attributes:nil error:nil];
            }
            BOOL result = [self.fileManager createFileAtPath:[self cacheFileName:key inDiskPath:self.diskPath] contents:fileData attributes:nil];
            if (result && completion) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion();
                });
            }
        });
    }
}

#pragma mark - getData

- (id)dataForKey:(NSString *)key {
    id data = [self dataFromMemoryWithKey:key];
    if (data) {
        return data;
    }
    data = [self dataFromDiskWithKey:key];
    if (data) {
        [self.memoryCache setObject:data forKey:key];
    }
    return data;
}

- (id)dataFromMemoryWithKey:(NSString *)key {
    return [self.memoryCache objectForKey:key];
}

- (id)dataFromDiskWithKey:(NSString *)key {
    NSString *fileName = [self cacheFileName:key inDiskPath:self.diskPath];
    NSData *data = [NSData dataWithContentsOfFile:fileName];
    if (data) {
        id unArchiverData = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        return unArchiverData;
    }
    return nil;
}

@end
