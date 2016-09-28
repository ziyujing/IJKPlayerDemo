//
//  AYPlayer.m
//  AiYanProject
//
//  Created by KUN on 16/9/18.
//  Copyright © 2016年 Apple. All rights reserved.
//

#import "AYPlayer.h"
#import "AYPlayerHeader.h"
#import <IJKMediaFramework/IJKMediaFramework.h>
#import <AVFoundation/AVFoundation.h>

static const CGFloat ZFPlayerAnimationTimeInterval             = 7.0f;
// 枚举值，包含水平移动方向和垂直移动方向
typedef NS_ENUM(NSInteger, PanDirection){
    PanDirectionHorizontalMoved, // 横向移动
    PanDirectionVerticalMoved    // 纵向移动
};
//static const CGFloat ZFPlayerControlBarAutoFadeOutTimeInterval = 0.35f;
@interface AYPlayer () <UIGestureRecognizerDelegate>
/** 播放器 */
@property(atomic, retain,) id<IJKMediaPlayback> player;
/** 控制层View */
@property (nonatomic, strong) AYPlayerControlView    *controlView;

@property (nonatomic, strong) AVAssetImageGenerator  *imageGenerator;
/** 视频采集 */
@property (nonatomic, strong) AVURLAsset             *urlAsset;
@property (nonatomic, strong) UITapGestureRecognizer *tap;
@property (nonatomic, strong) UITapGestureRecognizer *doubleTap;
/** 进入后台*/
@property (nonatomic, assign) BOOL                   didEnterBackground;
/** 播放完了*/
@property (nonatomic, assign) BOOL                   playDidEnd;
/** 是否自动播放 */
@property (nonatomic, assign) BOOL                   isAutoPlay;
/** 是否被用户暂停 */
@property (nonatomic, assign) BOOL       isPauseByUser;
/** 是否显示controlView*/
@property (nonatomic, assign) BOOL                   isMaskShowing;
/** 是否播放本地文件 */
@property (nonatomic, assign) BOOL                   isLocalVideo;
/** 是否正在拖动进度条 */
@property (nonatomic, assign) BOOL                   isChangeSliderVideo;
//进度变化定时器
@property (nonatomic, strong)NSTimer * timer;
/** slider上次的值 */
@property (nonatomic, assign) CGFloat                sliderLastValue;
/** palyer加到tableView */
@property (nonatomic, strong) UIView            *videoView;
///** 视频采集 */
//@property (nonatomic, assign) AVAsset *videoAsset;
/** 定义一个实例变量，保存枚举值 */
@property (nonatomic, assign) PanDirection           panDirection;
/** 用来保存快进的总时长 */
@property (nonatomic, assign) CGFloat                sumTime;
#pragma mark - UITableViewCell PlayerView

/** palyer加到tableView */
@property (nonatomic, strong) UITableView            *tableView;
/** player所在cell的indexPath */
@property (nonatomic, strong) NSIndexPath            *indexPath;
/** cell上imageView的tag */
@property (nonatomic, assign) NSInteger              cellImageViewTag;
/** ViewController中页面是否消失 */
@property (nonatomic, assign) BOOL                   viewDisappear;

/** 是否缩小视频在底部 */
@property (nonatomic, assign) BOOL                   isBottomVideo;
/** 是否在cell上播放video */
@property (nonatomic, assign) BOOL                   isCellVideo;
/** 是否再次设置URL播放视频 */
@property (nonatomic, assign) BOOL                   repeatToPlay;
/** cell中是否是第一次创建 */
@property (nonatomic, assign) BOOL                   isCellFirst;
@end



@implementation AYPlayer

+ (instancetype)sharedPlayerView {

    static AYPlayer *player = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        player = [[AYPlayer alloc]init];
    });
    
    return player;
}

- (instancetype)init {

    if (self = [super init]) {
        //
//        [self initialAYPlayer];
        
    }
    return self;
}

- (id)initWithContentURL:(NSURL *)aUrl withOptions:(NSDictionary *)options withSuperView:(UIView *)videoView {

    if (self = [super init]) {
        _videoURL = aUrl;
        _options = options;
        self.videoView = videoView;
        
        [self initialAYPlayer];
        [self createTimer];
        [self addNotifications];
        // 添加手势
        [self createGesture];
    }
    return self;
}

#pragma mark - 观察者、通知

/**
 *  添加观察者、通知
 */
- (void)addNotifications{
   
    // app退到后台
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackground) name:UIApplicationWillResignActiveNotification object:nil];
    // app进入前台
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterPlayGround) name:UIApplicationDidBecomeActiveNotification object:nil];
    // slider开始滑动事件
    [self.controlView.videoSlider addTarget:self action:@selector(progressSliderTouchBegan:) forControlEvents:UIControlEventTouchDown];
    // slider滑动中事件
    [self.controlView.videoSlider addTarget:self action:@selector(progressSliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    // slider结束滑动事件
    [self.controlView.videoSlider addTarget:self action:@selector(progressSliderTouchEnded:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchCancel | UIControlEventTouchUpOutside];
    [self.controlView.startBtn addTarget:self action:@selector(startAction:) forControlEvents:UIControlEventTouchUpInside];
    // 返回按钮点击事件
    [self.controlView.backBtn addTarget:self action:@selector(backButtonAction) forControlEvents:UIControlEventTouchUpInside];
    // 全屏按钮点击事件
    [self.controlView.fullScreenBtn addTarget:self action:@selector(fullScreenAction:) forControlEvents:UIControlEventTouchUpInside];
    
    // 加载完成后，再添加平移手势
    // 添加平移手势，用来控制音量、亮度、快进快退
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(panDirection:)];
    pan.delegate                = self;
    [self addGestureRecognizer:pan];
//    // 重播
//    [self.controlView.repeatBtn addTarget:self action:@selector(repeatPlay:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)initialAYPlayer{
    
//    self.urlAsset = [AVURLAsset assetWithURL:self.videoURL];
    if ([self.videoURL.scheme isEqualToString:@"file"])
    {
        self.isLocalVideo = YES;
    }else{
        self.isLocalVideo = NO;
    }
     IJKFFOptions *options = [IJKFFOptions optionsByDefault];
    _player = [[IJKFFMoviePlayerController alloc] initWithContentURL:_videoURL withOptions:options];
    [_player setScalingMode:IJKMPMovieScalingModeAspectFit];
    UIView *playerView = [_player view];
//    playerView.frame = UIScreen16_9;
//    playerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview:playerView];
    [playerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.leading.bottom.trailing.mas_equalTo(0);
    }];

    [self addSubview:self.controlView];
    [self.controlView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.leading.bottom.trailing.mas_equalTo(0);
//        make.top.leading.trailing.bottom.equalTo(self);
    }];
    
