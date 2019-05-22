//
//  CustomThreadPool.m
//  5-21-CustomThreadPool
//
//  Created by pmst on 2019/5/21.
//  Copyright © 2019 pmst. All rights reserved.
//

#import "CustomThreadPool.h"

@interface Worker ()
@property(nonatomic, strong)id<Runnable> task;
@property(nonatomic, strong)NSThread *thread;
// true-> 创建新的线程执行 从对队列里获取线程执行
@property(nonatomic, assign)BOOL isNewTask;
@property(nonatomic, weak)CustomThreadPool *pool;
@end

@implementation Worker
- (instancetype)initWithTask:(id<Runnable>)task
                   isNewTask:(BOOL)isNewTask
                        pool:(CustomThreadPool *)pool {
    self = [super init];
    
    if (self) {
        self.task = task;
        self.thread = [[NSThread alloc] initWithTarget:self selector:@selector(run) object:nil];
        self.isNewTask = isNewTask;
        self.pool = pool;
    }
    return self;
}

- (void)run {
    id<Runnable> task = nil;
    
    if (self.isNewTask) {
        task = self.task;
    }
    @try {
        while (task != nil || (task = [self.pool getTask]) != nil) {
            @try {
                [task run];
            } @catch (NSException *exception) {
                
            } @finally {
                // 任务执行完毕
                task = nil;
                int number = self.pool.totalTask--;
                if (number == 0) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"SHUTDOWN_NOTIFICATION" object:nil];
                }
            }
        }
    } @catch (NSException *exception) {
        
    } @finally {
       [self.pool.workers removeObject:self];
    }
    
}

- (void)startTask {
    [self.thread start];
}

- (void)close{
    [self.thread cancel];
}
@end

@interface BlockingQueue ()
@property(nonatomic, strong)NSMutableArray *queue;
@property(nonatomic, assign)int capacity;
@end

@implementation BlockingQueue
- (instancetype)initWithCapacity:(int)capacity {
    self = [super init];
    
    if (self) {
        self.queue = [NSMutableArray new];
        self.capacity = capacity;
    }
    return self;
}

- (BOOL)offer:(id)obj {
    if (self.queue.count >= _capacity) {
        return false;
    }
    [self.queue addObject:obj];
    return true;
}

- (void)put:(id)obj {
    [self.queue addObject:obj];
}

- (id)take {
    id first = self.queue.firstObject;
    [self.queue removeObject:first];
    return first;
}
@end

@interface CustomThreadPool ()

@end

@implementation CustomThreadPool

- (instancetype)initWithMiniSize:(int)miniSize
                         maxSize:(int)maxSize
                   keepAliveTime:(CFTimeInterval)keepAliveTime
                            unit:(int)unit
                       workQueue:(BlockingQueue *)workQueue {
    self = [super init];
    
    if (self) {
        self.miniSize = miniSize;
        self.maxSize = maxSize;
        self.keepAliveTime = keepAliveTime;
        self.unit = unit;
        self.workQueue = workQueue;
        self.totalTask = 0;
        
        self.workers = [NSMutableSet new];
    }
    return self;
}

- (void)execute:(id<Runnable>)runnable {
    
    if (runnable == nil) {
        @throw [NSException exceptionWithName:@"线程池异常" reason:@"执行任务为空，异常！" userInfo:nil];
    }
    
    if (self.isShutDown) {
        NSLog(@"线程池已经关闭，不能再提交任务");
        return;
    }
    
    // 提交的线程 计数
    self.totalTask++;
    
    // 小于最小线程数时新建线程 规定线程池保证维护 miniSize 个线程
    if (self.workers.count < _miniSize) {
        [self addWorker:runnable];
        return;
    }
    
    BOOL offer = [self.workQueue offer:runnable];
    
    // 将任务写入到串行队列中等待被执行，如果超过了串行工作队列能执行的最大任务个数
    // 那么会写入失败，我们选择创建新的线程直接执行这个任务
    if (!offer) {
        // 创建新的线程执行
        if (self.workers.count < self.maxSize) {
            [self addWorker:runnable];
            return;
        } else {
            NSLog(@"超过最大线程数");
            @try {
                [self.workQueue put:runnable];
            } @catch (NSException *exception) {
                
            } @finally {
                
            }
        }
    }
    
}

- (id<Runnable>)getTask {
    if (self.isShutDown && self.totalTask == 0) {
        return nil;
    }
    
    /// 加锁
    
    @try {
        id<Runnable> task = nil;
        if (self.workers.count > self.miniSize) {
            // 大于核心线程时 需要用保活时间获取
            task = [self.workQueue take];
        } else {
            task = [self.workQueue take];
        }
        return task;
    } @catch (NSException *exception) {
        return nil;
    } @finally {
        /// 解锁
    }
    
    return nil;
}

- (void)shutdown {
    self.isShutDown = true;
    
}

- (void)shutdownNow {
    self.isShutDown = true;
}

- (void)tryClose:(BOOL)isTry {
    if (!isTry) {
        [self closeAllTask];
    } else {
        if (self.isShutDown && self.totalTask == 0 ){
            [self closeAllTask];
        }
    }
}

- (void)closeAllTask {
    for (Worker *worker in self.workers) {
        [worker close];
    }
}

- (int)getWorkerCount {
    return (int)self.workers.count;
}

// 添加任务 需要加锁 runnable 任务
// 难道每次都要创建一个线程？？？？？？？？？？？？？
- (void)addWorker:(id<Runnable>)task {
    Worker *worker = [[Worker alloc] initWithTask:task isNewTask:true pool:self];
    [worker startTask];
    [self.workers addObject:worker];
}

@end
