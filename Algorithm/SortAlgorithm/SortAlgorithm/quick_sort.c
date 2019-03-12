//
//  quick_sort.c
//  SortAlgorithm
//
//  Created by pmst on 2019/3/12.
//  Copyright © 2019 pmst. All rights reserved.
//

#include "quick_sort.h"

void quick_sort(int array[],int left,int right) {
    if(left >= right) {
        return ;
    }
    
    int key = array[left];
    
    int i = left;
    int j = right;
    
    while (i < j) {
        while (i<j && array[j] >= key) {
            j--;
        }
        array[i] = array[j]; // 从最右边找到一个大于基准值key的值，填补到i处
        
        while (i<j && array[i] <= key) {
            i++;
        }
        array[j] = array[i];
    }
    
    array[i] = key;
    
    quick_sort(array,left,i);
    quick_sort(array,i+1,right);
    
}