//    self.isPauseByUser = YES;
    self.isMaskShowing = NO;
    [self installMovieNotificationObservers];
    [self animateShow];
}
- (void)createTimer
{
    if (self.timer == nil) {
       self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(change) userInfo:nil repeats:YES];
    }
    
//    [self.timer setFireDate:[NSDate distantFuture]];//暂停timer
//    [self.timer fire];
}
//进度条变化
- (void)change
{
    NSInteger currentTime                      = [self getResultTimeWithTime:self.player.currentPlaybackTime];
    // 当前时长进度progress
    NSInteger proMin                           = currentTime / 60;//当前秒
    NSInteger proSec                           = currentTime % 60;//当前分钟
    CGFloat totalTime                          = [self getResultTimeWithTime:self.player.duration];
    // duration 总时长
    NSInteger durMin                           = (NSInteger)totalTime / 60;//总秒
    NSInteger durSec                           = (NSInteger)totalTime % 60;//总分钟
    
    //slider最大值
    self.controlView.videoSlider.maximumValue = self.player.duration;
    // 更新slider
    self.controlView.videoSlider.value     =  self.player.currentPlaybackTime;
    // 更新当前播放时间
    self.controlView.currentTimeLabel.text = [NSString stringWithFormat:@"%02zd:%02zd", proMin, proSec];
    // 更新总时间
    self.controlView.totalTimeLabel.text   = [NSString stringWithFormat:@"%02zd:%02zd", durMin, durSec];
//    NSLog(@" -----currentTime =>  %f,   duration => %f, playableDuration => %f",self.player.playbackRate,self.player.duration,self.player.playableDuration);
}

- (NSInteger)getResultTimeWithTime:(CGFloat)time
{
    NSInteger ys = (NSInteger)(time*10)%10;
    return  (ys > 5)?(NSInteger)(time + 1):(NSInteger)(time);
}
/**
 *  重置player
 */
- (void)resetPlayer
{
    // 改为为播放完
    self.playDidEnd         = NO;
//    self.player         = nil;
    self.didEnterBackground = NO;
    // 视频跳转秒数置0
    self.seekTime           = 0;
    self.isAutoPlay         = NO;
    // 暂停
    [self stop];
    if (self.timer) {
        [self.timer invalidate];
        self.timer = nil;
    }
//    [self removeMovieNotificationObservers];
    
//    [self cancelAutoFadeOutControlBar];
    
    // 移除原来的layer
    [self.player.view removeFromSuperview];
    self.imageGenerator = nil;
    // 把player置为nil
//    self.player = nil;
    [self teadownPlayer];
    // 移除通知
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    // 重置控制层View
    [self.controlView resetControlView];
    
    // 非重播时，移除当前playerView
    if (!self.repeatToPlay) { [self removeFromSuperview]; }
    // 底部播放video改为NO
    self.isBottomVideo = NO;
    // cell上播放视频 && 不是重播时
    if (self.isCellVideo && !self.repeatToPlay) {
        // vicontroller中页面消失
        self.viewDisappear = YES;
        self.isCellVideo   = NO;
        self.tableView     = nil;
        self.indexPath     = nil;
    }
}

/**
 *  应用退到后台
 */
- (void)appDidEnterBackground
{
//    self.didEnterBackground = YES;
    [self.player pause];
    [self.timer setFireDate:[NSDate distantFuture]];//暂停timer

//    self.state = ZFPlayerStatePause;
    [self cancelAutoFadeOutControlBar];
    self.controlView.startBtn.selected = NO;
}

/**
 *  应用进入前台
 */
- (void)appDidEnterPlayGround
{
//    self.didEnterBackground = NO;
    self.isMaskShowing = NO;
    // 延迟隐藏controlView
    [self animateShow];
    if (!self.isPauseByUser) {
//        self.state                         = ZFPlayerStatePlaying;
        self.controlView.startBtn.selected = YES;
        self.isPauseByUser                 = NO;
        [self play];
    }
}
#pragma mark - 设置视频URL

/**
 *  用于cell上播放player
 *
 *  @param videoURL  视频的URL
 *  @param tableView tableView
 *  @param indexPath indexPath
 */
- (void)setVideoURL:(NSURL *)videoURL
      withTableView:(UITableView *)tableView
        AtIndexPath:(NSIndexPath *)indexPath
   withImageViewTag:(NSInteger)tag
{
    self.isCellFirst = YES;
    // 如果页面没有消失，并且playerItem有值，需要重置player(其实就是点击播放其他视频时候)
    if (!self.viewDisappear && self.player) {self.isCellFirst = NO;
        [self resetPlayer]; }
    // 在cell上播放视频
    self.isCellVideo      = YES;
    // viewDisappear改为NO
    self.viewDisappear    = NO;
    // 设置imageView的tag
    self.cellImageViewTag = tag;
    // 设置tableview
    self.tableView        = tableView;
    // 设置indexPath
    self.indexPath        = indexPath;
    // 设置视频URL
//    [self setVideoURL:videoURL];
    [self setPlayerWithUrl:videoURL];
    
     [self createTimer];
    
    if (self.isCellFirst == YES) {
        
        [self addNotifications];
        // 添加手势
        [self createGesture];
    }
    
}
- (void)setPlayerWithUrl:(NSURL *)url
{
    _videoURL = url;
    //    self.urlAsset = [AVURLAsset assetWithURL:self.videoURL];
    if ([self.videoURL.scheme isEqualToString:@"file"])
    {
        self.isLocalVideo = YES;
    }else{
        self.isLocalVideo = NO;
    }
    self.backgroundColor = [UIColor redColor];
    IJKFFOptions *options = [IJKFFOptions optionsByDefault];
    _player = [[IJKFFMoviePlayerController alloc] initWithContentURL:url withOptions:options];
    [_player setScalingMode:IJKMPMovieScalingModeAspectFit];
    UIView *playerView = [_player view];
    playerView.backgroundColor = [UIColor blueColor];
    //    playerView.frame = UIScreen16_9;
    //    playerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    if (self.isCellFirst == YES)
    {
        [self addSubview:playerView];
    }else{
        [self insertSubview:playerView belowSubview:self.controlView];
    }
    [playerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.leading.bottom.trailing.mas_equalTo(0);
    }];
    if (self.isCellFirst == YES) {
        [self addSubview:self.controlView];
    }
    
    [self.controlView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.leading.bottom.trailing.mas_equalTo(0);
        //        make.top.leading.trailing.bottom.equalTo(self);
    }];
    
    //    self.isPauseByUser = YES;
    self.isMaskShowing = NO;
    [self installMovieNotificationObservers];
    [self animateShow];
}
#pragma mark - slider事件

