package main

import "fmt"

func main() {   
    fmt.Println(twoSum([]int{2,7,11,15}, 9))
    fmt.Println(twoSum([]int{3,2,4}, 6))
    fmt.Println(twoSum([]int{3,3}, 6))
}

func twoSum(nums []int, target int) []int {
    sumap := map[int]int{}

    for index, num := range nums{
        _, ok := sumap[num]
        if !ok {
            sumap[target - num] = index
        } else {
            return []int{sumap[num], index}
        }
    }
    return []int{}
}