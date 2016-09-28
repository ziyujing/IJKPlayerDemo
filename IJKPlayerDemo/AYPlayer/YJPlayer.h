//
//  YJPlayer.h
//  AiYanProject
//
//  Created by qx_mjn on 16/9/23.
//  Copyright © 2016年 Apple. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface YJPlayer : UIView
/** 视频URL */
@property (nonatomic, strong) NSURL                *videoURL;
/** 配置 */
@property (nonatomic, strong) NSDictionary         *options;

/** 播放前占位图片的名称*/
@property (nonatomic, copy  ) NSString             *placeholderImageName;
/** 是否被用户暂停 */
@property (nonatomic, assign, readonly) BOOL       isPauseByUser;
/** 是否隐藏返回按钮 */
@property (nonatomic, assign) BOOL                   isHideBackBtn; // new add
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


+ (instancetype)sharedPlayerView;

- (id)initWithContentURL:(NSURL *)aUrl
             withOptions:(NSDictionary *)options;

- (void)prepareToPlay;
- (void)autoToplay;
- (void)play;
- (void)pause;
- (void)stop;
- (BOOL)isPlaying;
- (void)setPauseInBackground:(BOOL)pause;
-(void)teadownPlayer;

@end
