package main

import "fmt"

func main() {
	num := 10076
	addTen(&num)
	fmt.Println(num)

	slice := []int{1, 2, 3, 4, 5}
	multiplyByTwo(&slice)
	fmt.Println(slice)
}

func addTen(num *int) {
	*num += 10
}

func multiplyByTwo(nums *[]int) {
	for i := range *nums {
		(*nums)[i] *= 2
	}
}
