package models

import "time"

// Request/Response DTOs with comprehensive validation

type LoginRequest struct {
	Email    string `json:"email" validate:"required,email" binding:"required,email"`
	Password string `json:"password" validate:"required,min=6" binding:"required,min=6"`
}

type RegisterRequest struct {
	Username string `json:"username" validate:"required,min=3,max=50,alphanum" binding:"required,min=3,max=50"`
	Email    string `json:"email" validate:"required,email" binding:"required,email"`
	Password string `json:"password" validate:"required,min=8,max=128" binding:"required,min=8,max=128"`
	Name     string `json:"name" validate:"required,min=2,max=100" binding:"required,min=2,max=100"`
	Role     string `json:"role" validate:"omitempty,oneof=admin author" binding:"omitempty,oneof=admin author"`
}

type RefreshTokenRequest struct {
	RefreshToken string `json:"refresh_token" validate:"required" binding:"required"`
}

type AuthResponse struct {
	AccessToken  string `json:"access_token"`
	RefreshToken string `json:"refresh_token"`
	TokenType    string `json:"token_type"`
	ExpiresIn    int64  `json:"expires_in"`
	User         User   `json:"user"`
}

type RefreshTokenResponse struct {
	AccessToken  string `json:"access_token"`
	RefreshToken string `json:"refresh_token"`
	TokenType    string `json:"token_type"`
	ExpiresIn    int64  `json:"expires_in"`
}

type CreatePostRequest struct {
	Title        string `json:"title" validate:"required,min=5,max=255" binding:"required,min=5,max=255"`
	Content      string `json:"content" validate:"required,min=50" binding:"required,min=50"`
	Excerpt      string `json:"excerpt" validate:"omitempty,max=500" binding:"omitempty,max=500"`
	ThumbnailURL string `json:"thumbnail_url" validate:"omitempty,url" binding:"omitempty,url"`
	CategoryID   uint   `json:"category_id" validate:"required,gt=0" binding:"required,gt=0"`
	Status       string `json:"status" validate:"omitempty,oneof=draft published archived" binding:"omitempty,oneof=draft published archived"`
}

type UpdatePostRequest struct {
	Title        *string `json:"title" validate:"omitempty,min=5,max=255" binding:"omitempty,min=5,max=255"`
	Content      *string `json:"content" validate:"omitempty,min=50" binding:"omitempty,min=50"`
	Excerpt      *string `json:"excerpt" validate:"omitempty,max=500" binding:"omitempty,max=500"`
	ThumbnailURL *string `json:"thumbnail_url" validate:"omitempty,url" binding:"omitempty,url"`
	CategoryID   *uint   `json:"category_id" validate:"omitempty,gt=0" binding:"omitempty,gt=0"`
	Status       *string `json:"status" validate:"omitempty,oneof=draft published archived" binding:"omitempty,oneof=draft published archived"`
}

type CreateCategoryRequest struct {
	Name        string `json:"name" validate:"required,min=2,max=100" binding:"required,min=2,max=100"`
	Description string `json:"description" validate:"omitempty,max=500" binding:"omitempty,max=500"`
}

type UpdateCategoryRequest struct {
	Name        *string `json:"name" validate:"omitempty,min=2,max=100" binding:"omitempty,min=2,max=100"`
	Description *string `json:"description" validate:"omitempty,max=500" binding:"omitempty,max=500"`
}

type CreateCommentRequest struct {
	PostID  uint   `json:"post_id" validate:"required,gt=0" binding:"required,gt=0"`
	Content string `json:"content" validate:"required,min=5,max=1000" binding:"required,min=5,max=1000"`
}

type UpdateCommentRequest struct {
	Content *string `json:"content" validate:"omitempty,min=5,max=1000" binding:"omitempty,min=5,max=1000"`
	Status  *string `json:"status" validate:"omitempty,oneof=pending approved rejected" binding:"omitempty,oneof=pending approved rejected"`
}

type UpdateProfileRequest struct {
	Name     *string `json:"name" validate:"omitempty,min=2,max=100" binding:"omitempty,min=2,max=100"`
	Username *string `json:"username" validate:"omitempty,min=3,max=50,alphanum" binding:"omitempty,min=3,max=50"`
	Email    *string `json:"email" validate:"omitempty,email" binding:"omitempty,email"`
}

type ChangePasswordRequest struct {
	CurrentPassword string `json:"current_password" validate:"required,min=8" binding:"required,min=8"`
	NewPassword     string `json:"new_password" validate:"required,min=8,max=128" binding:"required,min=8,max=128"`
	ConfirmPassword string `json:"confirm_password" validate:"required,eqfield=NewPassword" binding:"required,eqfield=NewPassword"`
}

// Standard API Response structure
type APIResponse struct {
	Success bool        `json:"success"`
	Message string      `json:"message,omitempty"`
	Data    interface{} `json:"data,omitempty"`
	Error   string      `json:"error,omitempty"`
	Code    string      `json:"code,omitempty"`
}

// Standard Error Response structure
type ErrorResponse struct {
	Success bool   `json:"success"`
	Error   string `json:"error"`
	Code    string `json:"code"`
	Details string `json:"details,omitempty"`
}

type ValidationError struct {
	Field   string `json:"field"`
	Message string `json:"message"`
	Value   string `json:"value,omitempty"`
}

