package main

import "fmt"

func main() {   
    fmt.Println(removeDuplicates([]int{1,1,2}))   
    fmt.Println(removeDuplicates([]int{0,0,1,1,1,2,2,3,3,4}))                       
    fmt.Println(removeDuplicates([]int{1,2,3,4,5,6,7,8,9,10}))                     
}

func removeDuplicates(nums []int) int {
    for i := len(nums) -1; i > 0; {
        if nums[i] != nums[i - 1] {
            i--
        } else {
            nums = append(nums[:i], nums[i + 1:]...)
            i--
        }
    }
    return len(nums)
}