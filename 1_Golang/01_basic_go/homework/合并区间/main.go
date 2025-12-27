package main

import (
    "fmt"
    "sort"
)

func main() {
    fmt.Println(merge([][]int{{1,3},{2,6},{8,10},{15,18}}))
    fmt.Println(merge([][]int{{1,4},{4,5}}))    
    fmt.Println(merge([][]int{{4,7},{1,4}}))
}

func merge(intervals [][]int) [][]int {
    sort.Slice(intervals, func (i int, j int) bool {
        return intervals[i][0] < intervals[j][0]
    })

    prev := intervals[0]
    res := [][]int{}
    for i := 1; i < len(intervals); i++ {
        if prev[1] >= intervals[i][0] {
            prev[1] = max(intervals[i][1], prev[1])
            continue
        } else {
            res = append(res, prev)
            prev = intervals[i]
        }
    }
    res = append(res, prev)
    return res
}
