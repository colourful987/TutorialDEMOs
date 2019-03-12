//
//  main.c
//  SortAlgorithm
//
//  Created by pmst on 2019/3/10.
//  Copyright © 2019 pmst. All rights reserved.
//

#include <stdio.h>
#include "sort_library.h"

int main(int argc, const char * argv[]) {
    // 堆排序
    int mock_case1[11] = {10,7,8,17,4,3,5,1,12,11,6};
    heap_sort(mock_case1, 11);
    
    // 归并
    int mock_case2[11] = {10,7,8,17,4,3,5,1,12,11,6};
    int tmp_case2[11] = {0,0,0,0,0,0,0,0,0,0,0};
    merge_sort(mock_case2, tmp_case2, 0, 10);
    
    // 快排
    int mock_case3[11] = {10,7,8,17,4,3,5,1,12,11,6};
    quick_sort(mock_case3, 0, 10);
    
    // 冒泡
    int mock_case4[11] = {10,7,8,17,4,3,5,1,12,11,6};
    bubble_sort(mock_case4,11);
    
    for (int i = 0; i < 11; i++) {
        printf("%d ",mock_case1[i]);
    }
    printf("\n");
    for (int i = 0; i < 11; i++) {
        printf("%d ",mock_case2[i]);
    }
    printf("\n");
    for (int i = 0; i < 11; i++) {
        printf("%d ",mock_case3[i]);
    }
    printf("\n");
    for (int i = 0; i < 11; i++) {
        printf("%d ",mock_case4[i]);
    }
    printf("\n");
    
    return 0;
}
