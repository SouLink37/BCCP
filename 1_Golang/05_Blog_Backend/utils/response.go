package utils

import "github.com/gin-gonic/gin"

// Response represents the response for the API.
type Response struct {
	Code    int    `json:"code"`
	Message string `json:"message"`
	Data    any    `json:"data,omitempty"`
}

// Success sends a success response to the client.
func Success(c *gin.Context, code int, message string, data any) {
	c.JSON(code, Response{
		Code:    code,
		Message: message,
		Data:    data,
	})
}

// Error sends an error response to the client.
func Error(c *gin.Context, code int, message string) {
	c.JSON(code, Response{
		Code:    code,
		Message: message,
	})
}
