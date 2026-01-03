# 博客后端项目详细实现指南 - MySQL 版本

## 📋 开发理念

采用**迭代开发**方法：完成一个模块后立即测试，逐步构建完整系统。每一步都能 `go run main.go` 验证功能。

---

## 📍 第一步：项目初始化和依赖安装

**目标目录：** `/home/soulink/workspace/BCCP/1_Golang/05_Blog_Backend`

```bash
# 1. 查看当前目录结构
cd /home/soulink/workspace/BCCP/1_Golang/05_Blog_Backend
ls -la

# 2. 初始化 go.mod（如果没有）
go mod init blog-backend

# 3. 下载依赖包（使用 MySQL 版本）
go get github.com/gin-gonic/gin
go get gorm.io/gorm
go get gorm.io/driver/mysql         # ← MySQL 驱动（不是 sqlite）
go get github.com/golang-jwt/jwt/v5
go get golang.org/x/crypto/bcrypt
go get github.com/joho/godotenv
```

---

## 📁 第二步：创建项目目录结构

```bash
# 在 05_Blog_Backend 目录下，创建以下目录
mkdir -p config models database handlers middleware routes utils logs

# 查看结构
tree  # 或者 ls -la
```

最终结构应该是：
```
05_Blog_Backend/
├── config/
├── models/
├── database/
├── handlers/
├── middleware/
├── routes/
├── utils/
├── logs/
├── .env
├── main.go
├── go.mod
└── go.sum
```

---

## 🔧 第三步：创建配置文件和 .env

### 3.1 创建 .env 文件

在项目根目录创建 `.env` 文件：

```
DB_HOST=127.0.0.1
DB_PORT=3306
DB_USER=root
DB_PASSWORD=your_password_here
DB_NAME=blog_backend
API_PORT=:8080
JWT_SECRET=your-secret-key-change-this-in-production
```

**重要：** 如果你提交到 GitHub，记得在 `.gitignore` 中添加 `.env`（防止密码泄露）

### 3.2 创建 config/config.go 文件

```go
package config

import (
	"fmt"
	"os"

	"github.com/joho/godotenv"
)

type Config struct {
	DBUser     string
	DBPassword string
	DBHost     string
	DBPort     string
	DBName     string
	Port       string
	Secret     string
}

// GetDSN 生成 MySQL 的数据源名称
func (c *Config) GetDSN() string {
	return fmt.Sprintf(
		"%s:%s@tcp(%s:%s)/%s?charset=utf8mb4&parseTime=True&loc=Local",
		c.DBUser,
		c.DBPassword,
		c.DBHost,
		c.DBPort,
		c.DBName,
	)
}

// LoadConfig 从环境变量中加载配置
func LoadConfig() *Config {
	godotenv.Load()

	return &Config{
		DBUser:     os.Getenv("DB_USER"),
		DBPassword: os.Getenv("DB_PASSWORD"),
		DBHost:     os.Getenv("DB_HOST"),
		DBPort:     os.Getenv("DB_PORT"),
		DBName:     os.Getenv("DB_NAME"),
		Port:       os.Getenv("API_PORT"),
		Secret:     os.Getenv("JWT_SECRET"),
	}
}
```

**说明：**
- `GetDSN()` 是一个**方法**，用来生成 MySQL 连接字符串
- `LoadConfig()` 是一个**函数**，用来从 .env 文件加载配置

---

## 🚀 第四步：创建最小化 main.go（可运行）

**编辑文件：** `main.go`

这是一个最小化版本，只加载配置，其他功能先注释。这样能立即测试项目是否正确设置。

```go
package main

import (
	"blog-backend/config"
	"fmt"
)

func main() {
	fmt.Println("🚀 博客后端启动中...")
	
	// 第1步：加载配置
	cfg := config.LoadConfig()
	fmt.Printf("✅ 配置加载成功: 端口 %s\n", cfg.Port)
	
	// 其他功能将逐步添加...
	// TODO: 初始化数据库
	// TODO: 设置路由
	// TODO: 启动服务器
	
	fmt.Println("\n✅ 项目初始化完成！")
}
```

**测试：** 运行 `go run main.go`，应该看到配置加载成功的消息。

---

## 💾 第五步：创建 GORM 模型

### 5.1 创建文件：`models/user.go`

