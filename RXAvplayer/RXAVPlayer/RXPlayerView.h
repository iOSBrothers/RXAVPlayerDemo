//
//  RXPlayerView.h
//  RXAvplayer
//
//  Created by srx on 2017/6/27.
//  Copyright © 2017年 https://github.com/srxboys. All rights reserved.
//
// view 里封装 播放器

#import <UIKit/UIKit.h>

///播放状态
typedef NS_ENUM(NSInteger, PlayerStatus) {
    PlayerStatusFaild,//失败
    PlayerStatusReady,//准备
    PlayerStatusPlay,// 播放ing
    PlayerStatusStop //暂停、停止
    
};

/// 耳机状态
typedef NS_ENUM(NSInteger, ListenerStatus) {
    ListenerStatusUnkown, //不变
    ListenerStatusIn, //插入耳机
    ListenerStatusOut //爆出耳机
};

/// 屏幕状态
typedef NS_ENUM(NSInteger, PlayerScreen){
    PlayerScreenVertical = 0, //竖屏
    PlayerScreenFull = 1 //全屏
};

/// block 事件调用 (用代理delegate 容易 强强引用)
    /// 播放状态改变 -- 1
    typedef void(^PlayerStatusPlayBlock)();
    /// 播放完毕  -- 2
    typedef void(^PlayerStatusPlayENDBlock)();
    /// 视频加载失败  -- 3
    typedef void(^PlayerStatusErrorBlock)();
    /// 点击播放按钮的监听  -- 4
    typedef void(^PlayerButtonClickBlock)();
    /// 视频源有问题-没有网络  -- 5
    typedef void(^PlayerNoNetworkStatusBlock)();
    /// 耳机状态的监听 -- 6
    typedef void(^PlayerListenerStatusBlock)();
    /// 点击立即购买 -- 7
    typedef void(^PlayerNowbuyClickBlock)();
    /// 点击全屏 还是 返回 -- 8
    typedef void(^PlayerFullScreenClickBlock)(PlayerScreen playerScreen);
    /// 播放器内部点击将要 旋转 -- 9
    typedef void(^PlayerClickScreenWillChangeBlock)();
    /// 声音按钮的点击 -- 10
    typedef void(^PlayerClickVoiceChangeBlock)(BOOL isOff);
    //实时截图 -- 11
    typedef void(^PlayerSnapShotImageBlock)(NSInteger item, UIImage *image);




@interface RXPlayerView : UIView
@property (nonatomic, assign)NSInteger item;//collection/table.item
@property (nonatomic, assign) BOOL voiceOn;//是否播放声音
@property (nonatomic, assign) BOOL playerDestroy;//销毁

- (void)setPlayerURL:(NSString *)url;//播放流地址、设置就播放了
// 设置全屏 -- 左、右
- (void)setFullScreen;
// 设置竖屏
- (void)setVerticalScreen;

/// 播放
- (void)play;
/// 暂停是否 销毁资源【手机不允许播放的设置】
- (void)stop;


/**
 *  只是获取
 */
@property (nonatomic, copy, readonly) NSString * playerURL;
@property (nonatomic, assign, readonly) PlayerScreen playerScreen;
@property (nonatomic, assign, readonly) PlayerStatus playerStatus; //设置
@property (nonatomic, assign, readonly) ListenerStatus listenerStatus;
@property (nonatomic, copy) PlayerStatusPlayBlock playStatusPlayBlock;
@property (nonatomic, copy) PlayerStatusPlayENDBlock playStatusPlayEndBlock;
@property (nonatomic, copy) PlayerStatusErrorBlock playStatusErrorBlock;
@property (nonatomic, copy) PlayerButtonClickBlock playStatusClickBlock;
@property (nonatomic, copy) PlayerNoNetworkStatusBlock playNoNetworkStatusBlock;
@property (nonatomic, copy) PlayerListenerStatusBlock playListenerStatusBlock ;
@property (nonatomic, copy) PlayerNowbuyClickBlock playNowbuyClickBlock;
@property (nonatomic, copy) PlayerFullScreenClickBlock playFullScreenClickBlock;
@property (nonatomic, copy) PlayerClickScreenWillChangeBlock playClickScreenWillChangeBlock;
@property (nonatomic, copy) PlayerClickVoiceChangeBlock playClickVoiceChangeBlock;
@property (nonatomic, copy) PlayerSnapShotImageBlock playSnapShotImageBlock;

@end
