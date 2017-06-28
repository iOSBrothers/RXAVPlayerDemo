//
//  ViewController.m
//  RXAvplayer
//
//  Created by srx on 2017/6/27.
//  Copyright © 2017年 https://github.com/srxboys. All rights reserved.
//

#import "ViewController.h"
#import "RXPlayerView.h"
#import "UIView+Addition.h"

@interface ViewController ()
{
    RXPlayerView * _playView;//默认是strong类型
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    _playView = [[RXPlayerView alloc] initWithFrame:CGRectMake(0, 40, self.view.width, self.view.height/3.0)];
    [_playView setPlayerURL:@"http://c00.app.live.readtv.cn/ghs.m3u8"];
    [self.view addSubview:_playView];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