/**
 *  slider开始滑动事件
 *
 *  @param slider UISlider
 */
- (void)progressSliderTouchBegan:(AYSlider *)slider
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

/**
 *  slider滑动中事件
 *
 *  @param slider UISlider
 */
- (void)progressSliderValueChanged:(AYSlider *)slider
{
    
    NSString *style = @"";
    CGFloat value   = slider.value - self.player.currentPlaybackTime;
    if (value > 0) { style = @">>"; }
    if (value < 0) { style = @"<<"; }
    if (value == 0) { return; }
    // duration
    NSTimeInterval duration = self.player.duration;
    NSInteger intDuration = duration + 0.0;
    if (intDuration > 0) {
        self.controlView.videoSlider.maximumValue = duration;
        
    } else {
        self.controlView.totalTimeLabel.text = @"--:--";
        self.controlView.videoSlider.maximumValue = 1.0f;
        return;
    }
    // 暂停
    [self pause];
    NSTimeInterval position;
    position = self.controlView.videoSlider.value;
    NSInteger intPosition = position + 0.0;
    
    NSString *currentTime = [NSString stringWithFormat:@"%02d:%02d", (int)(intPosition / 60), (int)(intPosition % 60)];
    self.controlView.currentTimeLabel.text = currentTime;
    CMTime dragedCMTime     = CMTimeMake(self.controlView.videoSlider.value, 1);
    self.controlView.videoSlider.popUpView.hidden = !self.isFullScreen;

    if (self.isFullScreen)
    {
        [self.controlView.videoSlider setText:currentTime];
        dispatch_queue_t queue = dispatch_queue_create("com.playerPic.queue", DISPATCH_QUEUE_CONCURRENT);
        dispatch_async(queue, ^{
            NSError *error;
            CMTime actualTime;
            CGImageRef cgImage = [self.imageGenerator copyCGImageAtTime:dragedCMTime actualTime:&actualTime error:&error];
            CMTimeShow(actualTime);
            UIImage *image = [UIImage imageWithCGImage:cgImage];
            CGImageRelease(cgImage);
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.controlView.videoSlider setImage:image ? : AYPlayerImageFile(@"ZFPlayer_loading_bgView")];
            });
        });
    }else{
        self.controlView.horizontalLabel.hidden = NO;
        self.controlView.horizontalLabel.text   = [NSString stringWithFormat:@"%@ %@ / %@",style, currentTime, [self durationStringWithTime:duration]];
        
    }
    
    
//    //拖动改变视频播放进度
//    if (self.player.loadState == !IJKMPMovieLoadStateUnknown) {
//        self.isChangeSliderVideo = YES;
//        NSString *style = @"";
//        CGFloat value   = slider.value - self.sliderLastValue;
//        if (value > 0) { style = @">>"; }
//        if (value < 0) { style = @"<<"; }
//        if (value == 0) { return; }
//        
//        self.sliderLastValue    = slider.value;
//        // 暂停
//        [self pause];
//        
//        CGFloat total           = self.player.duration;
//        
//        //计算出拖动的当前秒数
//        NSInteger dragedSeconds = floorf(total * slider.value);
//        
//        //转换成CMTime才能给player来控制播放进度
//        
//        CMTime dragedCMTime     = CMTimeMake(dragedSeconds, 1);
//        // 拖拽的时长
//        NSInteger proMin        = (NSInteger)CMTimeGetSeconds(dragedCMTime) / 60;//当前秒
//        NSInteger proSec        = (NSInteger)CMTimeGetSeconds(dragedCMTime) % 60;//当前分钟
//        
//        //duration 总时长
//        NSInteger durMin        = (NSInteger)total / 60;//总秒
//        NSInteger durSec        = (NSInteger)total % 60;//总分钟
//        
//        NSString *currentTime   = [NSString stringWithFormat:@"%02zd:%02zd", proMin, proSec];
//        NSString *totalTime     = [NSString stringWithFormat:@"%02zd:%02zd", durMin, durSec];
//        NSLog(@"total === %f",total);
//        if (total > 0) { // 当总时长 > 0时候才能拖动slider
////            self.controlView.videoSlider.popUpView.hidden = !self.isFullScreen;
//            self.controlView.currentTimeLabel.text  = currentTime;
//            if (self.isFullScreen) {
//                [self.controlView.videoSlider setText:currentTime];
//                dispatch_queue_t queue = dispatch_queue_create("com.playerPic.queue", DISPATCH_QUEUE_CONCURRENT);
//                dispatch_async(queue, ^{
//                    NSError *error;
//                    CMTime actualTime;
//                    CGImageRef cgImage = [self.imageGenerator copyCGImageAtTime:dragedCMTime actualTime:&actualTime error:&error];
//                    CMTimeShow(actualTime);
//                    UIImage *image = [UIImage imageWithCGImage:cgImage];
//                    CGImageRelease(cgImage);
//                    dispatch_async(dispatch_get_main_queue(), ^{
//                        //                        [self.controlView.videoSlider setImage:image ? : ZFPlayerImage(@"ZFPlayer_loading_bgView")];
//                        [self.controlView.videoSlider setImage:image ? : AYPlayerImageFile(@"defaultmovie_")];
//                    });
//                });
//                
//            } else {
////                self.controlView.horizontalLabel.hidden = NO;
////                self.controlView.horizontalLabel.text   = [NSString stringWithFormat:@"%@ %@ / %@",style, currentTime, totalTime];
//            }
//        }else {
//            // 此时设置slider值为0
//            slider.value = 0;
//        }
//        
//    }else { // player状态加载失败
//        // 此时设置slider值为0
//        slider.value = 0;
//    }
}

