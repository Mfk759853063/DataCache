
##DataCache?
一个缓存类，支持缓存自定义对象

##如何使用？
```
NSData *data = [NSData dataWithContentsOfFile:filePath];
for (int i = 0; i< 1000; i++) {
    [[KNCache shareCache] saveData:data forKey:@(i).stringValue];
}
[[KNCache shareCache] getSizeWithCompletionBlock:^(id data) {
    NSLog(@"data %@",data);
}];
[[KNCache shareCache] clearDataWithCompletionBlock:nil];
```
##参考SDImageCache的做法，感谢@SDImageCache