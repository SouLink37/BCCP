package utils

import (
	"errors"
	"log"

	"golang.org/x/crypto/bcrypt"
)

// HashPassword hashes the password using bcrypt.
func HashPassword(password string) (string, error) {
	if len(password) < 8 {
		log.Printf("Password too short: minimum 8 characters.")
		return "", errors.New("Password too short: minimum 8 characters.")
	} else if len(password) > 72 {
		log.Printf("Password too long: maximum 72 characters.")
		return "", errors.New("Password too long: maximum 72 characters.")
	}

	log.Printf("Hashing password for user registration")

	hash, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	return string(hash), err
}

// CheckPassword checks if the password is correct by comparing the hashed password and the password.
func CheckPassword(hashedPassword, password string) bool {
	if len(password) < 8 {
		log.Printf("Password too short: minimum 6 characters.")
		return false
	} else if len(password) > 72 {
		log.Printf("Password too long: maximum 72 characters.")
		return false
	}

	err := bcrypt.CompareHashAndPassword([]byte(hashedPassword), []byte(password))

	if err != nil {
		log.Printf("Password verification failed.")
		return false
	}

	log.Printf("Password verification successful.")
	return true
}