```go
package models

import "gorm.io/gorm"

type User struct {
	ID        uint      `gorm:"primaryKey" json:"id"`
	Username  string    `gorm:"type:varchar(255);uniqueIndex;not null" json:"username"`
	Email     string    `gorm:"type:varchar(255);uniqueIndex;not null" json:"email"`
	Password  string    `gorm:"type:varchar(255);not null" json:"-"`
	PostCount int       `json:"post_count"`
	Posts     []Post    `gorm:"foreignKey:UserID" json:"-"`
	Comments  []Comment `gorm:"foreignKey:CommenterID" json:"-"`
}
```

### 5.2 创建文件：`models/post.go`

```go
package models

import "time"

type Post struct {
	ID        uint      `gorm:"primaryKey" json:"id"`
	Title     string    `gorm:"not null" json:"title"`
	Content   string    `json:"content"`
	UserID    uint      `json:"user_id"`
	User      User      `gorm:"foreignKey:UserID" json:"-"`
	Comments  []Comment `gorm:"foreignKey:PostID" json:"-"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}
```

### 5.3 创建文件：`models/comment.go`

```go
package models

import "time"

type Comment struct {
	ID          uint      `gorm:"primaryKey" json:"id"`
	Content     string    `gorm:"not null" json:"content"`
	CommenterID uint      `json:"commenter_id"`
	Commenter   User      `gorm:"foreignKey:CommenterID" json:"-"`
	PostId      uint      `json:"post_id"`
	Post        Post      `gorm:"foreignKey:PostID" json:"-"`
	CreatedAt   time.Time `json:"created_at"`
}
```

---

## 🗄️ 第六步：创建 MySQL 数据库和数据库初始化

### 6.1 在 MySQL 中创建数据库

在 MySQL 命令行中执行：

```sql
CREATE DATABASE blog_backend CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

**说明：**
- `CHARACTER SET utf8mb4` - 支持中文和 emoji
- `COLLATE utf8mb4_unicode_ci` - 排序规则

### 6.2 创建数据库初始化代码

**创建文件：** `database/db.go`

```go
package database

import (
	"blog-backend/config"
	"blog-backend/models"
	"fmt"
	"gorm.io/driver/mysql"
	"gorm.io/gorm"
	"log"
)

func InitDB(cfg *config.Config) *gorm.DB {
	// 获取 MySQL 连接字符串
	dsn := cfg.GetDSN()
	
	// 连接 MySQL 数据库
	db, err := gorm.Open(mysql.Open(dsn), &gorm.Config{})
	if err != nil {
		log.Fatalf("数据库连接失败: %v", err)
	}
	
	// 自动迁移（创建表）
	db.AutoMigrate(&models.User{}, &models.Post{}, &models.Comment{})
	fmt.Println("✅ 数据库初始化成功")
	
	return db
}
```

### 6.3 更新 main.go 测试数据库连接

```go
package main

import (
	"blog-backend/config"
	"blog-backend/database"
	"fmt"
)

func main() {
	fmt.Println("🚀 博客后端启动中...")
	
	// 第1步：加载配置
	cfg := config.LoadConfig()
	fmt.Printf("✅ 配置加载成功: 端口 %s\n", cfg.Port)
	
	// 第2步：初始化数据库
	db := database.InitDB(cfg)
	fmt.Println("✅ 数据库初始化完成")
	
	// 验证数据库连接
	sqlDB, _ := db.DB()
	if err := sqlDB.Ping(); err != nil {
		fmt.Printf("❌ 数据库连接失败: %v\n", err)
	} else {
		fmt.Println("✅ 数据库连接验证成功")
	}
	
	// 其他功能将逐步添加...
	// TODO: 设置路由
	// TODO: 启动服务器
}
```

**测试：** 运行 `go run main.go`，应该看到数据库初始化成功的消息。

---

## 🔐 第七步：创建工具函数

### 7.1 创建文件：`utils/password.go`

```go
package utils

import "golang.org/x/crypto/bcrypt"

// 加密密码
func HashPassword(password string) (string, error) {
	hash, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	return string(hash), err
}

// 验证密码
func CheckPassword(hashedPassword, password string) bool {
	err := bcrypt.CompareHashAndPassword([]byte(hashedPassword), []byte(password))
	return err == nil
}
```

