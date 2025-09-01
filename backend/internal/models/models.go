package models

import (
	"time"

	"gorm.io/gorm"
)

type User struct {
	ID        uint           `json:"id" gorm:"primaryKey"`
	Username  string         `json:"username" gorm:"uniqueIndex;not null;size:50"`
	Email     string         `json:"email" gorm:"uniqueIndex;not null;size:100"`
	Name      string         `json:"name" gorm:"not null;size:100"`
	Password  string         `json:"-" gorm:"not null;size:255"`
	Role      string         `json:"role" gorm:"not null;type:enum('admin','author');default:'author'"`
	CreatedAt time.Time      `json:"created_at"`
	UpdatedAt time.Time      `json:"updated_at"`
	DeletedAt gorm.DeletedAt `json:"-" gorm:"index"`

	// Relationships
	Posts         []Post         `json:"posts,omitempty" gorm:"foreignKey:AuthorID"`
	Comments      []Comment      `json:"comments,omitempty" gorm:"foreignKey:UserID"`
	RefreshTokens []RefreshToken `json:"-" gorm:"foreignKey:UserID"`
}

type Category struct {
	ID          uint           `json:"id" gorm:"primaryKey"`
	Name        string         `json:"name" gorm:"not null;size:100"`
	Slug        string         `json:"slug" gorm:"uniqueIndex;not null;size:100"`
	Description string         `json:"description" gorm:"type:text"`
	CreatedAt   time.Time      `json:"created_at"`
	UpdatedAt   time.Time      `json:"updated_at"`
	DeletedAt   gorm.DeletedAt `json:"-" gorm:"index"`

	// Relationships
	Posts []Post `json:"posts,omitempty" gorm:"foreignKey:CategoryID"`
}

type Post struct {
	ID           uint           `json:"id" gorm:"primaryKey"`
	Title        string         `json:"title" gorm:"not null;size:255"`
	Slug         string         `json:"slug" gorm:"uniqueIndex;not null;size:255"`
	Content      string         `json:"content" gorm:"not null;type:text"`
	Excerpt      string         `json:"excerpt" gorm:"type:text"`
	ThumbnailURL string         `json:"thumbnail_url" gorm:"size:500"`
	CategoryID   uint           `json:"category_id" gorm:"not null"`
	AuthorID     uint           `json:"author_id" gorm:"not null"`
	Status       string         `json:"status" gorm:"not null;type:enum('draft','published','archived');default:'draft'"`
	CreatedAt    time.Time      `json:"created_at"`
	UpdatedAt    time.Time      `json:"updated_at"`
	DeletedAt    gorm.DeletedAt `json:"-" gorm:"index"`

	// Relationships
	Category *Category `json:"category,omitempty" gorm:"foreignKey:CategoryID"`
	Author   *User     `json:"author,omitempty" gorm:"foreignKey:AuthorID"`
	Comments []Comment `json:"comments,omitempty" gorm:"foreignKey:PostID"`
}

type Comment struct {
	ID        uint           `json:"id" gorm:"primaryKey"`
	PostID    uint           `json:"post_id" gorm:"not null"`
	UserID    uint           `json:"user_id" gorm:"not null"`
	Content   string         `json:"content" gorm:"not null;type:text"`
	Status    string         `json:"status" gorm:"not null;type:enum('pending','approved','rejected');default:'pending'"`
	CreatedAt time.Time      `json:"created_at"`
	UpdatedAt time.Time      `json:"updated_at"`
	DeletedAt gorm.DeletedAt `json:"-" gorm:"index"`

	// Relationships
	Post *Post `json:"post,omitempty" gorm:"foreignKey:PostID"`
	User *User `json:"user,omitempty" gorm:"foreignKey:UserID"`
}
