package main

import "fmt"

func main() {
	fmt.Println(plusOne([]int{1,2,3}))
	fmt.Println(plusOne([]int{4,3,2,1}))
	fmt.Println(plusOne([]int{9}))
	fmt.Println(plusOne([]int{9,9,9}))
}

func plusOne(digits []int) []int {
    n := len(digits) - 1
                        
    for n >= 0 {
        if digits[n] == 9 {
            digits[n] = 0
            n--
        } else {
            break
        }
    }

    if n != -1 {
        digits[n]++
    } else {
        digits = append([]int{1}, digits...)
    }

    return digits
}
