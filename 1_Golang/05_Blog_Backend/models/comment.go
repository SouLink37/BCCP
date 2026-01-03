package models

import (
	"time"

	"gorm.io/gorm"
)

type Comment struct {
	ID          uint           `gorm:"primaryKey" json:"id"`
	Content     string         `gorm:"not null" json:"content"`
	CommenterID uint           `json:"commenter_id"`
	Commenter   User           `gorm:"foreignKey:CommenterID" json:"-"`
	PostId      uint           `json:"post_id"`
	Post        Post           `gorm:"foreignKey:PostID" json:"-"`
	CreatedAt   time.Time      `json:"created_at"`
	UpdatedAt   time.Time      `json:"updated_at"`
	DeletedAt   gorm.DeletedAt `json:"-" gorm:"index"`
}
