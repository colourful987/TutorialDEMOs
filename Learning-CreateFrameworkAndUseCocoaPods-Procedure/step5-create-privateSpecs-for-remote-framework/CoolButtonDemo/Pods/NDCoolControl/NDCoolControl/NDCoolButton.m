//
//  NDCoolButton.m
//  CoolButton
//
//  Created by pmst on 2019/2/16.
//  Copyright © 2019 pmst. All rights reserved.
//

#import "NDCoolButton.h"
#import "UIView+PathCreator.h"

@implementation NDCoolButton

- (void)setHue:(CGFloat)hue {
    _hue = hue;
    [self setNeedsDisplay];
}

- (void)setSaturation:(CGFloat)saturation {
    _saturation = saturation;
    [self setNeedsDisplay];
}

- (void)setBrightness:(CGFloat)brightness {
    _brightness = brightness;
    [self setNeedsDisplay];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    
    if (self) {
        _hue = 0.5;
        _saturation = 0.5;
        _brightness = 0.5;
    }
    
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    if (self) {
        _hue = 0.5;
        _saturation = 0.5;
        _brightness = 0.5;
    }
    
    return self;
}

- (instancetype)init {
    self = [super init];
    
    if (self) {
        _hue = 0.5;
        _saturation = 0.5;
        _brightness = 0.5;
    }
    
    return self;
}

- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGFloat actualBrightness = _brightness;
    
    if (self.state == UIControlStateHighlighted) {
        actualBrightness -= 0.1; // 高亮状态下更改颜色
    }
    
    UIColor *outerColor = [UIColor colorWithHue:_hue saturation:_saturation brightness:_brightness alpha:1.0];
    UIColor *shadowColor = [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:0.5];
    
    CGFloat outerMarign = 5.f;
    CGRect outerRect = CGRectInset(rect, outerMarign, outerMarign);
    
    // ================== 外圈 ==================
    CGPathRef outerPath = [self createRoundedRectPath:outerRect radius:6.0];
    
    if (self.state != UIControlStateHighlighted) {
        // 在normal状态下才绘制阴影
        CGContextSaveGState(context);
        CGContextSetFillColorWithColor(context, outerColor.CGColor);
        CGContextSetShadowWithColor(context, CGSizeMake(0, 2), 3.0, shadowColor.CGColor);
        CGContextAddPath(context, outerPath);
        CGContextFillPath(context);
        CGContextRestoreGState(context);
    }
    // ==========================================
    
    // 路径描边 渐变色
    UIColor *outerTop = [UIColor colorWithHue:_hue saturation:_saturation brightness:actualBrightness alpha:1.0];
    UIColor *outerBottom = [UIColor colorWithHue:_hue saturation:_saturation brightness:actualBrightness * 0.8 alpha:1.0];
    
    CGContextSaveGState(context);
    CGContextAddPath(context, outerPath);
    CGContextClip(context);
    // 绘制外圈的一次渐变图
    [self drawGlossAndGradient:context rect:outerRect startColor:outerTop endColor:outerBottom];
    CGContextRestoreGState(context);
    
    UIColor *innerTop = [UIColor colorWithHue:_hue saturation:_saturation brightness:actualBrightness * 0.9 alpha:1.0];
    UIColor *innerBottom = [UIColor colorWithHue:_hue saturation:_saturation brightness:actualBrightness * 0.7 alpha:1.0];
    
    CGFloat innerMargin = 3.0;
    CGRect innerRect = CGRectInset(outerRect, innerMargin, innerMargin);
    CGPathRef innerPath = [self createRoundedRectPath:innerRect radius:6.0];
    
    CGContextSaveGState(context);
    CGContextAddPath(context, innerPath);
    CGContextClip(context);
    // 绘制内圈的一次渐变图
    [self drawGlossAndGradient:context rect:innerRect startColor:innerTop endColor:innerBottom];
    CGContextRestoreGState(context);
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    
    [self setNeedsDisplay];
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesMoved:touches withEvent:event];
    
    [self setNeedsDisplay];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesEnded:touches withEvent:event];
    
    [self setNeedsDisplay];
    
    [self performSelector:@selector(hesitateUpdate) withObject:nil afterDelay:0.1];
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesCancelled:touches withEvent:event];
    
    [self setNeedsDisplay];
    
    [self performSelector:@selector(hesitateUpdate) withObject:nil afterDelay:0.1];
}

- (void)hesitateUpdate {
    [self setNeedsDisplay];
}

@end
