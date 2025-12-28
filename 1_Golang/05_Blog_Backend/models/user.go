package models

type User struct {
	ID        uint      `gorm:"primaryKey" json:"id"`
	Username  string    `gorm:"type:varchar(255);uniqueIndex;not null" json:"username"`
	Email     string    `gorm:"type:varchar(255);uniqueIndex;not null" json:"email"`
	Password  string    `gorm:"type:varchar(255);not null" json:"-"`
	PostCount int       `json:"post_count"`
	Posts     []Post    `gorm:"foreignKey:UserID" json:"-"`
	Comments  []Comment `gorm:"foreignKey:CommenterID" json:"-"`
}
