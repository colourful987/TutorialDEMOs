//
//  bubble_sort.c
//  SortAlgorithm
//
//  Created by pmst on 2019/3/12.
//  Copyright © 2019 pmst. All rights reserved.
//

#include "bubble_sort.h"

void bubble_swap(int array[],int lhs,int rhs) {
    int tmp = array[lhs];
    array[lhs] = array[rhs];
    array[rhs] = tmp;
}

void bubble_sort(int array[],int count){
    for (int i = 0; i < count; i++) {
        for (int j = 0; j < count - i -1; j++) {
            if (array[j] > array[j+1]) {
                bubble_swap(array, j, j+1);
            }
        }
    }
}
