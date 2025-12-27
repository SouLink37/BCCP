package main

import "fmt"

func problem2() {
	emp := Employee{Person{"CXK", 18}, "两年半"}
	emp.PrintInfo()
}

type Person struct {
	Name string
	Age  int
}

type Employee struct {
	Person
	EmployeeID string
}

func (employee Employee) PrintInfo() {
	fmt.Println("姓名: ", employee.Person.Name)
	fmt.Println("年龄: ", employee.Person.Age)
	fmt.Println("工号: ", employee.EmployeeID)
}
