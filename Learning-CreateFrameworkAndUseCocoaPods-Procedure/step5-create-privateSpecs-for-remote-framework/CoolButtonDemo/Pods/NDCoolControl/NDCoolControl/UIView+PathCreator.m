//
//  UIView+PathCreator.m
//  CoolButton
//
//  Created by pmst on 2019/2/17.
//  Copyright © 2019 pmst. All rights reserved.
//

#import "UIView+PathCreator.h"

@implementation UIView (PathCreator)

/// Explain of `CGPathAddArcToPoint`: [diagrammatize](https://stackoverflow.com/questions/78127/cgpathaddarc-vs-cgpathaddarctopoint)
- (CGMutablePathRef)createRoundedRectPath:(CGRect)rect radius:(CGFloat)radius {
    CGMutablePathRef path = CGPathCreateMutable();
    CGPoint midTopPoint = CGPointMake(CGRectGetMidX(rect), CGRectGetMinY(rect));
    CGPathMoveToPoint(path, 0, midTopPoint.x, midTopPoint.y);
    
    CGPoint topRightPoint = CGPointMake(CGRectGetMaxX(rect),CGRectGetMinY(rect));
    CGPoint bottomRightPoint = CGPointMake(CGRectGetMaxX(rect),CGRectGetMaxY(rect));
    CGPoint bottomLeftPoint = CGPointMake(CGRectGetMinX(rect),CGRectGetMaxY(rect));
    CGPoint topLeftPoint = CGPointMake(CGRectGetMinX(rect),CGRectGetMinY(rect));
    
    CGPathAddArcToPoint(path, 0, topRightPoint.x, topRightPoint.y, bottomRightPoint.x, bottomRightPoint.y, radius);
    
    CGPathAddArcToPoint(path, 0, bottomRightPoint.x, bottomRightPoint.y, bottomLeftPoint.x, bottomLeftPoint.y, radius);
    
    CGPathAddArcToPoint(path, 0, bottomLeftPoint.x, bottomLeftPoint.y, topLeftPoint.x, topLeftPoint.y, radius);
    
    CGPathAddArcToPoint(path, 0, topLeftPoint.x, topLeftPoint.y, topRightPoint.x, topRightPoint.y, radius);
    
    CGPathCloseSubpath(path);
    
    return path;
}

- (void)drawLinearGradient:(CGContextRef)context rect:(CGRect)rect startColor:(UIColor *)startColor endColor:(UIColor *)endColor {
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGFloat colorLocations[2] = {0.0, 1.0};
    CFArrayRef colors = (__bridge CFArrayRef)(@[(id)startColor.CGColor, (id)endColor.CGColor]);
    CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, colors, colorLocations);
    
    CGPoint startPoint = CGPointMake(CGRectGetMidX(rect), CGRectGetMinY(rect));
    CGPoint endPoint = CGPointMake(CGRectGetMidX(rect), CGRectGetMaxY(rect));
    
    CGContextSaveGState(context);
    CGContextAddRect(context, rect);
    CGContextClip(context);
    CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, 0);
    CGContextRestoreGState(context);
}

- (void)drawGlossAndGradient:(CGContextRef)context rect:(CGRect)rect startColor:(UIColor *)startColor endColor:(UIColor *)endColor {
    // 先用实际颜色将整个rect区域绘制一次渐变
    [self drawLinearGradient:context rect:rect startColor:startColor endColor:endColor];
    
    // 白色绘制上半部分 alpha 都是透明色，从0.35 -> 0.1
    // 搞个类似遮盖
    UIColor *glossColor1 = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.35];
    UIColor *glossColor2 = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.1];
    
    CGRect topHalf = CGRectMake(rect.origin.x, rect.origin.y, CGRectGetWidth(rect), CGRectGetHeight(rect)/2.f);
    
    [self drawLinearGradient:context rect:topHalf startColor:glossColor1 endColor:glossColor2];
}
@end
