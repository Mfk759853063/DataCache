//
//  ViewController.m
//  KNDataCacheSimple
//
//  Created by hzdlapple2 on 16/1/8.
//  Copyright © 2016年 hzdlapple2. All rights reserved.
//

#import "ViewController.h"
#import "KNCache.h"

@interface ViewController () <UITableViewDelegate,UITableViewDataSource>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    UITableView *t = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    t.delegate =self;
    t.dataSource = self;
    [self.view addSubview:t];
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"test" ofType:@"png"];
    NSData *data = [NSData dataWithContentsOfFile:filePath];
    for (int i = 0; i< 1000; i++) {
        [[KNCache shareCache] saveData:data forKey:@(i).stringValue];
    }
    [[KNCache shareCache] getSizeWithCompletionBlock:^(id data) {
        NSLog(@"data %@",data);
    }];
    [[KNCache shareCache] clearDataWithCompletionBlock:nil];

    
    
}

#pragma mark - TableViewDelegate && Datasource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 100;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"cellIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
