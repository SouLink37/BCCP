package main

import (
	"fmt"
	"sync"
)

func problem1() {
	var wg sync.WaitGroup
	pct := &Counter{}

	for range 10 {
		wg.Go(func() {
			pct.add1000()
		})
	}

	wg.Wait()
	fmt.Println(pct.count)
}

type Counter struct {
	mu    sync.Mutex
	count int
}

func (counter *Counter) add1000() {
	counter.mu.Lock()
	defer counter.mu.Unlock()

	for range 1000 {
		counter.count++
	}
}