/**
 *  slider结束滑动事件
 *
 *  @param slider UISlider
 */
- (void)progressSliderTouchEnded:(AYSlider *)slider
{
//    if (self.player.loadState == !IJKMPMovieLoadStateUnknown) {

    NSTimeInterval duration = self.player.duration;
    NSInteger intDuration = duration + 0.0;
    if (intDuration > 0) {
        self.isChangeSliderVideo = NO;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.controlView.horizontalLabel.hidden = YES;
        });
        
       
        // 结束滑动时候把开始播放按钮改为播放状态
        self.controlView.startBtn.selected = YES;
        self.isPauseByUser                 = NO;
        
        // 滑动结束延时隐藏controlView
        [self autoFadeOutControlBar];
        // 视频总时间长度
//        CGFloat total           =  self.player.duration;
        
        //计算出拖动的当前秒数
        NSInteger dragedSeconds = self.isLocalVideo?slider.value : MIN(slider.value, self.player.playableDuration);
        self.player.currentPlaybackTime = dragedSeconds;
        [self play];

    }
       //    }
}

- (void)startAction:(UIButton *)button
{
    button.selected    = !button.selected;
    self.isPauseByUser = !self.isPauseByUser;
    if (!button.selected) {
        [self play];
    } else {
        [self pause];
    }
}

- (void)prepareToPlay {
    if (self.player) {
        [self.player prepareToPlay];
//        [self.timer setFireDate:[NSDate distantPast]];//启动timer
    }
}

- (void)autoToplay {
    if (self.player) {
        self.player.shouldAutoplay = YES;
        [self.timer setFireDate:[NSDate distantPast]];//启动timer
    }
}

- (void)play {
    if (![self.player isPlaying]) {
        self.isPauseByUser = NO;
        self.controlView.startBtn.selected = NO;
        [self.player play];
        [self.timer setFireDate:[NSDate distantPast]];//启动timer
    }
}

-(void)pause {
    if ([self.player isPlaying]) {
        
        self.isPauseByUser = YES;
        self.controlView.startBtn.selected = YES;
        [self.player pause];
        [self.timer setFireDate:[NSDate distantFuture]];//暂停timer
    }
}

-(void)stop {
    
    if (self.player) {
        [self.player stop];
        [self.timer invalidate];
        self.timer = nil;
    }
}

-(BOOL)isPlaying {
    return [self.player isPlaying];
}

- (void)setPauseInBackground:(BOOL)pause {
    [self.player setPauseInBackground:pause];
}

/**
 *  创建手势
 */
- (void)createGesture
{
    // 单击
    self.tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapAction:)];
    self.tap.delegate = self;
    [self addGestureRecognizer:self.tap];
    
    // 双击(播放/暂停)
    self.doubleTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(doubleTapAction:)];
    [self.doubleTap setNumberOfTapsRequired:2];
    [self addGestureRecognizer:self.doubleTap];

    // 解决点击当前view时候响应其他控件事件
    self.tap.delaysTouchesBegan = YES;
    [self.tap requireGestureRecognizerToFail:self.doubleTap];
}

#pragma mark - Action

- (void)tapAction:(UITapGestureRecognizer *)gesture
{
    if (gesture.state == UIGestureRecognizerStateRecognized) {
//        [self startAction:self.controlView.startBtn];
        
        self.isMaskShowing ? ([self hideControlView]) : ([self animateShow]);
    }
}
/**
 *  双击播放/暂停
 *
 *  @param gesture UITapGestureRecognizer
 */
- (void)doubleTapAction:(UITapGestureRecognizer *)gesture
{
    // 显示控制层
    [self animateShow];
    [self startAction:self.controlView.startBtn];
}
#pragma mark - UIPanGestureRecognizer手势方法

/**
 *  pan手势事件
 *
 *  @param pan UIPanGestureRecognizer
 */
