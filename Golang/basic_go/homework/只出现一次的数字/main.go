package main

import "fmt"

func main() {
	fmt.Println(singleNumber([]int{2,2,1}))
	fmt.Println(singleNumber([]int{4,1,2,1,2}))
	fmt.Println(singleNumber([]int{1}))
}

func singleNumber(nums []int) int {
	for i := range nums{
		for j := range nums{
			if i == j {continue}
			if nums[i] == nums[j] {break}
			if j == len(nums) -1 {return nums[i]}
		}
	}
	return nums[len(nums) - 1]
}
