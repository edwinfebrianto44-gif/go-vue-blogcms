package services

import (
	"fmt"
	"io"
	"mime/multipart"
	"os"
	"path/filepath"
	"strings"
	"time"

	"backend/internal/config"
	"backend/internal/models"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/credentials"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/s3"
	"github.com/google/uuid"
)

type StorageService interface {
	UploadFile(file *multipart.FileHeader, userID uint) (*models.UploadResponse, error)
	DeleteFile(filename string) error
	GetFileURL(filename string) string
	ValidateImageFile(file *multipart.FileHeader) error
}

type LocalStorageService struct {
	config *config.StorageConfig
}

type S3StorageService struct {
	client *s3.S3
	config *config.StorageConfig
}

func NewStorageService(cfg *config.Config) StorageService {
	switch cfg.Storage.Driver {
	case "s3":
		return NewS3StorageService(&cfg.Storage)
	default:
		return NewLocalStorageService(&cfg.Storage)
	}
}

func NewLocalStorageService(cfg *config.StorageConfig) *LocalStorageService {
	// Create upload directory if it doesn't exist
	if err := os.MkdirAll(cfg.UploadDir, 0755); err != nil {
		panic(fmt.Sprintf("Failed to create upload directory: %v", err))
	}

	return &LocalStorageService{
		config: cfg,
	}
}

func NewS3StorageService(cfg *config.StorageConfig) *S3StorageService {
	if cfg.S3Bucket == "" {
		panic("S3_BUCKET_NAME is required when using S3 storage")
	}

	awsConfig := &aws.Config{
		Region: aws.String(cfg.S3Region),
	}

	if cfg.S3AccessKey != "" && cfg.S3SecretKey != "" {
		awsConfig.Credentials = credentials.NewStaticCredentials(cfg.S3AccessKey, cfg.S3SecretKey, "")
	}

	if cfg.S3Endpoint != "" {
		awsConfig.Endpoint = aws.String(cfg.S3Endpoint)
		awsConfig.S3ForcePathStyle = aws.Bool(cfg.S3ForcePathStyle)
	}

	sess, err := session.NewSession(awsConfig)
	if err != nil {
		panic(fmt.Sprintf("Failed to create S3 session: %v", err))
	}

	return &S3StorageService{
		client: s3.New(sess),
		config: cfg,
	}
}

// Local Storage Implementation
func (s *LocalStorageService) UploadFile(fileHeader *multipart.FileHeader, userID uint) (*models.UploadResponse, error) {
	// Validate file
	if err := s.ValidateImageFile(fileHeader); err != nil {
		return nil, err
	}

	// Generate unique filename
	ext := filepath.Ext(fileHeader.Filename)
	filename := fmt.Sprintf("%s_%d%s", uuid.New().String(), time.Now().Unix(), ext)

	// Create file path
	filePath := filepath.Join(s.config.UploadDir, filename)

	// Open uploaded file
	src, err := fileHeader.Open()
	if err != nil {
		return nil, fmt.Errorf("failed to open uploaded file: %w", err)
	}
	defer src.Close()

	// Create destination file
	dst, err := os.Create(filePath)
	if err != nil {
		return nil, fmt.Errorf("failed to create destination file: %w", err)
	}
	defer dst.Close()

	// Copy file content
	if _, err := io.Copy(dst, src); err != nil {
		return nil, fmt.Errorf("failed to copy file: %w", err)
	}

	// Generate public URL
	url := fmt.Sprintf("%s/uploads/%s", s.config.BaseURL, filename)

	return &models.UploadResponse{
		Success:  true,
		Message:  "File uploaded successfully",
		Filename: filename,
		URL:      url,
		Size:     fileHeader.Size,
		MimeType: fileHeader.Header.Get("Content-Type"),
	}, nil
}

func (s *LocalStorageService) DeleteFile(filename string) error {
	filePath := filepath.Join(s.config.UploadDir, filename)
	return os.Remove(filePath)
}

func (s *LocalStorageService) GetFileURL(filename string) string {
	return fmt.Sprintf("%s/uploads/%s", s.config.BaseURL, filename)
}