### 7.2 创建文件：`utils/jwt.go`

```go
package utils

import (
	"errors"
	"github.com/golang-jwt/jwt/v5"
	"time"
)

var jwtSecret = []byte("your-secret-key")

type Claims struct {
	UserID uint
	jwt.RegisteredClaims
}

// 生成 JWT Token
func GenerateToken(userID uint) (string, error) {
	claims := Claims{
		UserID: userID,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(24 * time.Hour)),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
		},
	}
	
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString(jwtSecret)
}

// 验证 JWT Token
func ValidateToken(tokenString string) (*Claims, error) {
	token, err := jwt.ParseWithClaims(tokenString, &Claims{}, func(token *jwt.Token) (interface{}, error) {
		return jwtSecret, nil
	})
	
	if err != nil {
		return nil, err
	}
	
	claims, ok := token.Claims.(*Claims)
	if !ok || !token.Valid {
		return nil, errors.New("invalid token")
	}
	
	return claims, nil
}
```

### 7.3 创建文件：`utils/response.go`

```go
package utils

import "github.com/gin-gonic/gin"

type Response struct {
	Code    int         `json:"code"`
	Message string      `json:"message"`
	Data    interface{} `json:"data,omitempty"`
}

func Success(c *gin.Context, code int, message string, data interface{}) {
	c.JSON(code, Response{
		Code:    code,
		Message: message,
		Data:    data,
	})
}

func Error(c *gin.Context, code int, message string) {
	c.JSON(code, Response{
		Code:    code,
		Message: message,
	})
}
```

---

## 🔐 第八步：创建认证中间件（middleware/auth.go）

**创建文件：** `middleware/auth.go`

```go
package middleware

import (
	"blog-backend/utils"
	"github.com/gin-gonic/gin"
	"net/http"
	"strings"
)

func AuthMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		// 获取 Authorization header
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "missing token"})
			c.Abort()
			return
		}
		
		// 提取 token（通常格式是 "Bearer token"）
		tokenString := strings.TrimPrefix(authHeader, "Bearer ")
		
		// 验证 token
		claims, err := utils.ValidateToken(tokenString)
		if err != nil {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "invalid token"})
			c.Abort()
			return
		}
		
		// 将 userID 存放在 context 中，后续可使用
		c.Set("userID", claims.UserID)
		c.Next()
	}
}
```

---

## 👤 第九步：创建用户认证处理（handlers/auth.go）

**创建文件：** `handlers/auth.go`

```go
package handlers

import (
	"blog-backend/models"
	"blog-backend/utils"
	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
	"net/http"
)

type AuthHandler struct {
	DB *gorm.DB
}

// 注册请求结构体
type RegisterRequest struct {
	Username string `json:"username" binding:"required"`
	Email    string `json:"email" binding:"required"`
	Password string `json:"password" binding:"required"`
}

// 登录请求结构体
type LoginRequest struct {
	Username string `json:"username" binding:"required"`
	Password string `json:"password" binding:"required"`
}

// 用户注册
func (h *AuthHandler) Register(c *gin.Context) {
	var req RegisterRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.Error(c, http.StatusBadRequest, "invalid request")
		return
	}
	
	// 检查用户是否已存在
	var existingUser models.User
	if h.DB.Where("username = ?", req.Username).First(&existingUser).Error == nil {
		utils.Error(c, http.StatusConflict, "username already exists")
		return
	}
	
	// 加密密码
	hashedPassword, err := utils.HashPassword(req.Password)
	if err != nil {
		utils.Error(c, http.StatusInternalServerError, "password hashing failed")
		return
	}
	
	// 创建用户
	user := models.User{
		Username: req.Username,
		Email:    req.Email,
		Password: hashedPassword,
	}
	
	if err := h.DB.Create(&user).Error; err != nil {
		utils.Error(c, http.StatusInternalServerError, "registration failed")
		return
	}
	
	utils.Success(c, http.StatusCreated, "registration successful", gin.H{
		"id":       user.ID,
		"username": user.Username,
	})
}

// 用户登录
func (h *AuthHandler) Login(c *gin.Context) {
	var req LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.Error(c, http.StatusBadRequest, "invalid request")
		return
	}
	
	// 查找用户
	var user models.User
	if err := h.DB.Where("username = ?", req.Username).First(&user).Error; err != nil {
		utils.Error(c, http.StatusUnauthorized, "invalid username or password")
		return
	}
	
	// 验证密码
	if !utils.CheckPassword(user.Password, req.Password) {
		utils.Error(c, http.StatusUnauthorized, "invalid username or password")
		return
	}
	
	// 生成 JWT Token
	token, err := utils.GenerateToken(user.ID)
	if err != nil {
		utils.Error(c, http.StatusInternalServerError, "token generation failed")
		return
	}
	
	utils.Success(c, http.StatusOK, "login successful", gin.H{
		"token": token,
		"user": gin.H{
			"id":       user.ID,
			"username": user.Username,
		},
	})
}
```

