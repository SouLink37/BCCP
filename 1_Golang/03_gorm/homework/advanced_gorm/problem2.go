package main

import "fmt"

func problem2() {
	db := connectDB()

	fmt.Println("=== 需求1: 查询某个用户发布的所有文章及其评论 ===")

	// 查询用户ID=1的所有文章及其评论
	var user User
	err := db.Preload("Posts.Comments").First(&user, 1).Error
	if err != nil {
		fmt.Printf("查询用户失败: %v\n", err)
		return
	}

	fmt.Printf("用户: %s\n", user.Name)
	fmt.Printf("文章数量: %d\n", len(user.Posts))

	for i, post := range user.Posts {
		fmt.Printf("  文章 %d: %s\n", i+1, post.Title)
		fmt.Printf("    评论数量: %d\n", len(post.Comments))
		for j, comment := range post.Comments {
			fmt.Printf("      评论 %d: %s\n", j+1, comment.Content)
		}
	}

	fmt.Println("\n=== 需求2: 查询评论数量最多的文章 ===")
	var posts []Post
	err = db.Preload("User").Preload("Comments").
		Order("(SELECT COUNT(*) FROM comments WHERE comments.post_id = posts.id) DESC").
		Limit(1).
		Find(&posts).Error
	if err != nil {
		fmt.Printf("查询文章失败: %v\n", err)
		return
	}

	if len(posts) > 0 {
		post := posts[0]
		fmt.Printf("评论最多的文章: %s\n", post.Title)
		fmt.Printf("作者: %s\n", post.User.Name)
		fmt.Printf("评论数量: %d\n", len(post.Comments))
		for i, comment := range post.Comments {
			fmt.Printf("  评论 %d: %s\n", i+1, comment.Content)
		}
	}
}
