//
//  RXPlayer.m
//  RXAvplayer
//
//  Created by srx on 2017/6/27.
//  Copyright © 2017年 https://github.com/srxboys. All rights reserved.
//

#import "RXPlayer.h"

@implementation RXPlayer
+ (Class)layerClass {
    return [AVPlayerLayer class];
}

- (AVPlayer *)player {
    return [(AVPlayerLayer *)[self layer] player];
}

- (void)setPlayer:(AVPlayer *)player {
    [(AVPlayerLayer *)[self layer] setPlayer:player];
}
@end
