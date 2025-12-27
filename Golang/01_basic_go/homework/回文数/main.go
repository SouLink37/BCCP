package main

import "fmt"

func main() {
	fmt.Println(isPalindrome(121))
	fmt.Println(isPalindrome(-121))
	fmt.Println(isPalindrome(10))	
}

func isPalindrome(x int) bool {
    if x < 0 {
        return false
    }

    slice_int := []int{}

    for i := 0; x > 0; i++{
        slice_int = append(slice_int, x % 10)
        x /= 10
    }

    for left := range slice_int {
        right := len(slice_int) - left -1
        if left >= right {
            break
        }
        if slice_int[left] != slice_int[right] {
            return false
        }
    }
    return true
}