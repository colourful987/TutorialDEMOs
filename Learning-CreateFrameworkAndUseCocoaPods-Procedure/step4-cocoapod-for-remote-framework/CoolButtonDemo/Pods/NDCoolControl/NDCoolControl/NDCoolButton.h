//
//  NDCoolButton.h
//  CoolButton
//
//  Created by pmst on 2019/2/16.
//  Copyright © 2019 pmst. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NDCoolButton : UIButton
@property(nonatomic, assign)CGFloat hue;
@property(nonatomic, assign)CGFloat saturation;
@property(nonatomic, assign)CGFloat brightness;

@end

NS_ASSUME_NONNULL_END
