//
//  NDMathArithmetic.m
//  NDMath
//
//  Created by pmst on 2019/2/21.
//  Copyright © 2019 pmst. All rights reserved.
//

#import "NDMathArithmetic.h"

@implementation NDMathArithmetic

- (int)add:(int)lhs rhs:(int)rhs {
    return lhs + rhs;
}

- (int)min:(int)lhs rhs:(int)rhs {
    return lhs - rhs;
}

- (int)mul:(int)lhs rhs:(int)rhs {
    return lhs * rhs;
}

- (int)div:(int)lhs rhs:(int)rhs {
    return lhs / rhs;
}
@end
