package main

import (
	"fmt"

	"gorm.io/gorm"
)

func problem3() {
	db := connectDB()
	db.AutoMigrate(&Post{})

	post := Post{Title: "hook_test", UserID: 1}
	db.Create(&post)

	comment := Comment{Content: "hook_test", PostID: 1}
	db.Create(&comment)

	db.First(&comment)
	db.Delete(&comment)
}

func (p *Post) AfterCreate(tx *gorm.DB) (err error) {
	return tx.Model(&User{}).Where("id = ?", p.UserID).Update("post_count", gorm.Expr("post_count + 1")).Error
}
func (p *Comment) AfterDelete(tx *gorm.DB) (err error) {
	post := Post{}
	tx.Where("Id = ?", p.PostID).Find(&post)

	num := len(post.Comments)

	if num == 0 {
		fmt.Println("文章无评论")
	}

	return nil
}