- (void)panDirection:(UIPanGestureRecognizer *)pan
{
    //根据在view上Pan的位置，确定是调音量还是亮度
    CGPoint locationPoint = [pan locationInView:self];
    
    // 我们要响应水平移动和垂直移动
    // 根据上次和本次移动的位置，算出一个速率的point
    CGPoint veloctyPoint = [pan velocityInView:self];
    
    // 判断是垂直移动还是水平移动
    switch (pan.state) {
        case UIGestureRecognizerStateBegan:{ // 开始移动
            // 使用绝对值来判断移动的方向
            CGFloat x = fabs(veloctyPoint.x);
            CGFloat y = fabs(veloctyPoint.y);
            if (x > y) { // 水平移动
                // 取消隐藏
                self.controlView.horizontalLabel.hidden = NO;
                self.panDirection = PanDirectionHorizontalMoved;
//                // 给sumTime初值
//                CMTime time       = self.player.currentTime;
                self.sumTime      = self.player.currentPlaybackTime;
                
                // 暂停视频播放
                [self pause];
            }
            else if (x < y){ // 垂直移动
                self.panDirection = PanDirectionVerticalMoved;
                // 开始滑动的时候,状态改为正在控制音量
//                if (locationPoint.x > self.bounds.size.width / 2) {
//                    self.isVolume = YES;
//                }else { // 状态改为显示亮度调节
//                    self.isVolume = NO;
//                }
            }
            break;
        }
        case UIGestureRecognizerStateChanged:{ // 正在移动
            switch (self.panDirection) {
                case PanDirectionHorizontalMoved:{
                    // 移动中一直显示快进label
//                    self.controlView.horizontalLabel.hidden = NO;
                    [self horizontalMoved:veloctyPoint.x]; // 水平移动的方法只要x方向的值
                    break;
                }
                case PanDirectionVerticalMoved:{
//                    [self verticalMoved:veloctyPoint.y]; // 垂直移动方法只要y方向的值
                    break;
                }
                default:
                    break;
            }
            break;
        }
        case UIGestureRecognizerStateEnded:{ // 移动停止
            // 移动结束也需要判断垂直或者平移
            // 比如水平移动结束时，要快进到指定位置，如果这里没有判断，当我们调节音量完之后，会出现屏幕跳动的bug
            switch (self.panDirection) {
                case PanDirectionHorizontalMoved:{
                    
                    // 继续播放
                    [self play];
                    
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        // 隐藏视图
                        self.controlView.horizontalLabel.hidden = YES;
                    });
                    // 快进、快退时候把开始播放按钮改为播放状态
                    self.controlView.startBtn.selected = YES;
                    self.isPauseByUser                 = NO;
                    self.player.currentPlaybackTime = self.sumTime;
//                    [self seekToTime:self.sumTime completionHandler:nil];
//                    // 把sumTime滞空，不然会越加越多
//                    self.sumTime = 0;
                    break;
                }
                case PanDirectionVerticalMoved:{
                    // 垂直移动结束后，把状态改为不再控制音量
//                    self.isVolume = NO;
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        self.controlView.horizontalLabel.hidden = YES;
                    });
                    break;
                }
                default:
                    break;
            }
            break;
        }
        default:
            break;
    }
}
/**
 *  pan水平移动的方法
 *
 *  @param value void
 */
- (void)horizontalMoved:(CGFloat)value
{
    // 快进快退的方法
    NSString *style = @"";
    if (value < 0) { style = @"<<"; }
    if (value > 0) { style = @">>"; }
    if (value == 0) { return; }
    
    
    
    // 需要限定sumTime的范围
//    CMTime totalTime           = self.player.duration;
    CGFloat totalMovieDuration = self.player.duration;
    // 每次滑动需要叠加时间
    self.sumTime += 3*value/self.width/totalMovieDuration;
    if (self.sumTime > totalMovieDuration) { self.sumTime = totalMovieDuration;}
    if (self.sumTime < 0) { self.sumTime = 0; }
    
    // 当前快进的时间
    NSString *nowTime         = [self durationStringWithTime:(int)self.sumTime];
    // 总时间
    NSString *durationTime    = [self durationStringWithTime:(int)totalMovieDuration];
    
    // 更新快进label的时长
    self.controlView.horizontalLabel .text  = [NSString stringWithFormat:@"%@ %@ / %@",style, nowTime, durationTime];
    // 更新slider的进度
    self.controlView.videoSlider.value     = self.sumTime;
    // 更新现在播放的时间
    self.controlView.currentTimeLabel.text = nowTime;
}
/**
 *  根据时长求出字符串
 *
 *  @param time 时长
 *
 *  @return 时长字符串
 */
- (NSString *)durationStringWithTime:(int)time
{
    // 获取分钟
    NSString *min = [NSString stringWithFormat:@"%02d",time / 60];
    // 获取秒数
    NSString *sec = [NSString stringWithFormat:@"%02d",time % 60];
    return [NSString stringWithFormat:@"%@:%@", min, sec];
}
#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if ([gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]) {
        CGPoint point = [touch locationInView:self.controlView];
        // （屏幕下方slider区域） || （在cell上播放视频 && 不是全屏状态） || (播放完了) =====>  不响应pan手势
        if ((point.y > self.bounds.size.height-40) || (self.isCellVideo && !self.isFullScreen) || self.playDidEnd) { return NO; }
        return YES;
    }
    // 在cell上播放视频 && 不是全屏状态 && 点在控制层上
    if (self.isBottomVideo && !self.isFullScreen && touch.view == self.controlView) {
        [self fullScreenAction:self.controlView.fullScreenBtn];
        return NO;
    }
    if (self.isBottomVideo && !self.isFullScreen && touch.view == self.controlView.backBtn) {
        // 关闭player
//        [self resetPlayer];
        [self removeFromSuperview];
        return NO;
    }
    return YES;
}
#pragma mark - ShowOrHideControlView

- (void)autoFadeOutControlBar
{
    if (!self.isMaskShowing) { return; }
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideControlView) object:nil];
    [self performSelector:@selector(hideControlView) withObject:nil afterDelay:ZFPlayerAnimationTimeInterval];
}
/**
 *  取消延时隐藏controlView的方法
 */
- (void)cancelAutoFadeOutControlBar
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}
- (void)hideControlView
{
    if (!self.isMaskShowing) { return; }
    [UIView animateWithDuration:0.35 animations:^{
        [self.controlView hideControlView];
        if (self.isFullScreen) { //全屏状态
            self.controlView.backBtn.alpha = 0;
            //            [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
        }else if (self.isBottomVideo && !self.isFullScreen) { // 视频在底部bottom小屏,并且不是全屏状态
            self.controlView.backBtn.alpha = 1;
        }else {
            self.controlView.backBtn.alpha = 0;
        }

    }completion:^(BOOL finished) {
        self.isMaskShowing = NO;
    }];
}


- (void)animateShow
{
    if (self.isMaskShowing) { return; }
    [UIView animateWithDuration:0.35f animations:^{
        
        if (self.isFullScreen) {
            self.controlView.backBtn.alpha = 1.0;
        }else{
            self.controlView.backBtn.alpha = 0.0;
        }
        if (self.isBottomVideo && !self.isFullScreen) { [self.controlView hideControlView]; } // 视频在底部bottom小屏,并且不是全屏状态
        else if (self.playDidEnd) { [self.controlView hideControlView]; } // 播放完了
        else { [self.controlView showControlView]; }
    } completion:^(BOOL finished) {
        self.isMaskShowing = YES;
        [self autoFadeOutControlBar];
    }];
}

