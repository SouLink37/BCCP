package main

import (
	"fmt"
	"os"
)

func main() {
	if len(os.Args) < 2 {
		fmt.Println("用法: go run . <示例名称>")
		fmt.Println("可用示例: array")
		os.Exit(1)
	}

	example := os.Args[1]
	switch example {
	case "1":
		problem1()
	case "2":
		problem2()
	default:
		fmt.Println("未知示例: ", example)
		os.Exit(1)
	}
}
