//
//  RXPlayerView.m
//  RXAvplayer
//
//  Created by srx on 2017/6/27.
//  Copyright © 2017年 https://github.com/srxboys. All rights reserved.
//

#import "RXPlayerView.h"

#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>

#import "RXPlayer.h"
#import "UIView+Addition.h"


#define showHiddenControllIntervel 0.3
#define blackViewAlpha 0.7

#define NavHeight 64
#define SystemStatusHeight [[UIApplication sharedApplication] statusBarFrame].size.height

#define PlayMutedButtonWidth 24 //声音 播放按钮
#define PlayMutedButtonHeight 23 //声音 播放按钮
#define PlayMutedButtonLeft 20 //声音 播放按钮

#define PlayScreenWidthHeight 20//全屏按钮 宽度==高度
#define PlayScreenRight 20//全屏按钮 距离 右边、下边
#define PlayScreenBottom 15
#define PlayActivityWidthHeight 37 //菊花 宽==高

@interface RXPlayerView ()
{
    UIView           * _shadeView;//亮度遮罩层
    UIView           * _backView;//点击全面遮罩层
    UIImageView      * _player_bottom_bg;//底部按钮黑条//750x152
    
    BOOL              _isShowControl; //返回、暂停、全屏按钮是否显示
    
    /** 按钮 */
    UIButton         * _backButton; //返回按钮
    UIButton         * _playOrPauseButton; //暂停
    UIButton         * _screenButton;//全屏
    UIButton         * _mutedButton;//静音🔇按钮
    
    /** 音量 */
    UIView           * _leftView; //亮度调节
    UIView           * _rightView; //音量控制
    CGPoint            _beginPoint;
    UISlider         * _sysVolumeSlider;
    
    /** 针对网络状态 */
    UILabel          * _errorLabel;
    UILabel          * _activityLabel;//正在努力加载中~~
    UIActivityIndicatorView * _activityView;
    
}
@property (nonatomic ,strong) AVPlayer *player;
@property (nonatomic ,strong) AVPlayerItem *playerItem;//播放对列  //播放内容 //playerItem是管理资源的对象
@property (nonatomic, strong) RXPlayer * playerView;//播放器

@end

@implementation RXPlayerView
#pragma mark - ~~~~~~~~~~~ 基本设置 ~~~~~~~~~~~~~~~
/** 重写初始化 */
- (instancetype)init {
   self = [super init];
    if(self) {
        [self configUI];
    }
    return self;
}
- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self configUI];
        [self changeUIFrame];
    }
    return self;
}

