package main

import (
	"fmt"
)

func problem1() {
	ch := make(chan int)
	done := make(chan bool)

	go func() {
		for i := range 11 {
			ch <- i
		}
		close(ch)
	}()

	go func() {
		for j := range ch {
			fmt.Println(j)
		}
		done <- true
	}()

	<-done
}