/**
 *  返回按钮事件
 */
- (void)backButtonAction
{

    if (self.isFullScreen) {
        [[UIApplication sharedApplication] setStatusBarHidden:NO];
        [self toSmallScreen];
    }else {
    
    }
 
}
#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == self.tableView) {
        if ([keyPath isEqualToString:kZFPlayerViewContentOffset]) {
            if (([UIDevice currentDevice].orientation != UIDeviceOrientationPortrait)) { return; }
            // 当tableview滚动时处理playerView的位置
            [self handleScrollOffsetWithDict:change];
        }
    }
}

#pragma mark - tableViewContentOffset

/**
 *  KVO TableViewContentOffset
 *
 *  @param dict void
 */
- (void)handleScrollOffsetWithDict:(NSDictionary*)dict
{
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:self.indexPath];
    NSArray *visableCells = self.tableView.visibleCells;
    
    if ([visableCells containsObject:cell]) {
        //在显示中
//        [self updatePlayerViewToCell];
    }else {
        //在底部
//        [self updatePlayerViewToBottom];
        [self pause];
    }
}

/**
 *  缩小到底部，显示小视频
 */
- (void)updatePlayerViewToBottom
{
    if (self.isBottomVideo) { return ; }
    self.isBottomVideo = YES;
    if (self.playDidEnd) { //如果播放完了，滑动到小屏bottom位置时，直接resetPlayer
        self.repeatToPlay = NO;
        self.playDidEnd   = NO;
        [self resetPlayer];
        return;
    }
    [[UIApplication sharedApplication].keyWindow addSubview:self];
    // 解决4s，屏幕宽高比不是16：9的问题
    if (iPhone4s) {
        [self mas_remakeConstraints:^(MASConstraintMaker *make) {
            CGFloat width = SCREEN_WIDTH*0.5-20;
            make.width.mas_equalTo(width);
            make.trailing.mas_equalTo(-10);
            make.bottom.mas_equalTo(-self.tableView.contentInset.bottom-10);
            make.height.mas_equalTo(width*320/480).with.priority(750);
        }];
    }else {
        [self mas_remakeConstraints:^(MASConstraintMaker *make) {
            CGFloat width = SCREEN_WIDTH*0.5-20;
            make.width.mas_equalTo(width);
            make.trailing.mas_equalTo(-10);
            make.bottom.mas_equalTo(-self.tableView.contentInset.bottom-10);
            make.height.equalTo(self.mas_width).multipliedBy(9.0f/16.0f).with.priority(750);
        }];
    }
    // 不显示控制层
    [self.controlView hideControlView];
}
/**
 *  player添加到cellImageView上
 *
 *  @param cell 添加player的cellImageView
 */
- (void)addPlayerToCellImageView:(UIImageView *)imageView
{
    [imageView addSubview:self];
    [self mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.leading.trailing.bottom.equalTo(imageView);
    }];
}
/**
 *  回到cell显示
 */
- (void)updatePlayerViewToCell
{
    if (!self.isBottomVideo) { return; }
    self.isBottomVideo     = NO;
    // 显示控制层
    self.controlView.alpha = 1;
    [self setOrientationPortrait];
    
    [self.controlView showControlView];
}

/**
 *  设置横屏的约束
 */
- (void)setOrientationLandscape
{
    if (self.isCellVideo) {
        
        // 横屏时候移除tableView的观察者
        [self.tableView removeObserver:self forKeyPath:kZFPlayerViewContentOffset];
        
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
        // 亮度view加到window最上层
        [[UIApplication sharedApplication].keyWindow addSubview:self];
        [self mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.edges.insets(UIEdgeInsetsMake(0, 0, 0, 0));
        }];
    }
}

/**
 *  设置竖屏的约束
 */
- (void)setOrientationPortrait
{
    if (self.isCellVideo) {
//        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
        [self removeFromSuperview];
        UITableViewCell * cell = [self.tableView cellForRowAtIndexPath:self.indexPath];
        NSArray *visableCells = self.tableView.visibleCells;
        self.isBottomVideo = NO;
        if (![visableCells containsObject:cell]) {
            [self updatePlayerViewToBottom];
        }else {
            // 根据tag取到对应的cellImageView
            UIImageView *cellImageView = [cell viewWithTag:self.cellImageViewTag];
            [self addPlayerToCellImageView:cellImageView];
        }
    }
}

#pragma mark 屏幕转屏相关
/**
 *  全屏按钮事件
 *
 *  @param sender 全屏Button
 */
- (void)fullScreenAction:(UIButton *)sender
{
    
//    if (self.isCellVideo && sender.selected == YES) {
//        [self interfaceOrientation:UIInterfaceOrientationPortrait];
//        return;
//    }
    
    UIButton *fullScreenBtn = (UIButton *)sender;
    if (!self.isFullScreen) {//全屏显示
        if (self.isCellVideo) {
            
            // 横屏时候移除tableView的观察者
            [self.tableView removeObserver:self forKeyPath:kZFPlayerViewContentOffset];
        }
//        [[UIApplication sharedApplication] setStatusBarHidden:YES];
        [self toFullScreenWithInterfaceOrientation:UIInterfaceOrientationLandscapeLeft];
    }else{
        [[UIApplication sharedApplication] setStatusBarHidden:NO];
        if (self.isFullScreen) {
            //放widow上,小屏显示
            [self toSmallScreen];
        }else{
//            [self toCell];
        }
    }

}