---

## 📝 第十步：创建文章处理（handlers/post.go）

**创建文件：** `handlers/post.go`

```go
package handlers

import (
	"blog-backend/models"
	"blog-backend/utils"
	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
	"net/http"
)

type PostHandler struct {
	DB *gorm.DB
}

type CreatePostRequest struct {
	Title   string `json:"title" binding:"required"`
	Content string `json:"content" binding:"required"`
}

// 创建文章
func (h *PostHandler) CreatePost(c *gin.Context) {
	userID, exists := c.Get("userID")
	if !exists {
		utils.Error(c, http.StatusUnauthorized, "user not authenticated")
		return
	}
	
	var req CreatePostRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.Error(c, http.StatusBadRequest, "invalid request")
		return
	}
	
	post := models.Post{
		Title:   req.Title,
		Content: req.Content,
		UserID:  userID.(uint),
	}
	
	if err := h.DB.Create(&post).Error; err != nil {
		utils.Error(c, http.StatusInternalServerError, "failed to create post")
		return
	}
	
	utils.Success(c, http.StatusCreated, "post created successfully", post)
}

// 获取所有文章
func (h *PostHandler) GetAllPosts(c *gin.Context) {
	var posts []models.Post
	if err := h.DB.Preload("User").Find(&posts).Error; err != nil {
		utils.Error(c, http.StatusInternalServerError, "failed to fetch posts")
		return
	}
	
	utils.Success(c, http.StatusOK, "success", posts)
}

// 获取单篇文章
func (h *PostHandler) GetPost(c *gin.Context) {
	id := c.Param("id")
	var post models.Post
	
	if err := h.DB.Preload("User").Preload("Comments").First(&post, id).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			utils.Error(c, http.StatusNotFound, "post not found")
			return
		}
		utils.Error(c, http.StatusInternalServerError, "failed to fetch post")
		return
	}
	
	utils.Success(c, http.StatusOK, "success", post)
}

// 更新文章
func (h *PostHandler) UpdatePost(c *gin.Context) {
	userID, exists := c.Get("userID")
	if !exists {
		utils.Error(c, http.StatusUnauthorized, "user not authenticated")
		return
	}
	
	id := c.Param("id")
	var post models.Post
	
	// 查找文章
	if err := h.DB.First(&post, id).Error; err != nil {
		utils.Error(c, http.StatusNotFound, "post not found")
		return
	}
	
	// 检查是否是文章作者
	if post.UserID != userID.(uint) {
		utils.Error(c, http.StatusForbidden, "only author can update this post")
		return
	}
	
	var req CreatePostRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.Error(c, http.StatusBadRequest, "invalid request")
		return
	}
	
	if err := h.DB.Model(&post).Updates(req).Error; err != nil {
		utils.Error(c, http.StatusInternalServerError, "failed to update post")
		return
	}
	
	utils.Success(c, http.StatusOK, "post updated successfully", post)
}

// 删除文章
func (h *PostHandler) DeletePost(c *gin.Context) {
	userID, exists := c.Get("userID")
	if !exists {
		utils.Error(c, http.StatusUnauthorized, "user not authenticated")
		return
	}
	
	id := c.Param("id")
	var post models.Post
	
	// 查找文章
	if err := h.DB.First(&post, id).Error; err != nil {
		utils.Error(c, http.StatusNotFound, "post not found")
		return
	}
	
	// 检查是否是文章作者
	if post.UserID != userID.(uint) {
		utils.Error(c, http.StatusForbidden, "only author can delete this post")
		return
	}
	
	if err := h.DB.Delete(&post).Error; err != nil {
		utils.Error(c, http.StatusInternalServerError, "failed to delete post")
		return
	}
	
	utils.Success(c, http.StatusOK, "post deleted successfully", nil)
}
```

