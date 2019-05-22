//
//  ViewController.m
//  5-21-CustomThreadPool
//
//  Created by pmst on 2019/5/21.
//  Copyright © 2019 pmst. All rights reserved.
//

#import "ViewController.h"
#import "CustomThreadPool.h"

@interface LogNumberJob : NSObject<Runnable>
@property(nonatomic, assign)int number;
@end

@implementation LogNumberJob

- (instancetype)initWithNumber:(int)number {
    self = [super init];
    
    if (self) {
        self.number = number;
    }
    return self;
}

- (void)run {
    
    NSLog(@"Thread INFO:%@ 执行任务编号 number is %d",[NSThread currentThread],self.number);
}

@end


@interface ViewController ()
@property(nonatomic, strong)CustomThreadPool *pool;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    BlockingQueue *queue = [[BlockingQueue alloc] initWithCapacity: 10];
    CustomThreadPool *pool = [[CustomThreadPool alloc] initWithMiniSize:3 maxSize:5 keepAliveTime:1 unit:1 workQueue:queue];
    self.pool = pool;
    for (int i = 0; i < 10; i++) {
        [pool execute:[[LogNumberJob alloc] initWithNumber:i]];
    }
    
    NSLog(@"================= 休眠前线程池活跃数=%d ===================",pool.workers.count);
    [NSThread sleepForTimeInterval:5];
    NSLog(@"================= 休眠后线程池活跃数=%d ===================",pool.workers.count);
    
    for (int i = 10; i < 13; i++){
        [pool execute:[[LogNumberJob alloc] initWithNumber:i]];
    }
}


@end
