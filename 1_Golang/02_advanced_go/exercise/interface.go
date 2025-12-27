package main

import "fmt"

type Setter interface {
    // Set(int) // 接口要求：Set() 方法
	Set2(int) // 接口要求：Set2() 方法
}

type Item struct {
    val int
}

// // 📌 指针接收者：修改接收者
// func (i *Item) Set(v int) { 
//     i.val = v 
// }

// 📌 指针接收者：修改接收者
func (i Item) Set2(v int) { 
    i.val = v 
}

func main() {
    itemValue := Item{val: 2}    // 值类型实例
    itemPointer := &Item{val: 1} // 指针类型实例

    var s Setter
	var s2 Setter
    
    // 赋值 D: 指针类型实例赋值给接口
    s = itemPointer // ✅ 允许：因为只有 *Item 满足 Set() 方法集
	fmt.Println(s)
	s.Set2(10)
	fmt.Println(s)
	fmt.Println(itemValue)
    // 赋值 E: 值类型实例赋值给接口
    s2 = itemValue // ❌ 编译报错！因为 Item 的方法集不包含 Set()
	fmt.Println(s2)
	fmt.Println(itemValue)
}