---

## 💬 第十一步：创建评论处理（handlers/comment.go）

**创建文件：** `handlers/comment.go`

```go
package handlers

import (
	"blog-backend/models"
	"blog-backend/utils"
	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
	"net/http"
)

type CommentHandler struct {
	DB *gorm.DB
}

type CreateCommentRequest struct {
	Content string `json:"content" binding:"required"`
}

// 创建评论
func (h *CommentHandler) CreateComment(c *gin.Context) {
	userID, exists := c.Get("userID")
	if !exists {
		utils.Error(c, http.StatusUnauthorized, "user not authenticated")
		return
	}
	
	postID := c.Param("post_id")
	
	// 验证文章是否存在
	var post models.Post
	if err := h.DB.First(&post, postID).Error; err != nil {
		utils.Error(c, http.StatusNotFound, "post not found")
		return
	}
	
	var req CreateCommentRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.Error(c, http.StatusBadRequest, "invalid request")
		return
	}
	
	comment := models.Comment{
		Content: req.Content,
		UserID:  userID.(uint),
		PostID:  post.ID,
	}
	
	if err := h.DB.Create(&comment).Error; err != nil {
		utils.Error(c, http.StatusInternalServerError, "failed to create comment")
		return
	}
	
	utils.Success(c, http.StatusCreated, "comment created successfully", comment)
}

// 获取文章的所有评论
func (h *CommentHandler) GetPostComments(c *gin.Context) {
	postID := c.Param("post_id")
	
	var comments []models.Comment
	if err := h.DB.Where("post_id = ?", postID).Preload("User").Find(&comments).Error; err != nil {
		utils.Error(c, http.StatusInternalServerError, "failed to fetch comments")
		return
	}
	
	utils.Success(c, http.StatusOK, "success", comments)
}
```

---

## 🛣️ 第十二步：创建路由配置（routes/routes.go）

**创建文件：** `routes/routes.go`

```go
package routes

import (
	"blog-backend/handlers"
	"blog-backend/middleware"
	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

func SetupRoutes(router *gin.Engine, db *gorm.DB) {
	// 初始化处理器
	authHandler := &handlers.AuthHandler{DB: db}
	postHandler := &handlers.PostHandler{DB: db}
	commentHandler := &handlers.CommentHandler{DB: db}
	
	// 认证路由（不需要 JWT）
	auth := router.Group("/api/auth")
	{
		auth.POST("/register", authHandler.Register)
		auth.POST("/login", authHandler.Login)
	}
	
	// 文章路由
	posts := router.Group("/api/posts")
	{
		// 无需认证的路由
		posts.GET("", postHandler.GetAllPosts)
		posts.GET("/:id", postHandler.GetPost)
		
		// 需要认证的路由
		posts.POST("", middleware.AuthMiddleware(), postHandler.CreatePost)
		posts.PUT("/:id", middleware.AuthMiddleware(), postHandler.UpdatePost)
		posts.DELETE("/:id", middleware.AuthMiddleware(), postHandler.DeletePost)
	}
	
	// 评论路由
	comments := router.Group("/api/posts/:post_id/comments")
	{
		// 无需认证的路由
		comments.GET("", commentHandler.GetPostComments)
		
		// 需要认证的路由
		comments.POST("", middleware.AuthMiddleware(), commentHandler.CreateComment)
	}
}
```

---

## 🎯 第十三步：更新 main.go 为完整版本

**编辑文件：** `main.go`

```go
package main

import (
	"blog-backend/config"
	"blog-backend/database"
	"blog-backend/routes"
	"fmt"
	"github.com/gin-gonic/gin"
)

func main() {
	fmt.Println("🚀 博客后端启动中...")
	
	// 第1步：加载配置
	cfg := config.LoadConfig()
	fmt.Printf("✅ 配置加载成功: 端口 %s\n", cfg.Port)
	
	// 第2步：初始化数据库
	db := database.InitDB(cfg)
	fmt.Println("✅ 数据库初始化完成")
	
	// 第3步：创建 Gin 路由
	router := gin.Default()
	fmt.Println("✅ 路由引擎创建完成")
	
	// 第4步：设置路由
	routes.SetupRoutes(router, db)
	fmt.Println("✅ 所有路由配置完成")
	
	// 第5步：启动服务器
	fmt.Printf("🌐 服务器启动在 http://localhost%s\n", cfg.Port)
	fmt.Println("📡 等待请求中...\n")
	router.Run(cfg.Port)
}
```

