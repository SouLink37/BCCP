package utils

import (
	"errors"
	"log"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

var jwtSecret = []byte("blog-backend-secret-key-dev")

// Claims represents the claims for the JWT token.
type Claims struct {
	UserID uint
	jwt.RegisteredClaims
}

// GenerateToken generates a JWT token for the given user ID and expity hours.
func GenerateToken(userID uint, expityHours ...int) (string, error) {
	hours := 24
	if len(expityHours) == 1 {
		log.Printf("Using expity hours: %d", expityHours[0])
		hours = expityHours[0]
	} else if len(expityHours) > 1 {
		log.Printf("Invalid expity hours: only one expity hour is allowed.")
		return "", errors.New("Invalid expity hours: only one expity hour is allowed.")
	}

	log.Printf("Generating JWT token for user ID: %d", userID)
	claim := Claims{
		UserID: userID,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(time.Duration(hours) * time.Hour)),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claim)

	log.Printf("Signing JWT token with secret key.")
	tokenString, err := token.SignedString(jwtSecret)
	return tokenString, err
}

// ValidateToken validates the JWT token and returns the claims if the token is valid.
func ValidateToken(tokenString string) (*Claims, error) {
	token, err := jwt.ParseWithClaims(tokenString, &Claims{}, func(token *jwt.Token) (any, error) {
		return jwtSecret, nil
	})

	if err != nil {
		log.Printf("Error parsing JWT token: %v", err)
		return nil, err
	}

	if !token.Valid {
		log.Printf("Invalid token.")
		return nil, errors.New("Invalid token.")
	}

	claims, ok := token.Claims.(*Claims)

	if !ok {
		log.Printf("Invalid token claims.")
		return nil, errors.New("Invalid token claims.")
	}

	log.Printf("Token validated successfully.")
	return claims, nil
}
