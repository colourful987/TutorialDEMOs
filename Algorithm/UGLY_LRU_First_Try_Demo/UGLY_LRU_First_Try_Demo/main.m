//
//  main.m
//  UGLY_LRU_First_Try_Demo
//
//  Created by pmst on 2019/3/7.
//  Copyright © 2019 pmst. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LRULinkedNode : NSObject
@property(nonatomic, strong)LRULinkedNode *prevNode;
@property(nonatomic, strong)LRULinkedNode *nextNode;
@property(nonatomic, strong)id value;
@property(nonatomic, strong)NSString *key;
@end

@implementation LRULinkedNode

- (NSString *)description {
    return [NSString stringWithFormat:@"prevNode:%@, self:%@, nextNode:%@", _prevNode.key ?:@"None",self.key,_nextNode.key?:@"None"];
}
@end

@interface LRULinkedList : NSObject
@property(nonatomic, strong)NSMutableDictionary *indexTable;
@property(nonatomic, strong)LRULinkedNode *head;
@property(nonatomic, strong)LRULinkedNode *tail;
@property(nonatomic, assign)int limit;
@property(nonatomic, assign)int totalCount;
@end

@implementation LRULinkedList

- (instancetype)init {
    self = [super init];
    
    if (self) {
        _indexTable = [NSMutableDictionary new];
        _limit = 5;
        _totalCount = 0;
    }
    return self;
}

- (void)addObject:(id)object forKey:(NSString *)key {
    if (_head == nil) {
        // 说明是第一个
        LRULinkedNode *node = [LRULinkedNode new];
        node.prevNode = nil;
        node.nextNode = nil;
        node.value = object;
        node.key = key;
        self.head = node;
        self.tail = node;
        self.indexTable[key] = node;
        self.totalCount = 1;
        return;
    }
    
    // 从缓存中找
    LRULinkedNode *node = _indexTable[key];
    
    if (node) {
        
        if (node.nextNode == nil) {
            // 尾
            node.prevNode.nextNode = nil;
            self.tail = node.prevNode;
            node.nextNode = self.head;
            node.prevNode = nil;
            self.head = node;
        } else if (node.prevNode == nil){
            // 已经为头 do nothing
        } else {
            // 那么从现有位置bring到头部
            LRULinkedNode *prevNode = node.prevNode;
            LRULinkedNode *nextNode = node.nextNode;
            prevNode.nextNode = nextNode;
            nextNode.prevNode = prevNode;
            node.nextNode = self.head;
            self.head.prevNode = node;
            node.prevNode = nil;
            self.head = node;
        }
        
    } else {
        // 重新创建一个 设为头部
        LRULinkedNode *node = [LRULinkedNode new];
        node.nextNode = self.head;
        self.head.prevNode = node;
        node.prevNode = nil;
        node.value = object;
        node.key = key;
        self.head = node;
        self.indexTable[key] = node;
        self.totalCount += 1;
    }
    
    if (self.totalCount > self.limit) {
        node = self.tail.prevNode;
        [self.indexTable removeObjectForKey:self.tail.key];
        node.nextNode = nil;
        self.tail = node;
    }
    
    // 遍历链表
    node = self.head;
    NSMutableString *linkSTR = [@"" mutableCopy];
    
    while (node != nil) {
        [linkSTR appendString:node.key];
        [linkSTR appendString:@"->"];
        node = node.nextNode;
    }
    NSLog(@"当前链表：%@",linkSTR);
}


@end

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        LRULinkedList *lru = [LRULinkedList new];
        
        [lru addObject:@"11" forKey:@"11"];
        [lru addObject:@"22" forKey:@"22"];
        [lru addObject:@"33" forKey:@"33"];
        [lru addObject:@"22" forKey:@"22"];
        [lru addObject:@"44" forKey:@"44"];
        [lru addObject:@"11" forKey:@"11"];
        [lru addObject:@"11222" forKey:@"11222"];
        [lru addObject:@"123" forKey:@"123"];
        [lru addObject:@"22" forKey:@"22"];
    }
    return 0;
}
