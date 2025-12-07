package main

import "fmt"

func main() {
	fmt.Println(isValid("()"))
	fmt.Println(isValid("()[]{}"))
	fmt.Println(isValid("(]"))
	fmt.Println(isValid("([)]"))
	fmt.Println(isValid("{[]}"))
}

func isValid(s string) bool {
    stack := []string{}

    for _, char := range s {
        if char == '(' || char == '[' || char == '{' {
            stack = append(stack, string(char))
        } else if char == ')' || char == ']' || char == '}' {
            if len(stack) == 0 {
                return false
            }
            if stack[len(stack)-1] != getLeftPair(string(char)) {
                return false
            } else {
                stack = stack[:len(stack)-1]
            }
        }
    }

    return len(stack) == 0
}

func getLeftPair(char string) string {
    switch char {
        case ")":
            return "("
        case "]":
            return "["
        case "}":
            return "{"
    }
    return ""
}

