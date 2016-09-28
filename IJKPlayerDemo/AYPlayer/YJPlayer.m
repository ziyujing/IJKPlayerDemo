//
//  YJPlayer.m
//  AiYanProject
//
//  Created by qx_mjn on 16/9/23.
//  Copyright © 2016年 Apple. All rights reserved.
//

#import "YJPlayer.h"
#import "AYPlayerHeader.h"
#import <IJKMediaFramework/IJKMediaFramework.h>


@interface YJPlayer () <UIGestureRecognizerDelegate>
/** 播放器 */
@property(atomic, retain,) id<IJKMediaPlayback> player;
/** 控制层View */
@property (nonatomic, strong) AYPlayerControlView    *controlView;

@property (nonatomic, strong) UITapGestureRecognizer *tap;
@property (nonatomic, strong) UITapGestureRecognizer *doubleTap;

/** 是否显示controlView*/
@property (nonatomic, assign) BOOL                   isMaskShowing;

@end

@implementation YJPlayer

+ (instancetype)sharedPlayerView {
    
    static YJPlayer *player = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        player = [[YJPlayer alloc]init];
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

- (id)initWithContentURL:(NSURL *)aUrl withOptions:(NSDictionary *)options {
    
    if (self = [super init]) {
        _videoURL = aUrl;
        _options = options;
        [self initialAYPlayer];
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
    [self.controlView.startBtn addTarget:self action:@selector(startAction:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)startAction:(UIButton *)button
{
    button.selected    = !button.selected;
    if (!button.selected) {
        [self play];
    } else {
        [self pause];
    }
}

- (void)initialAYPlayer{
    
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
//        make.top.leading.bottom.trailing.mas_equalTo(0);
        make.top.leading.trailing.bottom.equalTo(self);
    }];
    
    self.isMaskShowing = NO;
    [self installMovieNotificationObservers];
    [self animateShow];
}

- (void)prepareToPlay {
    if (self.player) {
        [self.player prepareToPlay];
    }
}

- (void)autoToplay {
    if (self.player) {
        self.player.shouldAutoplay = YES;
    }
}

- (void)play {
    if (![self.player isPlaying]) {
        [self.player play];
    }
}

-(void)pause {
    if ([self.player isPlaying]) {
        [self.player pause];
    }
}

-(void)stop {
    
    if (self.player) {
        [self.player stop];
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
    // 解决点击当前view时候响应其他控件事件
    self.tap.delaysTouchesBegan = YES;
    //    [self.tap requireGestureRecognizerToFail:self.doubleTap];
}

#pragma mark - Action

- (void)tapAction:(UITapGestureRecognizer *)gesture
{
    if (gesture.state == UIGestureRecognizerStateRecognized) {
        [self startAction:self.controlView.startBtn];
        
        //        self.isMaskShowing ? ([self hideControlView]) : ([self animateShow]);
    }
}

- (void)hideControlView
{
    if (!self.isMaskShowing) { return; }
    [UIView animateWithDuration:0.35 animations:^{
        [self.controlView hideControlView];
    }completion:^(BOOL finished) {
        self.isMaskShowing = NO;
    }];
}


- (void)animateShow
{
    if (self.isMaskShowing) { return; }
    [UIView animateWithDuration:0.35f animations:^{
        [self.controlView showControlView];
    } completion:^(BOOL finished) {
        self.isMaskShowing = YES;
    }];
}

- (AYPlayerControlView *)controlView {
    
    if (!_controlView) {
        _controlView = [[AYPlayerControlView alloc]init];
    }
    return _controlView;
}


- (void)layoutSubviews {
    [super layoutSubviews];
}


#pragma Install Notifiacation- -播放器依赖的相关监听

- (void)loadStateDidChange:(NSNotification*)notification {
    
    IJKMPMovieLoadState loadState = _player.loadState;
    
    if ((loadState & IJKMPMovieLoadStatePlaythroughOK) != 0) {
        NSLog(@"LoadStateDidChange: IJKMovieLoadStatePlayThroughOK: %d\n",(int)loadState);
    }else if ((loadState & IJKMPMovieLoadStateStalled) != 0) {
        NSLog(@"loadStateDidChange: IJKMPMovieLoadStateStalled: %d\n", (int)loadState);
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
            self.controlView.startBtn.selected = YES;
            [self startAction:self.controlView.startBtn];
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


-(void)dealloc {
    
    [self teadownPlayer];
}

-(void)teadownPlayer {
    [self.player shutdown];
    self.player = nil;
    [self removeMovieNotificationObservers];
}


@end
