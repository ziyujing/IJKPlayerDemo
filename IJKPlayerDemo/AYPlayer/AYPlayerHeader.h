//
//  AYPlayerHeader.h
//  AiYanProject
//
//  Created by KUN on 16/9/18.
//  Copyright © 2016年 Apple. All rights reserved.
//

#ifndef AYPlayerHeader_h
#define AYPlayerHeader_h

#import "AYPlayerControlView.h"
//#import "AYPlayer.h"
#import "Masonry.h"
#import "UIViewExt.h"

#define SCREEN_WIDTH                    ([UIScreen mainScreen].bounds.size.width)
#define SCREEN_HEIGHT                   ([UIScreen mainScreen].bounds.size.height)
#define iPhone4s ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(640, 960), [[UIScreen mainScreen] currentMode].size) : NO)
// 监听TableView的contentOffset
#define kZFPlayerViewContentOffset          @"contentOffset"
#define AYPlayerImage(file)            [UIImage imageNamed:(file)]

// 图片路径
#define ZFPlayerSrcName(file)               [@"ZFPlayer.bundle" stringByAppendingPathComponent:file]
#define ZFPlayerFrameworkSrcName(file)      [@"Frameworks/ZFPlayer.framework/ZFPlayer.bundle" stringByAppendingPathComponent:file]
#define AYPlayerImageFile(file)                 [UIImage imageNamed:ZFPlayerSrcName(file)] ? :[UIImage imageNamed:ZFPlayerFrameworkSrcName(file)]
#define UIScreen16_9 CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width , [UIScreen mainScreen].bounds.size.width * 9 / 16)

#endif /* AYPlayerHeader_h */