func (s *LocalStorageService) ValidateImageFile(fileHeader *multipart.FileHeader) error {
	// Check file size
	if fileHeader.Size > s.config.MaxFileSize {
		return fmt.Errorf("file size exceeds maximum allowed size of %d bytes", s.config.MaxFileSize)
	}

	// Check file extension
	ext := strings.ToLower(filepath.Ext(fileHeader.Filename))
	allowedExts := []string{".jpg", ".jpeg", ".png", ".gif", ".webp"}
	
	allowed := false
	for _, allowedExt := range allowedExts {
		if ext == allowedExt {
			allowed = true
			break
		}
	}
	
	if !allowed {
		return fmt.Errorf("file type not allowed. Allowed types: JPG, JPEG, PNG, GIF, WebP")
	}

	// Check MIME type
	mimeType := fileHeader.Header.Get("Content-Type")
	allowedMimes := []string{
		"image/jpeg",
		"image/jpg", 
		"image/png",
		"image/gif",
		"image/webp",
	}
	
	allowed = false
	for _, allowedMime := range allowedMimes {
		if mimeType == allowedMime {
			allowed = true
			break
		}
	}
	
	if !allowed {
		return fmt.Errorf("invalid MIME type. Expected image type, got: %s", mimeType)
	}

	return nil
}

// S3 Storage Implementation
func (s *S3StorageService) UploadFile(fileHeader *multipart.FileHeader, userID uint) (*models.UploadResponse, error) {
	// Validate file
	if err := s.ValidateImageFile(fileHeader); err != nil {
		return nil, err
	}

	// Generate unique filename
	ext := filepath.Ext(fileHeader.Filename)
	filename := fmt.Sprintf("images/%d/%s_%d%s", userID, uuid.New().String(), time.Now().Unix(), ext)

	// Open uploaded file
	src, err := fileHeader.Open()
	if err != nil {
		return nil, fmt.Errorf("failed to open uploaded file: %w", err)
	}
	defer src.Close()

	// Upload to S3
	_, err = s.client.PutObject(&s3.PutObjectInput{
		Bucket:      aws.String(s.config.S3Bucket),
		Key:         aws.String(filename),
		Body:        src,
		ContentType: aws.String(fileHeader.Header.Get("Content-Type")),
		ACL:         aws.String("public-read"), // Make file publicly accessible
	})

	if err != nil {
		return nil, fmt.Errorf("failed to upload file to S3: %w", err)
	}

	// Generate public URL
	var url string
	if s.config.S3BaseURL != "" {
		url = fmt.Sprintf("%s/%s", s.config.S3BaseURL, filename)
	} else if s.config.S3Endpoint != "" {
		url = fmt.Sprintf("%s/%s/%s", s.config.S3Endpoint, s.config.S3Bucket, filename)
	} else {
		url = fmt.Sprintf("https://%s.s3.%s.amazonaws.com/%s", s.config.S3Bucket, s.config.S3Region, filename)
	}

	return &models.UploadResponse{
		Success:  true,
		Message:  "File uploaded successfully",
		Filename: filename,
		URL:      url,
		Size:     fileHeader.Size,
		MimeType: fileHeader.Header.Get("Content-Type"),
	}, nil
}

func (s *S3StorageService) DeleteFile(filename string) error {
	_, err := s.client.DeleteObject(&s3.DeleteObjectInput{
		Bucket: aws.String(s.config.S3Bucket),
		Key:    aws.String(filename),
	})
	return err
}

func (s *S3StorageService) GetFileURL(filename string) string {
	if s.config.S3BaseURL != "" {
		return fmt.Sprintf("%s/%s", s.config.S3BaseURL, filename)
	} else if s.config.S3Endpoint != "" {
		return fmt.Sprintf("%s/%s/%s", s.config.S3Endpoint, s.config.S3Bucket, filename)
	} else {
		return fmt.Sprintf("https://%s.s3.%s.amazonaws.com/%s", s.config.S3Bucket, s.config.S3Region, filename)
	}
}

func (s *S3StorageService) ValidateImageFile(fileHeader *multipart.FileHeader) error {
	// Reuse the same validation logic as local storage
	localStorage := &LocalStorageService{config: s.config}
	return localStorage.ValidateImageFile(fileHeader)
}

// Utility functions
func GetImageSizeLimit(cfg *config.StorageConfig) int64 {
	if cfg != nil {
		return cfg.MaxFileSize
	}
	return 5 * 1024 * 1024 // 5MB default
}

func GetAllowedImageTypes() []string {
	return []string{".jpg", ".jpeg", ".png", ".gif", ".webp"}
}

func GetAllowedMimeTypes() []string {
	return []string{
		"image/jpeg",
		"image/jpg",
		"image/png", 
		"image/gif",
		"image/webp",
	}
}
