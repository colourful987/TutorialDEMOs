//
//  merge_sort.c
//  SortAlgorithm
//
//  Created by pmst on 2019/3/12.
//  Copyright © 2019 pmst. All rights reserved.
//

#include "merge_sort.h"


void p_merge(int arr[], int temp[], int left, int middle, int right){
    int i = left;
    int j = middle+1;
    int k = 0;
    while (i <= middle && j <= right) {
        if (arr[i] <= arr[j]) {
            temp[k++] = arr[i++];
        } else {
            temp[k++] = arr[j++];
        }
    }
    
    while (i <= middle) {
        temp[k++] = arr[i++];
    }
    
    while (j <= right) {
        temp[k++] = arr[j++];
    }
    
    k = 0;
    while (left <= right) {
        arr[left++] = temp[k++];
    }
}

void merge_sort(int arr[], int temp[], int left, int right) {
    if (left>=right) {
        return;
    }
    
    int middle = (left+right)/2;
    
    merge_sort(arr, temp, left, middle);
    merge_sort(arr, temp, middle+1, right);
    
    p_merge(arr, temp, left, middle, right);
    
}
