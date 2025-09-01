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
	Name        string         `json:"name" gorm:"not null;size:100;index:idx_categories_name"`
	Slug        string         `json:"slug" gorm:"uniqueIndex;not null;size:100"`
	Description string         `json:"description" gorm:"type:text"`
	CreatedAt   time.Time      `json:"created_at" gorm:"index:idx_categories_created_at"`
	UpdatedAt   time.Time      `json:"updated_at"`
	DeletedAt   gorm.DeletedAt `json:"-" gorm:"index"`

	// Relationships
	Posts []Post `json:"posts,omitempty" gorm:"foreignKey:CategoryID"`
}

type Post struct {
	ID           uint           `json:"id" gorm:"primaryKey"`
	Title        string         `json:"title" gorm:"not null;size:255;index:idx_posts_title"`
	Slug         string         `json:"slug" gorm:"uniqueIndex;not null;size:255"`
	Content      string         `json:"content" gorm:"not null;type:text"`
	Excerpt      string         `json:"excerpt" gorm:"type:text"`
	ThumbnailURL string         `json:"thumbnail_url" gorm:"size:500"`
	CategoryID   uint           `json:"category_id" gorm:"not null;index:idx_posts_category_id,idx_posts_category_status"`
	AuthorID     uint           `json:"author_id" gorm:"not null;index:idx_posts_author_id,idx_posts_author_status"`
	Status       string         `json:"status" gorm:"not null;type:enum('draft','published','archived');default:'draft';index:idx_posts_status,idx_posts_status_created_at,idx_posts_category_status,idx_posts_author_status"`
	CreatedAt    time.Time      `json:"created_at" gorm:"index:idx_posts_created_at,idx_posts_status_created_at"`
	UpdatedAt    time.Time      `json:"updated_at" gorm:"index:idx_posts_updated_at"`
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