-(void)toFullScreenWithInterfaceOrientation:(UIInterfaceOrientation )interfaceOrientation{
    
    [self removeFromSuperview];
//    self.transform = CGAffineTransformIdentity;
    
    [[UIApplication sharedApplication].keyWindow addSubview:self];
    [UIView animateWithDuration:0.25f animations:^{
        if (interfaceOrientation==UIInterfaceOrientationLandscapeLeft) {
            self.transform = CGAffineTransformMakeRotation(M_PI_2);
        }else if(interfaceOrientation==UIInterfaceOrientationLandscapeRight){
            self.transform = CGAffineTransformMakeRotation(-M_PI_2);
        }
        [self mas_updateConstraints:^(MASConstraintMaker *make) {
            make.centerX.mas_equalTo(0);
            make.centerY.mas_equalTo(0);
            make.height.mas_equalTo(SCREEN_WIDTH);
            make.width.mas_equalTo(SCREEN_HEIGHT);
        }];

    } completion:^(BOOL finished) {
        [[UIApplication sharedApplication] setStatusBarHidden:YES];
        self.isFullScreen = YES;
        self.controlView.fullScreenBtn.selected = YES;
    }];
}
-(void)toSmallScreen{
    
    if (self.isCellVideo) {
        
//        self.transform = CGAffineTransformIdentity;
        // 竖屏时候table滑动到可视范围
        [self.tableView scrollToRowAtIndexPath:self.indexPath atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
        // 重新监听tableview偏移量
        [self.tableView addObserver:self forKeyPath:kZFPlayerViewContentOffset options:NSKeyValueObservingOptionNew context:nil];
        
        [self removeFromSuperview];
        UITableViewCell * cell = [self.tableView cellForRowAtIndexPath:self.indexPath];
        NSArray *visableCells = self.tableView.visibleCells;
        self.isBottomVideo = NO;
        [UIView animateWithDuration:0.25f animations:^{
            self.transform = CGAffineTransformIdentity;
            if (![visableCells containsObject:cell]) {
                [self updatePlayerViewToBottom];
            }else {
                // 根据tag取到对应的cellImageView
                UIImageView *cellImageView = [cell viewWithTag:self.cellImageViewTag];
                [self addPlayerToCellImageView:cellImageView];
            }
            
        } completion:^(BOOL finished) {
            self.controlView.backBtn.alpha = 0.0;
            self.isFullScreen = NO;
            self.controlView.fullScreenBtn.selected = NO;
        }];

    }else{
        //放widow上
        [self removeFromSuperview];
        [self.videoView addSubview:self];
        //    [[UIApplication sharedApplication].keyWindow bringSubviewToFront:self];
        [UIView animateWithDuration:0.25f animations:^{
            self.transform = CGAffineTransformIdentity;
            [self mas_updateConstraints:^(MASConstraintMaker *make) {
                make.top.mas_equalTo(0);
                make.left.mas_equalTo(0);
                //        make.centerX.mas_equalTo(0);
                //        make.centerY.mas_equalTo(0);
                make.height.mas_equalTo(self.videoView.height);
                make.width.mas_equalTo(self.videoView.width);
            }];
            
        } completion:^(BOOL finished) {
            self.controlView.backBtn.alpha = 0.0;
            self.isFullScreen = NO;
            self.controlView.fullScreenBtn.selected = NO;
        }];

    }
}
/**
 *  根据tableview的值来添加、移除观察者
 *
 *  @param tableView tableView
 */
- (void)setTableView:(UITableView *)tableView
{
    if (_tableView == tableView) { return; }
    
    if (_tableView) { [_tableView removeObserver:self forKeyPath:kZFPlayerViewContentOffset]; }
    _tableView = tableView;
    if (tableView) { [tableView addObserver:self forKeyPath:kZFPlayerViewContentOffset options:NSKeyValueObservingOptionNew context:nil]; }
}
/**
 *  设置playerLayer的填充模式
 *
 *  @param playerLayerGravity playerLayerGravity
 */
- (void)setPlayerLayerGravity:(AYPlayerLayerGravity)playerLayerGravity
{
    _playerLayerGravity = playerLayerGravity;
    // AVLayerVideoGravityResize,           // 非均匀模式。两个维度完全填充至整个视图区域
    // AVLayerVideoGravityResizeAspect,     // 等比例填充，直到一个维度到达区域边界
    // AVLayerVideoGravityResizeAspectFill  // 等比例填充，直到填充满整个视图区域，其中一个维度的部分区域会被裁剪
    switch (playerLayerGravity) {
        case AYPlayerLayerGravityFill:
            self.player.scalingMode = IJKMPMovieScalingModeFill;
            break;
        case AYPlayerLayerGravityAspectFit:
            self.player.scalingMode = IJKMPMovieScalingModeAspectFit;
            break;
        case AYPlayerLayerGravityAspectFill:
            self.player.scalingMode = IJKMPMovieScalingModeAspectFill;
            break;
        default:
            break;
    }
}

- (void)setSeekTime:(NSInteger)seekTime
{
//    self.player.currentPlaybackTime = seekTime;
}
/**
 *  是否隐藏返回按钮  new add by KUN
 */
- (void)setIsHideBackBtn:(BOOL)isHideBackBtn {
    _isHideBackBtn = isHideBackBtn;
    self.controlView.backBtn.hidden = isHideBackBtn;
}
- (void)setIsHideControlView:(BOOL)isHideControlView
{
    _isHideControlView = isHideControlView;
    self.controlView.hidden = YES;
}
#pragma mark ---initview---
- (AYPlayerControlView *)controlView {
 
    if (!_controlView) {
        _controlView = [[AYPlayerControlView alloc]init];
    }
    return _controlView;
}
- (AVAssetImageGenerator *)imageGenerator
{
    if (!_imageGenerator) {
        _imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:self.urlAsset];
    }
    return _imageGenerator;
}

- (void)layoutSubviews {
    [super layoutSubviews];
}

#pragma mark --getter ---
- (AVURLAsset *)urlAsset
{
    if (!_urlAsset) {
        _urlAsset = [AVURLAsset assetWithURL:self.videoURL];
    }
    return _urlAsset;
}
- (CGFloat)totalTime
{
    return self.player.duration;
}
-(CGFloat)totalDuRation
{
    //视频采集
    AVAsset *videoAsset1 = self.urlAsset;
   return videoAsset1.duration.value;
}
- (CGFloat)totalTimescale
{
    //视频采集
    AVAsset *videoAsset1 = self.urlAsset;
    return videoAsset1.duration.timescale;
}
#pragma Install Notifiacation- -播放器依赖的相关监听

