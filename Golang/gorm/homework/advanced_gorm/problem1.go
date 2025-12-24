package main

import (
	"fmt"

	"gorm.io/driver/mysql"
	"gorm.io/gorm"
)

func problem1() {
	db := connectDB()
	db.AutoMigrate(&User{}, &Post{}, &Comment{})

	user := User{Name: "张三"}
	db.Create(&user)

	post := Post{Title: "文章1", UserID: user.ID}
	db.Create(&post)

	comment := Comment{Content: "评论1", PostID: post.ID}
	db.Create(&comment)
}

type User struct {
	ID        uint   `gorm:"primaryKey"`
	Name      string `gorm:"size:100;not null"`
	PostCount int    `gorm:"default:0"`
	Posts     []Post `gorm:"foreignKey:UserID"` // 一个用户有多篇文章
}

type Post struct {
	ID       uint      `gorm:"primaryKey"`
	Title    string    `gorm:"size:100;not null"`
	UserID   uint      `gorm:"not null"`
	User     User      `gorm:"foreignKey:UserID"`
	Comments []Comment `gorm:"foreignKey:PostID"` // 一篇文章有多个评论
}

type Comment struct {
	ID      uint   `gorm:"primaryKey"`
	Content string `gorm:"size:200;not null"`
	PostID  uint   `gorm:"not null"`
	Post    Post   `gorm:"foreignKey:PostID"`
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
