package main

import (
	"blog-backend/config"
	"blog-backend/database"
	"blog-backend/routes"

	"github.com/gin-gonic/gin"
)

func main() {
	cfg := config.LoadConfig()

	db := database.InitDB(cfg)

	router := gin.Default()

	routes.SetupRoutes(router, db)

	router.Run(cfg.ServerPort)
}
