package main

import (
	"blog-backend/config"
	"blog-backend/database"
)

func main() {
	cfg := config.LoadConfig()

	database.InitDB(cfg)
}
