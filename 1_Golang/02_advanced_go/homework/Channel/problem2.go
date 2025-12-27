package main

import (
	"fmt"
	"sync"
)

func problem2() {
	var wg sync.WaitGroup
	ch := make(chan int, 100)

	wg.Add(1)

	go func() {
		for i := range 100 {
			ch <- i
		}
		close(ch)
	}()

	go func() {
		defer wg.Done()
		for j := range ch {
			fmt.Println(j)
		}
	}()

	wg.Wait()
}
