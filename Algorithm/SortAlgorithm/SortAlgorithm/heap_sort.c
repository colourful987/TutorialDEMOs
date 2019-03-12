//
//  heap_sort.c
//  SortAlgorithm
//
//  Created by pmst on 2019/3/12.
//  Copyright © 2019 pmst. All rights reserved.
//

#include "heap_sort.h"

void swap(int arr[],int a ,int b){
    int temp=arr[a];
    arr[a] = arr[b];
    arr[b] = temp;
}

void convertToMaxHeap(int array[], int index, int count){
    int temp = array[index];
    
    for (int k = index * 2 + 1; k < count; k = k * 2 + 1) {
        /// index 父节点
        /// index * 2 + 1 左子节点
        /// index * 2 + 2 右子节点
        if (k+1 < count && array[k+1] > array[k]) {
            // 右节点
            k++;
        }
        
        // 交换最大值 swap
        if (array[k] > temp) {
            array[index] = array[k];
            index = k;
        } else {
            break;
        }
    }
    array[index] = temp; // 其实若真的存在要交换的 那么总是在交换顶端的那个
}

void heap_sort(int array[], int count){
    /// 使用数组作为存储的数据结构，首先是构建一个大顶堆
    /// 大顶堆规则：节点最多可以有2个子节点，父节点总是比子节点大
    /// 数组元素映射到二叉树如下：n(idx)
    ///                 n0
    ///           /             \
    ///         n1               n2
    ///       /    \            /  \
    ///     n3    n4         n5      n6
    ///    /  \   / \       / \     / \
    ///   n7  n8 n9 n10   n11 n12 n13 n14
    
    /// 先找到最后一片leaf的父节点，往回遍历
    /// 构建一个大顶堆先
    for (int i = count/2 - 1; i >= 0; i--) {
        convertToMaxHeap(array, i, count);
    }
    for (int j = count-1; j >= 0 ; j--) {
        swap(array, 0, j);
        convertToMaxHeap(array, 0, j-1);
    }
    
}
