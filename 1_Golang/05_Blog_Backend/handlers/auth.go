package handlers

import (
	"blog-backend/models"
	"blog-backend/utils"
	"net/http"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

type AuthHandler struct {
	DB *gorm.DB
}

type RegisterRequest struct {
	Username string
	Email    string
	Password string
}

type LoginRequest struct {
	Username string
	Password string
}

type AuthResponse struct {
	Token string      `json:"token"`
	User  models.User `json:"user"`
}

// Register handler for user registration
func (h *AuthHandler) Register(c *gin.Context) {
	var req RegisterRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.Error(c, http.StatusBadRequest, err.Error())
		return
	}

	var existingUser models.User
	if err := h.DB.Where("Username = ?", req.Username).First(&existingUser).Error; err == nil {
		utils.Error(c, http.StatusConflict, "Username already exists")
		return
	}

	if err := h.DB.Where("Email = ?", req.Email).First(&existingUser).Error; err == nil {
		utils.Error(c, http.StatusConflict, "Email already exists")
		return
	}

	user := models.User{
		Username: req.Username,
		Email:    req.Email,
		Password: req.Password,
	}

	// hashpassword processed in hook BeforeCreate()
	if err := h.DB.Create(&user).Error; err != nil {
		utils.Error(c, http.StatusInternalServerError, "Registration failed")
		return
	}

	token, err := utils.GenerateToken(user.ID, user.Username)

	if err != nil {
		utils.Error(c, http.StatusInternalServerError, "Token generation failed")
		return
	}

	utils.Success(c, 200, "Registration successful", AuthResponse{
		Token: token,
		User:  user,
	})
}

func (h *AuthHandler) Login(c *gin.Context) {
	var req LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.Error(c, http.StatusBadRequest, "Invalid request")
		return
	}

	var existingUser models.User
	if err := h.DB.Where("Username = ?", req.Username).First(&existingUser).Error; err != nil {
		utils.Error(c, http.StatusUnauthorized, "Invalid username or password")
		return
	}

	passed := utils.CheckPassword(existingUser.Password, req.Password)

	if !passed {
		utils.Error(c, http.StatusUnauthorized, "Invalid username or password")
		return
	}

	token, err := utils.GenerateToken(existingUser.ID, existingUser.Username)

	if err != nil {
		utils.Error(c, http.StatusInternalServerError, "Token generation failed")
		return
	}

	utils.Success(c, 200, "Login successful", AuthResponse{
		Token: token,
		User:  existingUser,
	})
}