**测试：** 运行 `go run main.go`，应该看到服务器成功启动的消息。

---

## ✅ 完成后的测试步骤

### 环境准备

1. 确保 MySQL 服务已启动
2. 创建 `.env` 文件，配置如下：
   ```
   DB_USER=root
   DB_PASSWORD=
   DB_HOST=127.0.0.1
   DB_PORT=3306
   DB_NAME=blog_backend
   SERVER_PORT=:8080
   ```
3. 运行应用：`go run main.go`
4. 应用将在 `http://localhost:8080` 运行

### 使用网页版 Postman 测试

打开 https://web.postman.co/，逐个测试以下接口：

| 序号 | 功能 | 请求方式 | URL | 请求体/Headers | 预期结果 |
|------|------|---------|-----|-----------------|---------|
| 1 | **注册用户** | POST | `http://localhost:8080/api/auth/register` | Body: `{"username":"user1","email":"user@example.com","password":"12345678"}` | 返回 `{"code":200,"message":"User registered successfully"}` |
| 2 | **登录用户** | POST | `http://localhost:8080/api/auth/login` | Body: `{"username":"user1","password":"12345678"}` | 返回 `{"code":200,"data":{"token":"jwt_token_here"},"message":"Login successful"}` 并**保存 token** |
| 3 | **获取所有文章** | GET | `http://localhost:8080/api/posts` | 无需认证 | 返回所有文章列表（初始时为空数组）|
| 4 | **创建文章** | POST | `http://localhost:8080/api/posts` | Header: `Authorization: Bearer [刚才保存的token]` <br> Body: `{"title":"My First Post","content":"This is the content of my first post"}` | 返回 `{"code":200,"data":{"id":1,...},"message":"Post created successfully"}` |
| 5 | **获取单篇文章** | GET | `http://localhost:8080/api/posts/1` | 无需认证 | 返回 ID 为 1 的文章详情，包括评论数据 |
| 6 | **创建评论** | POST | `http://localhost:8080/api/posts/1/comments` | Header: `Authorization: Bearer [token]` <br> Body: `{"content":"Great post!"}` | 返回 `{"code":200,"data":{"id":1,...},"message":"Comment created successfully"}` |
| 7 | **获取评论列表** | GET | `http://localhost:8080/api/posts/1/comments` | 无需认证 | 返回该文章的所有评论列表 |
| 8 | **更新文章** | PUT | `http://localhost:8080/api/posts/1` | Header: `Authorization: Bearer [token]` <br> Body: `{"title":"Updated Title","content":"Updated content"}` | 返回 `{"code":200,"data":{...},"message":"Post updated successfully"}` |
| 9 | **删除文章** | DELETE | `http://localhost:8080/api/posts/1` | Header: `Authorization: Bearer [token]` | 返回 `{"code":200,"message":"Post deleted successfully"}` |

### 测试检查清单

- [ ] 注册用户时，密码会被正确加密存储
- [ ] 登录后获取的 token 是有效的 JWT
- [ ] 使用 token 能够访问需要认证的接口
- [ ] 使用错误的 token 或无 token 访问受保护接口时返回 401
- [ ] 创建文章时自动关联当前登录的用户
- [ ] 更新和删除文章时验证操作者是否为文章所有者
- [ ] 获取文章详情时包含该文章的评论数据
- [ ] 创建评论时自动关联当前登录的用户和指定的文章

### 常见问题排查

| 问题 | 解决方案 |
|------|---------|
| `address 3306: missing port in address` | 检查 `.env` 文件中 `SERVER_PORT` 是否设置为 `:8080` 格式 |
| 无法连接数据库 | 确保 MySQL 运行中，DB_HOST/DB_PORT/DB_NAME 配置正确 |
| 401 Unauthorized 错误 | 检查 Authorization header 格式是否为 `Bearer [token]`，确保 token 未过期 |
| 更新/删除文章返回 403 | 确保只用创建该文章的用户的 token 进行操作 |

---


