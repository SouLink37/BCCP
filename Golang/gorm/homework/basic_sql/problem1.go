package main

import (
	"fmt"

	"gorm.io/driver/mysql"
	"gorm.io/gorm"
)

func problem1() {
	db := connectDB()
	db.AutoMigrate(&Students{})

	// 插入数据
	student := Students{Name: "张三", Age: 20, Grade: "三年级"}
	db.Create(&student)

	// 查询数据
	students := []Students{}
	db.Where("age > ?", 18).Find(&students)
	fmt.Println("查询 age > 18 的结果:")
	for _, s := range students {
		fmt.Printf("  ID: %d, Name: %s, Age: %d, Grade: %s\n", s.ID, s.Name, s.Age, s.Grade)
	}

	// 更新数据
	db.Model(&students).Where("name = ?", "张三").Update("grade", "四年级")

	// 删除数据
	db.Where("age < ?", 15).Delete(&students)

}

type Students struct {
	ID    uint
	Name  string
	Age   int
	Grade string
}

func connectDB() *gorm.DB {
	dsn := "root:12345678@tcp(127.0.0.1:3306)/gorm_homework?charset=utf8mb4&parseTime=True&loc=Local"
	db, err := gorm.Open(mysql.Open(dsn), &gorm.Config{})
	if err != nil {
		panic("连接数据库失败: " + err.Error())
	}
	fmt.Println("数据库连接成功")
	return db
}
