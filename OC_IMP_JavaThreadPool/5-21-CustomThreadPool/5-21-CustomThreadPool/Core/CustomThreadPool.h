//
//  CustomThreadPool.h
//  5-21-CustomThreadPool
//
//  Created by pmst on 2019/5/21.
//  Copyright © 2019 pmst. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol Runnable <NSObject>

- (void)run;

@end

@class CustomThreadPool;

@interface Worker : NSObject

- (instancetype)initWithTask:(id<Runnable>)task
                   isNewTask:(BOOL)isNewTask
                        pool:(CustomThreadPool *)pool;

- (void)startTask;
@end

@interface BlockingQueue : NSObject

- (instancetype)initWithCapacity:(int)capacity;

- (BOOL)offer:(id)obj;

- (void)put:(id)obj;

- (id)take;
@end

@interface CustomThreadPool : NSObject
/// 最小线程数，核心线程数
@property(nonatomic, assign)int miniSize;
/// 最大线程数
@property(nonatomic, assign)int maxSize;
/// 线程需要被回收的时间
@property(nonatomic, assign)CFTimeInterval keepAliveTime;
/// 线程时间单位
@property(nonatomic, assign)CFTimeInterval unit;
/// 工作阻塞队列 存放所有的执行任务
@property(nonatomic, strong)BlockingQueue *workQueue;
/// 记录维护的线程 是否用字典会好一些
@property(nonatomic, strong)NSMutableSet<Worker *> *workers;
/// 是否关闭线程池标识
@property(atomic, assign)BOOL isShutDown;
/// 总共任务数
@property(atomic, assign)int totalTask;

// 通知接口用NSNotification

- (instancetype)initWithMiniSize:(int)miniSize
                         maxSize:(int)maxSize
                   keepAliveTime:(CFTimeInterval)keepAliveTime
                            unit:(int)unit
                       workQueue:(BlockingQueue *)workQueue;

- (void)execute:(id<Runnable>)runnable;

- (id<Runnable>)getTask;
@end
