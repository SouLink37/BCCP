package main

import "fmt"

func main() {
	fmt.Println(longestCommonPrefix([]string{"flower","flow","flight"}))
	fmt.Println(longestCommonPrefix([]string{"dog","racecar","car"}))
}

func longestCommonPrefix(strs []string) string {
    slice_prefix := []rune{}

    if len(strs) == 0 {
        return ""
    }

    for _, s := range strs[0]{
        slice_prefix = append(slice_prefix, s)
    }
    
    for i := 1; i < len(strs); i++ {
        for j, r := range strs[i] {
            if j < len(slice_prefix) {
                if  r != slice_prefix[j] {
                    slice_prefix = slice_prefix[:j] 
                    break
                }
            } 
        } 
        if len(slice_prefix) > len(strs[i]) {
            slice_prefix = slice_prefix[:len(strs[i])]
        }
    }

    return string(slice_prefix)
}