/** 重写frame */
- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    [self changeUIFrame];
}
/** 初始化 子控件 */
- (void)configUI {
    _playerView = [[RXPlayer alloc] init];
    [self addSubview:_playerView];
    
    _shadeView = [[UIView alloc] initWithFrame:CGRectZero];
    _shadeView.backgroundColor = [UIColor blackColor];
    _shadeView.alpha = 0;
    [self addSubview:_shadeView];
    
    //遮罩图片
    _backView = [[UIView alloc] initWithFrame:CGRectZero];
    _backView.backgroundColor = [UIColor blackColor];
    _backView.alpha = 0;
    [self addSubview:_backView];
    
    //双击 暂停、播放 操作
    UITapGestureRecognizer * tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGustureAction:)];
    //设置当前需要点击的次数
    tap.numberOfTapsRequired = 2;
    //设置当前需要触发事件的手指数量
    tap.numberOfTouchesRequired = 1;
    [self addGestureRecognizer:tap];
    
    //手势区域--亮度调节
    _leftView = [[UIView alloc] initWithFrame:CGRectZero];
    _leftView.backgroundColor = [UIColor clearColor];
    [self addSubview:_leftView];
    //手势区域--音量调节
    _rightView = [[UIView alloc] initWithFrame:CGRectZero];
    _rightView.backgroundColor = [UIColor clearColor];
    [self addSubview:_rightView];
    
    _player_bottom_bg = [[UIImageView alloc] init];
    _player_bottom_bg.alpha = 0;
    _player_bottom_bg.image = [UIImage imageNamed:@"player_bottom_bg"];
    [self addSubview:_player_bottom_bg];
    
    //返回
    _backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _backButton.frame = CGRectMake(0, SystemStatusHeight + (NavHeight - SystemStatusHeight - 30)/2.0, 30 + 20, 30);
    _backButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    _backButton.contentVerticalAlignment = UIControlContentVerticalAlignmentTop;
    _backButton.hidden = YES;
    _backButton.alpha = 0;
    [_backButton setImage:[UIImage imageNamed:@"nav_arrow"] forState:UIControlStateNormal];
    [_backButton addTarget:self action:@selector(closeFullScreenButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_backButton];
    //暂停
    _playOrPauseButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_playOrPauseButton setImage:[UIImage imageNamed:@"player_btn"] forState:UIControlStateNormal];
    _playOrPauseButton.alpha = 0;
    _playOrPauseButton.hidden = YES;
    _playOrPauseButton.frame = CGRectMake(0, 0, 60, 60);
    //player_btn
    [self addSubview:_playOrPauseButton];
    [_playOrPauseButton addTarget:self action:@selector(playOrPauseButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    
    _errorLabel = [[UILabel alloc] init];
    _errorLabel.textColor = [UIColor whiteColor];
    _errorLabel.font = [UIFont systemFontOfSize:12];
    _errorLabel.textAlignment = NSTextAlignmentCenter;
    _errorLabel.hidden = YES;
    [self addSubview:_errorLabel];
    
    _activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    [self addSubview:_activityView];
    
    //全屏按钮
    _screenButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_screenButton setImage:[UIImage imageNamed:@"player_screen_btn"] forState:UIControlStateNormal];
    [_screenButton setImage:[UIImage imageNamed:@"player_screen_btn"] forState:UIControlStateHighlighted];
    _screenButton.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    _screenButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    _screenButton.alpha = 0;
    [self addSubview:_screenButton];
    [_screenButton addTarget:self action:@selector(screenButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    
    _mutedButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_mutedButton setImage:[UIImage imageNamed:@"player_muted_on"] forState:UIControlStateNormal];
    [_mutedButton setImage:[UIImage imageNamed:@"player_muted_off"] forState:UIControlStateSelected];
    _mutedButton.alpha = 0;
    [_mutedButton addTarget:self action:@selector(mutedButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_mutedButton];
    
#pragma mark ------声音控制处理-------
    MPVolumeView *volumView = [[MPVolumeView alloc] init];
    
    for (UIView *view in [volumView subviews])
        {
        if ([NSStringFromClass([view class]) isEqualToString:@"MPVolumeSlider"]) {
            _sysVolumeSlider = (UISlider *)view;
        }
        }
    
    // 使用这个category的应用不会随着手机静音键打开而静音，可在手机静音下播放声音
    NSError *setCategoryError = nil;
    BOOL success = [[AVAudioSession sharedInstance]
                    setCategory: AVAudioSessionCategoryPlayback
                    error: &setCategoryError];
    if (!success) { /* handle the error in setCategoryError */ }
    
    // 监听耳机插入和拔掉通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioRouteChangeListenerCallback:) name:AVAudioSessionRouteChangeNotification object:nil];
}
/** 子控件设置frame */
- (void)changeUIFrame {
    _shadeView.frame = self.bounds;
    _playerView.frame = CGRectMake(0, 0, self.width, self.height);
    
    UIImage* img=[UIImage imageNamed:@"player_bottom_bg"];//原图并拉伸
    UIEdgeInsets edge=UIEdgeInsetsMake(0, 0, 1,76);
    img= [img resizableImageWithCapInsets:edge resizingMode:UIImageResizingModeStretch];
    _player_bottom_bg.image=img;
    _player_bottom_bg.frame = CGRectMake(0, self.height - 76, self.width, 76);
    
    _backView.frame = CGRectMake(0, 0, self.width, self.height);
    
    _leftView.frame = CGRectMake(0, 0, self.width/2.0, self.height);
    _rightView.frame = CGRectMake(self.width/2.0, 0, self.width/2.0, self.height);
    _playOrPauseButton.center = CGPointMake(self.width/2.0, self.height/2.0 - 4);
    _errorLabel.frame = CGRectMake(0, (self.height - 14)/2.0, self.width, 14);
    
    
    _activityView.center = CGPointMake(self.width/2.0, self.height/2.0);
    
    _screenButton.frame = CGRectMake(self.width - PlayMutedButtonWidth - PlayScreenWidthHeight * 2,
                                     self.height - PlayScreenWidthHeight - PlayScreenBottom * 2,
                                     PlayScreenWidthHeight + PlayScreenRight * 2,
                                     PlayScreenWidthHeight + PlayScreenBottom * 2);
    _mutedButton.frame = CGRectMake(0, (self.height - PlayMutedButtonHeight - PlayScreenBottom * 2), PlayMutedButtonWidth + PlayMutedButtonLeft * 2, PlayMutedButtonHeight + PlayScreenBottom * 2);
    
    _sysVolumeSlider.minimumValue = 0;
    _sysVolumeSlider.maximumValue = self.height/2.0;
}

/** 播放  */
- (void)play {
    
}
/** 暂停、销毁 */
- (void)stop {
    
}


- (void)mutedButtonClick {
    _mutedButton.selected = !_mutedButton.selected;
    self.player.muted = _mutedButton.selected;
    
    if(_playClickVoiceChangeBlock) {
        _playClickVoiceChangeBlock(self.player.muted);
    }
}
- (void) closeFullScreenButtonClick {
//    UIDevice *device = [UIDevice currentDevice];
//    
//    UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
//    UIInterfaceOrientation interfaceOrientation = (UIInterfaceOrientation)orientation;
//    if (interfaceOrientation == UIInterfaceOrientationLandscapeLeft ||interfaceOrientation ==  UIInterfaceOrientationLandscapeRight ||interfaceOrientation == UIDeviceOrientationFaceUp) {
//        if(_playClickScreenWillChangeBlock) {
//            _playClickScreenWillChangeBlock();
//        }
//        [device setValue:[NSNumber numberWithInteger:UIInterfaceOrientationPortrait] forKey:@"orientation"];
//        if(_playFullScreenClickBlock) {
//            _playFullScreenClickBlock(PlayerScreenVertical);
//        }
//        [self setVerticalScreen];
//    }
}
//设置横竖屏
- (void)screenButtonClick:(id)sender {
    NSLog(@"点击了 全屏");
}
- (void)playOrPauseButtonClick:(UIButton *)sender {
    NSLog(@"点击了 播放、暂停按钮");
}

- (void)tapGustureAction:(UITapGestureRecognizer *)tap {
    [self playOrPauseButtonClick:nil];
    //只能取消 不带参数的
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self showControl];
}

/** 设置播放源 */
- (void)setPlayerURL:(NSString *)url {
    _playerURL = url;
    //...
    [self allowGotoPlay];
}

/** 根据网络状态 是否允许播放->wifi */
- (void)allowGotoPlay {
    ///...
    [self settingPlayParameter];
}

/// 播放 UI...
- (void)playerUIToPlay {
    [_player play];
    _backView.alpha = 0;
    _playerStatus = PlayerStatusPlay;
    _playOrPauseButton.hidden = NO;
    
    [_activityView stopAnimating];
    _activityView.hidden = YES;
    
    [_playOrPauseButton setImage:[UIImage imageNamed:@"player_pause"] forState:UIControlStateNormal];
    
    _errorLabel.hidden = YES;
}
/// 暂停 UI...
- (void)playerUIToPause {
    [_player pause];
    _backView.alpha = blackViewAlpha;
    _playerStatus = PlayerStatusStop;
    
    [_activityView stopAnimating];
    _activityView.hidden = YES;
    
    _playOrPauseButton.hidden = NO;
    [_playOrPauseButton setImage:[UIImage imageNamed:@"player_btn"] forState:UIControlStateNormal];
}
/// 等待 UI...
- (void)playerUIToWiting {
    //开始等待
    [_player pause];
    _backView.alpha = blackViewAlpha;
    _playerStatus = PlayerStatusStop;
    _playOrPauseButton.hidden = YES;
    [_playOrPauseButton setImage:[UIImage imageNamed:@"player_btn"] forState:UIControlStateNormal];
    
    [_activityView startAnimating];
    _activityView.hidden = NO;
    
    _errorLabel.hidden = YES;
}
/// 播放error UI...
- (void)playerUIToError {
    _backView.alpha = blackViewAlpha;
    _playOrPauseButton.hidden = NO;
    [_playOrPauseButton setImage:[UIImage imageNamed:@"player_btn"] forState:UIControlStateNormal];
    _activityView.hidden = YES;
    _errorLabel.hidden = NO;
}

/** 全屏 */
- (void)setFullScreen {
    
}
/** 竖屏 */
- (void)setVerticalScreen {
    
}

/** 隐藏UI-animal */
- (void)hiddenControl {
    _isShowControl = NO;
    
    _screenButton.hidden = NO;
    if(_playerScreen == PlayerScreenFull) {
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
    }
    else {
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];
    }
    
    [UIView animateWithDuration:showHiddenControllIntervel animations:^{
        _playOrPauseButton.alpha = 0;
        _screenButton.alpha = 0;
        _backButton.alpha = 0;
        _player_bottom_bg.alpha = 0;
        _mutedButton.alpha = 0;
        
    } completion:^(BOOL finished) {
        //隐藏控件
        [self performSelector:@selector(hiddenControl) withObject:nil afterDelay:5];
    }];
}
/** 显示UI-animal */
- (void)showControl {
    //取消 动画
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hiddenControl) object:nil];
    _isShowControl = YES;
    //    _playOrPauseButton.hidden = _isPlayWiting;
    _screenButton.hidden = NO;
    
    if(_playerScreen == PlayerScreenFull) {
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];
    }
    
    [UIView animateWithDuration:showHiddenControllIntervel animations:^{
        _playOrPauseButton.alpha = 1;
        _screenButton.alpha = 1;
        _backButton.alpha = 1;
        _player_bottom_bg.alpha = 1;
        _mutedButton.alpha = 1;
        
    } completion:^(BOOL finished) {
        //隐藏控件
        [self performSelector:@selector(hiddenControl) withObject:nil afterDelay:5];
    }];
}

