package handlers

import (
	"blog-backend/models"
	"blog-backend/utils"
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

type CommentHandler struct {
	DB *gorm.DB
}

type CreateCommentRequest struct {
	Content string `json:"content" binding:"required,min=1,max=1000"`
}

func (h *CommentHandler) CreateComment(c *gin.Context) {
	userID, exists := c.Get("userID")
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

	var req CreateCommentRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.Error(c, http.StatusBadRequest, "Invalid request")
		return
	}

	comment := models.Comment{
		Content:     req.Content,
		CommenterID: userID.(uint),
		PostId:      post.ID,
	}

	if err := h.DB.Create(&comment).Error; err != nil {
		utils.Error(c, http.StatusInternalServerError, "Failed to create comment")
		return
	}

	utils.Success(c, 200, "Comment created successfully", comment)
}

func (h *CommentHandler) GetComments(c *gin.Context) {
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

	var comments []models.Comment
	if err := h.DB.Where("post_id = ?", postID).Preload("Commenter").Find(&comments).Error; err != nil {
		utils.Error(c, http.StatusInternalServerError, "Failed to fetch comments")
		return
	}

	utils.Success(c, 200, "Comments fetched successfully", comments)
}
