package database

import (
	"blog-backend/config"
	"blog-backend/models"
	"log"

	"gorm.io/driver/mysql"
	"gorm.io/gorm"
)

// InitDB initializes the database and performs auto-migration.
func InitDB(cfg *config.Config) {
	dsn := cfg.GetDSN()
	db := connectDB(dsn)

	db.AutoMigrate(&models.User{}, &models.Post{}, &models.Comment{})

	log.Println("Database initialized.")
}

// connectDB connects to the database and returns the database connection.
func connectDB(dsn string) *gorm.DB {
	db, err := gorm.Open(mysql.Open(dsn), &gorm.Config{})

	if err != nil {
		log.Fatalf("Data base conncted failed: %v", err)
	}

	log.Println("Database connect successfully.")

	return db
}
