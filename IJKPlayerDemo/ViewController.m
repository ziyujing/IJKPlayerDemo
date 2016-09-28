//
//  ViewController.m
//  IJKPlayerDemo
//
//  Created by qx_mjn on 16/9/26.
//  Copyright © 2016年 qx_mjn. All rights reserved.
//

#import "ViewController.h"
#import "ZFTableViewController.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    ZFTableViewController *vc = [[ZFTableViewController alloc] init];
    [self presentViewController:vc animated:YES completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
