package main

import (
	"fmt"
)

func problem1() {
	done := make(chan bool, 2)

	go func() {
		for i := 1; i < 10; i++ {
			if i%2 == 1 {
				fmt.Println("奇数: ", i)
			}
		}

		done <- true
	}()

	go func() {
		for i := 2; i <= 10; i++ {
			if i%2 == 0 {
				fmt.Println("偶数: ", i)
			}
		}

		done <- true
	}()

	<-done
	<-done
}
