package config

import (
	"fmt"
	"log"
	"os"

	"github.com/joho/godotenv"
)

type Config struct {
	DBUser     string
	DBPassword string
	DBHost     string
	DBPort     string
	DBName     string
}

// GetDSN returns the DSN for the database.
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

// LoadConfig loads the configuration from the .env file.
func LoadConfig() *Config {

	err := godotenv.Load()
	if err != nil {
		log.Println("Warning: .env file not found, using system environment variables")
	}

	config := &Config{
		DBUser:     os.Getenv("DB_USER"),
		DBPassword: os.Getenv("DB_PASSWORD"),
		DBHost:     os.Getenv("DB_HOST"),
		DBPort:     os.Getenv("DB_PORT"),
		DBName:     os.Getenv("DB_NAME"),
	}

	log.Printf("Config load successfully:\nDBHost: %s\nDBPort: %s\nDBName: %s\n",
		config.DBHost,
		config.DBPort,
		config.DBName)

	return config
}