type ValidationErrorResponse struct {
	Success bool              `json:"success"`
	Error   string            `json:"error"`
	Code    string            `json:"code"`
	Details []ValidationError `json:"details"`
}

type PaginationResponse struct {
	Data       interface{} `json:"data"`
	Total      int64       `json:"total"`
	Page       int         `json:"page"`
	PerPage    int         `json:"per_page"`
	TotalPages int         `json:"total_pages"`
}

// Enhanced pagination response with meta structure
type PaginatedAPIResponse struct {
	Success bool        `json:"success"`
	Message string      `json:"message,omitempty"`
	Data    interface{} `json:"data"`
	Meta    MetaData    `json:"meta"`
	Error   string      `json:"error,omitempty"`
	Code    string      `json:"code,omitempty"`
}

type MetaData struct {
	Page       int `json:"page"`
	Limit      int `json:"limit"`
	Total      int64 `json:"total"`
	TotalPages int `json:"total_pages"`
}

// Search and Filter DTOs
type PostSearchRequest struct {
	Query      string `form:"q" validate:"omitempty,min=2,max=100" binding:"omitempty,min=2,max=100"`
	CategoryID uint   `form:"category_id" validate:"omitempty,gt=0" binding:"omitempty,gt=0"`
	AuthorID   uint   `form:"author_id" validate:"omitempty,gt=0" binding:"omitempty,gt=0"`
	Status     string `form:"status" validate:"omitempty,oneof=draft published archived" binding:"omitempty,oneof=draft published archived"`
	Page       int    `form:"page" validate:"omitempty,min=1" binding:"omitempty,min=1"`
	Limit      int    `form:"limit" validate:"omitempty,min=1,max=100" binding:"omitempty,min=1,max=100"`
	Sort       string `form:"sort" validate:"omitempty,oneof=created_at updated_at title id" binding:"omitempty,oneof=created_at updated_at title id"`
	Order      string `form:"order" validate:"omitempty,oneof=asc desc" binding:"omitempty,oneof=asc desc"`
}

// Category search request
type CategorySearchRequest struct {
	Query string `form:"q" validate:"omitempty,min=2,max=100" binding:"omitempty,min=2,max=100"`
	Page  int    `form:"page" validate:"omitempty,min=1" binding:"omitempty,min=1"`
	Limit int    `form:"limit" validate:"omitempty,min=1,max=100" binding:"omitempty,min=1,max=100"`
	Sort  string `form:"sort" validate:"omitempty,oneof=created_at updated_at name id" binding:"omitempty,oneof=created_at updated_at name id"`
	Order string `form:"order" validate:"omitempty,oneof=asc desc" binding:"omitempty,oneof=asc desc"`
}

// JWT Claims
type JWTClaims struct {
	UserID   uint   `json:"user_id"`
	Email    string `json:"email"`
	Username string `json:"username"`
	Role     string `json:"role"`
	Type     string `json:"type"` // "access" or "refresh"
	IssuedAt int64  `json:"iat"`
	ExpiresAt int64 `json:"exp"`
}

// Refresh Token Model
type RefreshToken struct {
	ID        uint      `json:"id" gorm:"primaryKey"`
	UserID    uint      `json:"user_id" gorm:"not null;index"`
	Token     string    `json:"token" gorm:"uniqueIndex;not null;size:255"`
	ExpiresAt time.Time `json:"expires_at" gorm:"not null"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
	IsRevoked bool      `json:"is_revoked" gorm:"default:false"`

	// Relationships
	User *User `json:"user,omitempty" gorm:"foreignKey:UserID"`
}

// Health Check Response
type HealthResponse struct {
	Status    string            `json:"status"`
	Timestamp time.Time         `json:"timestamp"`
	Version   string            `json:"version"`
	Services  map[string]string `json:"services"`
}

// Rate Limit Response
type RateLimitResponse struct {
	Success bool   `json:"success"`
	Error   string `json:"error"`
	Code    string `json:"code"`
	Details struct {
		Limit     int `json:"limit"`
		Remaining int `json:"remaining"`
		ResetTime int `json:"reset_time"`
	} `json:"details"`
}

// Upload DTOs
type UploadResponse struct {
	Success  bool   `json:"success"`
	Message  string `json:"message"`
	Filename string `json:"filename"`
	URL      string `json:"url"`
	Size     int64  `json:"size"`
	MimeType string `json:"mime_type"`
}

type FileUpload struct {
	ID           uint      `json:"id" gorm:"primaryKey"`
	OriginalName string    `json:"original_name" gorm:"not null;size:255"`
	Filename     string    `json:"filename" gorm:"not null;size:255"`
	FilePath     string    `json:"file_path" gorm:"not null;size:500"`
	FileSize     int64     `json:"file_size" gorm:"not null"`
	MimeType     string    `json:"mime_type" gorm:"not null;size:100"`
	URL          string    `json:"url" gorm:"not null;size:500"`
	UserID       uint      `json:"user_id" gorm:"not null"`
	CreatedAt    time.Time `json:"created_at"`
	UpdatedAt    time.Time `json:"updated_at"`

	// Relationships
	User *User `json:"user,omitempty" gorm:"foreignKey:UserID"`
}
