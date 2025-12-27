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
    case "array":
        ArrayDemo()
	case "slice":
		SliceDemo()
	case "map":
		MapDemo()
	case "type":
		TypeDemo()
    default:
        fmt.Printf("未知示例: %s\n", example)
        fmt.Println("可用示例: array")
        os.Exit(1)
    }
}