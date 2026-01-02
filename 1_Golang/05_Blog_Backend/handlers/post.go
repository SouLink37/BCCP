package handlers

import (
	"blog-backend/models"
	"blog-backend/utils"
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

type PostHandler struct {
	DB gorm.DB
}

type CreatePostRequest struct {
	Title   string `json:"title" binding:"required, min=1, max=200"`
	Content string `json:"content" bingding:"required, min=1"`
}

type UpdatePostRequest struct {
	Title   string `json:"title" binding:"required, min=1, max=200"`
	Content string `json:"content" bingding:"required, min=1"`
}

// CreatePost handler for creating a new post
func (h *PostHandler) CreatePost(c *gin.Context) {
	var req CreatePostRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.Error(c, http.StatusBadRequest, "Invalid request")
		return
	}

	userID, exists := c.Get("UserID")
	if !exists {
		utils.Error(c, http.StatusUnauthorized, "User not authenticated")
		return
	}

	post := models.Post{
		UserID:  userID.(uint),
		Title:   req.Title,
		Content: req.Content,
	}

	if err := h.DB.Create(&post).Error; err != nil {
		utils.Error(c, http.StatusInternalServerError, "Failed to create post")
		return
	}

	h.DB.Joins("User").First(&post, post.ID)
	utils.Success(c, 200, "Post created successfully", post)
}

// GetAllPosts handler for fetching all posts
func (h *PostHandler) GetAllPosts(c *gin.Context) {
	var posts []models.Post
	if err := h.DB.Joins("User").Find(&posts).Error; err != nil {
		utils.Error(c, http.StatusInternalServerError, "Failed to fetch posts")
		return
	}

	utils.Success(c, 200, "Posts fetched successfully", posts)
}

// GetPost handler for fetching a single post
func (h *PostHandler) GetPost(c *gin.Context) {
	postID, err := strconv.ParseUint(c.Param("post_id"), 10, 64)
	if err != nil {
		utils.Error(c, http.StatusBadRequest, "Invalid post ID")
		return
	}

	var post models.Post
	if err := h.DB.Joins("User").First(&post, postID).Error; err != nil {
		utils.Error(c, http.StatusNotFound, "Post not found")
		return
	}

	utils.Success(c, 200, "Post fetched successfully", post)
}

// UpdatePost handler for updating a post
func (h *PostHandler) UpdatePost(c *gin.Context) {
	// 1. check if user is authenticated
	userID, exists := c.Get("UserID")
	if !exists {
		utils.Error(c, http.StatusUnauthorized, "User not authenticated")
		return
	}

	// 2. get post id from url
	postID, err := strconv.ParseUint(c.Param("post_id"), 10, 64)
	if err != nil {
		utils.Error(c, http.StatusBadRequest, "Invalid post ID")
		return
	}
	var post models.Post

	// 3. check if post exists
	if err := h.DB.First(&post, postID).Error; err != nil {
		utils.Error(c, http.StatusNotFound, "Post not found")
		return
	}

	// 4. check if user is the author of the post
	if post.UserID != userID.(uint) {
		utils.Error(c, http.StatusForbidden, "Only author can update this post")
		return
	}

	// 5. get request body
	var req UpdatePostRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.Error(c, http.StatusBadRequest, "Invalid request")
		return
	}

	// 6. update post
	post = models.Post{
		Title:   req.Title,
		Content: req.Content,
	}

	// 7. save post to database
	if err := h.DB.Create(&post).Error; err != nil {
		utils.Error(c, http.StatusInternalServerError, "Failed to update post")
		return
	}

	// 8. get post from database
	h.DB.Joins("User").First(&post, post.ID)
	utils.Success(c, 200, "Post updated successfully", post)
}

// DeletePost handler for deleting a post
func (h *PostHandler) DeletePost(c *gin.Context) {
	userID, exists := c.Get("UserID")

	if !exists {
		utils.Error(c, http.StatusUnauthorized, "User not authenticated")
		return
	}

	postID, err := strconv.ParseUint(c.Param("post_id"), 10, 64)
	if err != nil {
		utils.Error(c, http.StatusBadRequest, "Invalid post ID")
		return
	}
	var post models.Post

	if err := h.DB.First(&post, postID).Error; err != nil {
		utils.Error(c, http.StatusNotFound, "Post not found")
		return
	}

	if post.UserID != userID.(uint) {
		utils.Error(c, http.StatusForbidden, "Only author can delete this post")
		return
	}

	if err := h.DB.Delete(&post).Error; err != nil {
		utils.Error(c, http.StatusInternalServerError, "Failed to delete post")
		return
	}

	utils.Success(c, 200, "Post deleted successfully", nil)
}
