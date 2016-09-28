//
//  AYPlayer.h
//  AiYanProject
//
//  Created by KUN on 16/9/18.
//  Copyright © 2016年 Apple. All rights reserved.
//

#import <UIKit/UIKit.h>

// playerLayer的填充模式（默认：等比例填充，直到一个维度到达区域边界）
typedef NS_ENUM(NSInteger, AYPlayerLayerGravity) {
    AYPlayerLayerGravityFill,           // 非均匀模式。两个维度完全填充至整个视图区域
    AYPlayerLayerGravityAspectFit,     // 等比例填充，直到一个维度到达区域边界
    AYPlayerLayerGravityAspectFill  // 等比例填充，直到填充满整个视图区域，其中一个维度的部分区域会被裁剪
};


@interface AYPlayer : UIView

/** 视频URL */
@property (nonatomic, strong) NSURL                *videoURL;
/** 配置 */
@property (nonatomic, strong) NSDictionary         *options;
/** 设置playerLayer的填充模式 */
@property (nonatomic, assign) AYPlayerLayerGravity playerLayerGravity;
/** 播放前占位图片的名称*/
@property (nonatomic, copy  ) NSString             *placeholderImageName;
/** 是否被用户暂停 */
@property (nonatomic, assign, readonly) BOOL       isPauseByUser;
/** 是否隐藏返回按钮 */
@property (nonatomic, assign) BOOL                   isHideBackBtn; // new add
/** 从xx秒开始播放视频跳转 */
@property (nonatomic, assign) NSInteger            seekTime;
/** 是否显示controlView*/
@property (nonatomic, assign) BOOL                isHideControlView;
/** 当前播放的时间 */
@property (nonatomic, assign, readonly)  CGFloat currentTime;
/** 总时长 */
@property (nonatomic, assign, readonly)  CGFloat totalTime;
/** 总时长帧数 */
@property (nonatomic, assign, readonly)  CGFloat totalDuRation;
/** 总时长频率 */
@property (nonatomic, assign, readonly)  CGFloat totalTimescale;
/** 音量 */
@property (nonatomic, assign)  CGFloat volume;
/** 是否为全屏 */
@property (nonatomic, assign) BOOL                   isFullScreen;

/**
 *  单例，用于列表cell上多个视频
 *
 *  @return AYPlayer
 */
+ (instancetype)sharedPlayerView;

- (id)initWithContentURL:(NSURL *)aUrl withOptions:(NSDictionary *)options withSuperView:(UIView *)videoView;

- (void)prepareToPlay;
- (void)autoToplay;
- (void)play;
- (void)pause;
- (void)stop;
- (BOOL)isPlaying;
- (void)setPauseInBackground:(BOOL)pause;
-(void)teadownPlayer;
- (void)gotoFull;
/**销毁视图**/
- (void)gotoDeallocSelf;
/**移除视图**/
- (void)gotoRemoveSelf;
/**添加视图**/
- (void)gotoShowInView:(UIView *)view withFrame:(CGRect)rect;
/**
 *  取消延时隐藏controlView的方法,在ViewController的delloc方法中调用
 *  用于解决：刚打开视频播放器，就关闭该页面，maskView的延时隐藏还未执行。
 */
- (void)cancelAutoFadeOutControlBar;

/**
 *  player添加到cell上
 *
 *  @param cell 添加player的cellImageView
 */
- (void)addPlayerToCellImageView:(UIImageView *)imageView;
/**
 *  用于cell上播放player
 *
 *  @param videoURL  视频的URL
 *  @param tableView tableView
 *  @param indexPath indexPath
 *  @param ImageViewTag ImageViewTag
 */
- (void)setVideoURL:(NSURL *)videoURL
      withTableView:(UITableView *)tableView
        AtIndexPath:(NSIndexPath *)indexPath
   withImageViewTag:(NSInteger)tag;

@end
