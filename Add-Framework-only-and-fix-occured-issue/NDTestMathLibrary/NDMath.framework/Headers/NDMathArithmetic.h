//
//  NDMathArithmetic.h
//  NDMath
//
//  Created by pmst on 2019/2/21.
//  Copyright © 2019 pmst. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NDMathArithmetic : NSObject

- (int)add:(int)lhs rhs:(int)rhs;

- (int)min:(int)lhs rhs:(int)rhs;

- (int)mul:(int)lhs rhs:(int)rhs;

- (int)div:(int)lhs rhs:(int)rhs;
@end

NS_ASSUME_NONNULL_END