- (void)loadStateDidChange:(NSNotification*)notification {
    
    IJKMPMovieLoadState loadState = _player.loadState;
    
    if ((loadState & IJKMPMovieLoadStatePlaythroughOK) != 0) {
        NSLog(@"LoadStateDidChange: IJKMovieLoadStatePlayThroughOK: %d\n",(int)loadState);
        if (self.player) {
            [self.controlView.activity stopAnimating];
        }
        
    }else if ((loadState & IJKMPMovieLoadStateStalled) != 0) {
        NSLog(@"loadStateDidChange: IJKMPMovieLoadStateStalled: %d\n", (int)loadState);
        if (self.player) {
            [self.controlView.activity startAnimating];
        }
        
    } else {
        NSLog(@"loadStateDidChange: ???: %d\n", (int)loadState);
    }
}

- (void)moviePlayBackFinish:(NSNotification*)notification {
    
    int reason =[[[notification userInfo] valueForKey:IJKMPMoviePlayerPlaybackDidFinishReasonUserInfoKey] intValue];
    switch (reason) {
        case IJKMPMovieFinishReasonPlaybackEnded:
            NSLog(@"playbackStateDidChange: IJKMPMovieFinishReasonPlaybackEnded: %d\n", reason);
            break;
            
        case IJKMPMovieFinishReasonUserExited:
            NSLog(@"playbackStateDidChange: IJKMPMovieFinishReasonUserExited: %d\n", reason);
            break;
            
        case IJKMPMovieFinishReasonPlaybackError:
            NSLog(@"playbackStateDidChange: IJKMPMovieFinishReasonPlaybackError: %d\n", reason);
            if (self.player) {
                self.controlView.horizontalLabel.hidden = NO;
                self.controlView.horizontalLabel.text = @"视频加载失败";

            }
            break;
            
        default:
            NSLog(@"playbackPlayBackDidFinish: ???: %d\n", reason);
            break;
    }
}

- (void)mediaIsPreparedToPlayDidChange:(NSNotification*)notification {
    NSLog(@"mediaIsPrepareToPlayDidChange\n");
}

- (void)moviePlayBackStateDidChange:(NSNotification*)notification {
    switch (_player.playbackState) {
        case IJKMPMoviePlaybackStateStopped:
            NSLog(@"IJKMPMoviePlayBackStateDidChange %d: stoped", (int)_player.playbackState);
            if (self.isChangeSliderVideo == NO&&self.player) {
                self.controlView.startBtn.selected = YES;
                [self startAction:self.controlView.startBtn];
            }
            
            break;
            
        case IJKMPMoviePlaybackStatePlaying:
            NSLog(@"IJKMPMoviePlayBackStateDidChange %d: playing", (int)_player.playbackState);
            break;
            
        case IJKMPMoviePlaybackStatePaused:
            NSLog(@"IJKMPMoviePlayBackStateDidChange %d: paused", (int)_player.playbackState);
            break;
            
        case IJKMPMoviePlaybackStateInterrupted:
            NSLog(@"IJKMPMoviePlayBackStateDidChange %d: interrupted", (int)_player.playbackState);
            break;
            
        case IJKMPMoviePlaybackStateSeekingForward:
        case IJKMPMoviePlaybackStateSeekingBackward: {
            NSLog(@"IJKMPMoviePlayBackStateDidChange %d: seeking", (int)_player.playbackState);
            break;
        }
            
        default: {
            NSLog(@"IJKMPMoviePlayBackStateDidChange %d: unknown", (int)_player.playbackState);
            break;
        }
    }
}
- (void)moviePlayFirstVideoFrameRendered:(NSNotification*)notification
{
    NSLog(@"加载第一个画面！");
    //    if (_previewImage) {
    //        _previewImage.hidden = YES;
    //    }
    if (self.player) {
        [self.controlView.activity stopAnimating];
        [self performSelector:@selector(hideControlView) withObject:nil afterDelay:2];
        
        
        
        if(![self.player isPlaying]){
            NSLog(@"检测的一次播放状态错误");
            [self play];
        }

    }
}
#pragma Install Notifiacation

- (void)installMovieNotificationObservers {
    

    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(loadStateDidChange:)
                                                 name:IJKMPMoviePlayerLoadStateDidChangeNotification
                                               object:_player];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moviePlayBackFinish:)
                                                 name:IJKMPMoviePlayerPlaybackDidFinishNotification
                                               object:_player];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(mediaIsPreparedToPlayDidChange:)
                                                 name:IJKMPMediaPlaybackIsPreparedToPlayDidChangeNotification
                                               object:_player];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moviePlayBackStateDidChange:)
                                                 name:IJKMPMoviePlayerPlaybackStateDidChangeNotification
                                               object:_player];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moviePlayFirstVideoFrameRendered:)
                                                 name:IJKMPMoviePlayerFirstVideoFrameRenderedNotification
                                               object:_player];
    
}

- (void)removeMovieNotificationObservers {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:IJKMPMoviePlayerLoadStateDidChangeNotification
                                                  object:_player];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:IJKMPMoviePlayerPlaybackDidFinishNotification
                                                  object:_player];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:IJKMPMediaPlaybackIsPreparedToPlayDidChangeNotification
                                                  object:_player];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:IJKMPMoviePlayerPlaybackStateDidChangeNotification
                                                  object:_player];
}
- (void)gotoDeallocSelf
{
    [self stop];
    [self gotoRemoveSelf];
//    [self dealloc];
}
- (void)gotoRemoveSelf
{
    [self pause];
    [self removeFromSuperview];
}
- (void)gotoShowInView:(UIView *)view withFrame:(CGRect)rect
{
    [view addSubview:self];
    [self mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(0);
        make.left.mas_equalTo(0);
        //        make.centerX.mas_equalTo(0);
        //        make.centerY.mas_equalTo(0);
        make.height.mas_equalTo(view.height);
        make.width.mas_equalTo(view.width);
    }];
}
-(void)dealloc {

    [self teadownPlayer];
}

-(void)teadownPlayer {
    [self cancelAutoFadeOutControlBar];
    [self.player shutdown];
    self.player = nil;
    [self removeMovieNotificationObservers];
    
}

@end
