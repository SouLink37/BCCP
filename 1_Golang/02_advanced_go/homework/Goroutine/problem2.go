package main

import (
	"fmt"
	"time"
)

func problem2() {
	done := make(chan int)
	task := []func() int{
		func() int { return fib(10) },
		func() int { return fib(20) },
		func() int { return fib(30) },
		func() int { return fib(40) },
		func() int { return fib(50) },
	}

	for _, task := range task {
		go func() {
			start := time.Now()
			task()
			elapsed := time.Since(start)
			fmt.Println(elapsed)
			done <- 1
		}()
	}

	for range len(task) {
		<-done
	}
}

func fib(num int) int {
	if num < 2 {
		return num
	}

	return fib(num-1) + fib(num-2)
}
