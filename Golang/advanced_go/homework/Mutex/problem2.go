package main

import (
	"fmt"
	"sync"
	"sync/atomic"
)

func problem2() {
	var wg sync.WaitGroup
	pct := &AtomicCounter{}

	for range 10 {
		wg.Go(func() {
			pct.add1000()
		})
	}

	wg.Wait()
	fmt.Println(pct.count.Load())
}

type AtomicCounter struct {
	count atomic.Int32
}

func (counter *AtomicCounter) add1000() {
	for range 1000 {
		counter.count.Add(1)
	}
}
