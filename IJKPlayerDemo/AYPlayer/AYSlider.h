//
//  AYSlider.h
//  AiYanProject
//
//  Created by qx_mjn on 16/9/23.
//  Copyright © 2016年 Apple. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AYValuePoUpView.h"

@protocol AYSliderDelegate;

@interface AYSlider : UISlider
// present the popUpView manually, without touch event.
- (void)showPopUpViewAnimated:(BOOL)animated;
// the popUpView will not hide again until you call 'hidePopUpViewAnimated:'
- (void)hidePopUpViewAnimated:(BOOL)animated;
// setting the value of 'popUpViewColor' overrides 'popUpViewAnimatedColors' and vice versa
// the return value of 'popUpViewColor' is the currently displayed value
// this will vary if 'popUpViewAnimatedColors' is set (see below)
@property (strong, nonatomic) UIColor *popUpViewColor;

// pass an array of 2 or more UIColors to animate the color change as the slider moves
@property (strong, nonatomic) NSArray *popUpViewAnimatedColors;
// the above @property distributes the colors evenly across the slider
// to specify the exact position of colors on the slider scale, pass an NSArray of NSNumbers
- (void)setPopUpViewAnimatedColors:(NSArray *)popUpViewAnimatedColors withPositions:(NSArray *)positions;
// changes the left handside of the UISlider track to match current popUpView color
// the track color alpha is always set to 1.0, even if popUpView color is less than 1.0
@property (strong, nonatomic, readonly) AYValuePoUpView *popUpView;
// cornerRadius of the popUpView, default is 4.0
@property (nonatomic) CGFloat popUpViewCornerRadius;
// arrow height of the popUpView, default is 13.0
@property (nonatomic) CGFloat popUpViewArrowLength;
// width padding factor of the popUpView, default is 1.15
@property (nonatomic) CGFloat popUpViewWidthPaddingFactor;
// height padding factor of the popUpView, default is 1.1
@property (nonatomic) CGFloat popUpViewHeightPaddingFactor;
// changes the left handside of the UISlider track to match current popUpView color
// the track color alpha is always set to 1.0, even if popUpView color is less than 1.0
@property (nonatomic) BOOL autoAdjustTrackColor; // (default is YES)
// delegate is only needed when used with a TableView or CollectionView - see below
@property (weak, nonatomic) id<AYSliderDelegate> delegate;
/** 设置时间 */
- (void)setText:(NSString *)text;
/** 设置预览图 */
- (void)setImage:(UIImage *)image;
@end

// when embedding an ASValueTrackingSlider inside a TableView or CollectionView
// you need to ensure that the cell it resides in is brought to the front of the view hierarchy
// to prevent the popUpView from being obscured
@protocol AYSliderDelegate <NSObject>
- (void)sliderWillDisplayPopUpView:(AYSlider *)slider;

@optional
- (void)sliderWillHidePopUpView:(AYSlider *)slider;
- (void)sliderDidHidePopUpView:(AYSlider *)slider;
@end