/** 音量控制 */
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    //取消 延迟执行函数的种种 //只能取消 不带参数的
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    if(event.allTouches.count == 1) {
        
        _isShowControl = !_isShowControl;
        
        if(_isShowControl) {
            [self showControl];
        }
        else {
            [self hiddenControl];
        }
    }
    
    UITouch *touch = [touches anyObject];
    _beginPoint = [touch locationInView:_rightView];
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint selfPoint = [touch locationInView:self];
    CGPoint point = [touch locationInView:_rightView];
    CGRect volumRect = _rightView.frame;
    
    CGPoint lightPoint = [touch locationInView:_leftView];
    CGRect lightRect = _leftView.frame;
    
    if(CGRectContainsPoint(volumRect, selfPoint)) {
        CGFloat beginY = _beginPoint.y;
        CGFloat nowY = point.y;
        if(ABS(nowY - beginY) > 5) {
            if(nowY < beginY) {
                _sysVolumeSlider.value += 0.02;
            }
            else {
                _sysVolumeSlider.value -= 0.02;
            }
        }
    }
    
    if(CGRectContainsPoint(lightRect, lightPoint)) {
        CGFloat beginY = _beginPoint.y;
        CGFloat nowY = point.y;
        if(ABS(nowY - beginY) > 5) {
            CGFloat alpha = _shadeView.alpha;
            if(nowY < beginY) {
                alpha -= 0.02;
            }
            else {
                alpha += 0.02;
            }
            if(alpha >= 0.8) {
                alpha = 0.8;
            }
            else if(alpha <0) {
                alpha = 0;
            }
//            NSLog(@"alpha = %f", alpha);
            _shadeView.alpha = alpha;
        }
        
        //屏幕亮度
        //        [[UIScreen mainScreen] setBrightness:_sysVolumeSlider.value];
    }
    
    
}



