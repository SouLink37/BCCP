package middleware

import (
	"blog-backend/utils"
	"log"
	"strings"

	"github.com/gin-gonic/gin"
)

func AuthMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		authHeader := c.GetHeader("Authorization")

		if authHeader == "" {
			utils.Error(c, 401, "Authorization header is required")
			log.Printf("Authorization header is required")
			c.Abort()
			return
		}

		if !strings.HasPrefix(authHeader, "Bearer") {
			utils.Error(c, 401, "Authorization header must start with Bearer")
			log.Printf("Authorization header must start with Bearer")
			c.Abort()
			return
		}

		tokenString := strings.TrimPrefix(authHeader, "Bearer")

		claims, err := utils.ValidateToken(tokenString)

		if err != nil {
			utils.Error(c, 401, "Invalid token")
			log.Printf("Invalid token: %v", err)
			c.Abort()
			return
		}

		c.Set("userID", claims.UserID)
		c.Set("username", claims.Username)

		log.Printf("Token validated successfully")

		c.Next()
	}
}
