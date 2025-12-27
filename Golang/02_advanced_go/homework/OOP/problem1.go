package main

import (
	"fmt"
	"math"
)

func problem1() {
	rec := Rectangle{3, 7}
	cir := Circle{3}

	fmt.Println("矩形面积: ", rec.Area(), ", 矩形周长: ", rec.Perimeter())
	fmt.Println("圆形面积: ", cir.Area(), ", 圆形周长: ", cir.Perimeter())
}

type Shape interface {
	Area()
	Perimeter()
}

type Rectangle struct {
	a, b float64
}

func (rectangle Rectangle) Area() float64 {
	return rectangle.a * rectangle.b
}

func (rectangle Rectangle) Perimeter() float64 {
	return (rectangle.a + rectangle.b) * 2
}

type Circle struct {
	r float64
}

func (circle Circle) Area() float64 {
	return math.Pi * circle.r * circle.r
}

func (circle Circle) Perimeter() float64 {
	return 2 * math.Pi * circle.r
}