/** 配置播放参数->然后就播放 */
- (void)settingPlayParameter {
    NSString * video = [_playerURL stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if(video.length <= 0) {
        return;
    }
    
    if (self.playerItem && !_playerDestroy) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:self.playerItem];
        [self.playerItem removeObserver:self forKeyPath:@"status"];
    }
    
    self.playerItem = [self getPlayItemWithURLString:video];
    
    if(self.player) {
        [self.player replaceCurrentItemWithPlayerItem:self.playerItem];
    }
    else {
        self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
        self.playerView.player = self.player;
    }
    //声音按钮在将要播放时 设置一下声音
    self.player.muted = _mutedButton.isSelected;
    
    
    
    [self.playerItem addObserver:self
                      forKeyPath:@"status"
                         options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                         context:nil];
    
    // 添加视频播放结束通知
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(moviePlayDidEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:self.playerItem];
    [self.playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
    
    [self.playerItem addObserver:self forKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionNew context:nil];
    [self.playerItem addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:nil];
    [self.playerItem addObserver:self forKeyPath:@"playbackBufferFull" options:NSKeyValueObservingOptionNew context:nil];
}

///
-(AVPlayerItem *)getPlayItemWithURLString:(NSString *)urlString{
    AVAsset *movieAsset  = [[AVURLAsset alloc]initWithURL:[NSURL URLWithString:urlString] options:nil];
    AVPlayerItem *playerItem = [[AVPlayerItem alloc] initWithAsset:movieAsset];
    return playerItem;
}

/// 直播的对于这个不存在
- (void)moviePlayDidEnd:(NSNotification *)notification {
}

