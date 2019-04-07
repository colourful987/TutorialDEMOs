//
//  quick_sort.c
//  SortAlgorithm
//
//  Created by pmst on 2019/3/12.
//  Copyright © 2019 pmst. All rights reserved.
//

#include "quick_sort.h"

void dynamic_sort(int a[],int n){
    if (n < 10) {
        for (int i = 0; i < n; i++)
            for (int j = i + 1; j < n; j++)
                if (a[i] > a[j])
                    swap(a + i, a + j);
    } else if (n > 1) {
        swap(a, a + rand() % n);
        int pivot = a[0];
        int i = -1, j = n;
        
        while (i < j) {
            do i++; while (a[i] < pivot);
            do j--; while (a[j] > pivot);
            if (i < j) swap(a + i, a + j);
        }
        j++;
        sort(a, j);
        sort(a + j, n - j);
    }
    
}

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
        array[i] = array[j]; // 从最右边找到一个小于基准值key的值，填补到i处
        
        while (i<j && array[i] <= key) {
            i++;
        }
        array[j] = array[i];
    }
    
    array[i] = key;
    
    quick_sort(array,left,i);
    quick_sort(array,i+1,right);
    
}
