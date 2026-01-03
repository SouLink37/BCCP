package routes

import (
	"blog-backend/handlers"
	"blog-backend/middleware"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

func SetupRoutes(routes *gin.Engine, db *gorm.DB) {
	AuthHandler := &handlers.AuthHandler{DB: db}
	PostHandler := &handlers.PostHandler{DB: db}
	CommentHandler := &handlers.CommentHandler{DB: db}

	api := routes.Group("/api")
	{
		auth := api.Group("/auth")
		{
			auth.POST("/register", AuthHandler.Register)
			auth.POST("/login", AuthHandler.Login)
		}

		authenticated := api.Group("")
		authenticated.Use(middleware.AuthMiddleware())
		{
			posts := authenticated.Group("/posts")
			{
				posts.POST("", PostHandler.CreatePost)
				posts.PUT("/:post_id", PostHandler.UpdatePost)
				posts.DELETE("/:post_id", PostHandler.DeletePost)
			}
			comments := authenticated.Group("/posts/:post_id/comments")
			{
				comments.POST("", CommentHandler.CreateComment)
			}
		}

		public := api.Group("")
		{
			posts := public.Group("/posts")
			{
				posts.GET("/:post_id", PostHandler.GetPost)
				posts.GET("", PostHandler.GetAllPosts)
			}
			comments := public.Group("/posts/:post_id/comments")
			{
				comments.GET("", CommentHandler.GetComments)
			}
		}
	}

	routes.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{
			"status":  "ok",
			"message": "Blog API is running",
		})
	})
}