//添加一个通知，用于监听视频是否已经播放完毕，然后实现KVO的方法：
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    
    AVPlayerItem * playerItem = (AVPlayerItem *)object;
    if(playerItem == nil) return;
    
    //status 和上面的一样  key
    if([keyPath isEqualToString:@"status"]) {
        if([playerItem status] == AVPlayerStatusReadyToPlay) {
            NSLog(@"AVPlayerStatusReadyToPlay 准备播放");
            [self playerUIToPlay];
            if(_playStatusPlayBlock) {
                _playStatusPlayBlock();
            }
        }
        else if([playerItem status] == AVPlayerStatusFailed) {
            NSLog(@"缓冲失败");
            [self playerUIToError];
            self.playerDestroy = YES;
            if(_playStatusPlayBlock) {
                _playStatusPlayBlock();
            }
        }
    }
    else if([keyPath isEqualToString:@"loadedTimeRanges"]) {
        // 计算缓冲进度
        NSTimeInterval timeInterval = [self availableDuration];
        //        NSLog(@"time interval:%f", timeInterval);
        
        if(isnan(timeInterval)) {
            [self playerUIToWiting];
        }
        
        CGFloat loadProgress = timeInterval;
        CMTime duration =[_player currentTime];
        ///当前播放的时间
        CGFloat second = duration.value/duration.timescale;
        
        
        if (loadProgress>second+5) {
            [self playerUIToPlay];
        }
        else if (loadProgress<=second+5) {
            [self playerUIToWiting];
        }
        
    }
    else if([keyPath isEqualToString:@"playbackBufferEmpty"]) {
        //        // 当缓冲是空的时候
        if (_playerItem.playbackBufferEmpty) {
            [self playerUIToWiting];
        }
        
        /*
         超过缓冲区域或者网断了，此时视频暂停，缓冲区域已缓冲完毕或者网络恢复继续播放
         */
        
    }
    //    else if([keyPath isEqualToString:@"playbackLikelyToKeepUp"]) {
    ////        NSLog(@"表示没有当财产playbackbufferfull表示是的。在这个事件中，播放缓冲区具有达到的能力，但有没有统计数据，以支持一个预测，播放很可能 保持。它是留给应用程序程序员决定继续媒体播放或不。看到playbackbufferfull下面");
    //        if(self.playerItem.isPlaybackLikelyToKeepUp) {
    ////            [self playerToPlay];
    //            NSLog(@"恢复播放");
    //        }
    //        else {
    //            [self playerToWiting];
    //            NSLog(@"恢复等待");
    //        }
    //        //手机唤醒会调用
    //    }
    //    else if([keyPath isEqualToString:@"playbackBufferFull"]) {
    //        NSLog(@"表示内部媒体缓冲区是满的，并且还暂停了。");
    //        [self playerToWiting];
    //    }
}
#pragma mark - ~~~~~~~~~~~ 计算缓冲进度 ~~~~~~~~~~~~~~~
- (NSTimeInterval)availableDuration {
    NSArray *loadedTimeRanges = [[self.playerView.player currentItem] loadedTimeRanges];
    // 获取缓冲区域
    CMTimeRange timeRange = [loadedTimeRanges.firstObject CMTimeRangeValue];
    float startSeconds = CMTimeGetSeconds(timeRange.start);
    float durationSeconds = CMTimeGetSeconds(timeRange.duration);
    
    // 计算缓冲总进度
    NSTimeInterval result = startSeconds + durationSeconds;
    return result;
}

/** 耳机插入、拔出事件 */
- (void)audioRouteChangeListenerCallback:(NSNotification*)notification
{
    NSDictionary *interuptionDict = notification.userInfo;
    
    NSInteger routeChangeReason = [[interuptionDict valueForKey:AVAudioSessionRouteChangeReasonKey] integerValue];
    
    switch (routeChangeReason) {
            
        case AVAudioSessionRouteChangeReasonNewDeviceAvailable:
            //            NSLog(@"耳机插入");
            _listenerStatus = ListenerStatusIn;
            break;
            
        case AVAudioSessionRouteChangeReasonOldDeviceUnavailable:
        {
        //            NSLog(@"耳机拔掉");
        // 拔掉耳机继续播放
        _listenerStatus = ListenerStatusOut;
        //            [self playerToPlay];
        }
            break;
            
        case AVAudioSessionRouteChangeReasonCategoryChange:
        {
        // called at start - also when other audio wants to play
        NSLog(@"AVAudioSessionRouteChangeReasonCategoryChange");
        break;
        }
        case AVAudioSessionRouteChangeReasonUnknown: {
            _listenerStatus = ListenerStatusUnkown;
        }
    }
    
    if(_playListenerStatusBlock) {
        _playListenerStatusBlock();
    }
}
@end
