//
//  UIView+PathCreator.h
//  CoolButton
//
//  Created by pmst on 2019/2/17.
//  Copyright © 2019 pmst. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIView (PathCreator)

- (CGMutablePathRef)createRoundedRectPath:(CGRect)rect radius:(CGFloat)radius;

- (void)drawLinearGradient:(CGContextRef)context rect:(CGRect)rect startColor:(UIColor *)startColor endColor:(UIColor *)endColor;

- (void)drawGlossAndGradient:(CGContextRef)context rect:(CGRect)rect startColor:(UIColor *)startColor endColor:(UIColor *)endColor;
@end

NS_ASSUME_NONNULL_END
