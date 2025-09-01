package services

import (
	"fmt"
	"io"
	"mime/multipart"
	"os"
	"path/filepath"
	"strings"
	"time"

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
	uploadDir string
	baseURL   string
}

type S3StorageService struct {
	client     *s3.S3
	bucketName string
	region     string
	baseURL    string
}

func NewStorageService() StorageService {
	driver := os.Getenv("STORAGE_DRIVER")
	if driver == "" {
		driver = "local"
	}

	switch driver {
	case "s3":
		return NewS3StorageService()
	default:
		return NewLocalStorageService()
	}
}

func NewLocalStorageService() *LocalStorageService {
	uploadDir := os.Getenv("UPLOAD_DIR")
	if uploadDir == "" {
		uploadDir = "./storage/uploads"
	}

	baseURL := os.Getenv("BASE_URL")
	if baseURL == "" {
		baseURL = "http://localhost:8080"
	}

	// Create upload directory if it doesn't exist
	if err := os.MkdirAll(uploadDir, 0755); err != nil {
		panic(fmt.Sprintf("Failed to create upload directory: %v", err))
	}

	return &LocalStorageService{
		uploadDir: uploadDir,
		baseURL:   baseURL,
	}
}

func NewS3StorageService() *S3StorageService {
	region := os.Getenv("AWS_REGION")
	if region == "" {
		region = "us-east-1"
	}

	endpoint := os.Getenv("S3_ENDPOINT") // For MinIO compatibility
	accessKey := os.Getenv("AWS_ACCESS_KEY_ID")
	secretKey := os.Getenv("AWS_SECRET_ACCESS_KEY")
	bucketName := os.Getenv("S3_BUCKET_NAME")

	if bucketName == "" {
		panic("S3_BUCKET_NAME is required when using S3 storage")
	}

	config := &aws.Config{
		Region: aws.String(region),
	}

	if accessKey != "" && secretKey != "" {
		config.Credentials = credentials.NewStaticCredentials(accessKey, secretKey, "")
	}

	if endpoint != "" {
		config.Endpoint = aws.String(endpoint)
		config.S3ForcePathStyle = aws.Bool(true) // Required for MinIO
	}

	sess, err := session.NewSession(config)
	if err != nil {
		panic(fmt.Sprintf("Failed to create S3 session: %v", err))
	}

	baseURL := os.Getenv("S3_BASE_URL")
	if baseURL == "" {
		if endpoint != "" {
			baseURL = fmt.Sprintf("%s/%s", endpoint, bucketName)
		} else {
			baseURL = fmt.Sprintf("https://%s.s3.%s.amazonaws.com", bucketName, region)
		}
	}

	return &S3StorageService{
		client:     s3.New(sess),
		bucketName: bucketName,
		region:     region,
		baseURL:    baseURL,
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
	filePath := filepath.Join(s.uploadDir, filename)

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
	url := fmt.Sprintf("%s/uploads/%s", s.baseURL, filename)

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
	filePath := filepath.Join(s.uploadDir, filename)
	return os.Remove(filePath)
}

func (s *LocalStorageService) GetFileURL(filename string) string {
	return fmt.Sprintf("%s/uploads/%s", s.baseURL, filename)
}

func (s *LocalStorageService) ValidateImageFile(fileHeader *multipart.FileHeader) error {
	// Check file size (max 5MB)
	maxSize := int64(5 * 1024 * 1024) // 5MB
	if fileHeader.Size > maxSize {
		return fmt.Errorf("file size exceeds maximum allowed size of 5MB")
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
		Bucket:      aws.String(s.bucketName),
		Key:         aws.String(filename),
		Body:        src,
		ContentType: aws.String(fileHeader.Header.Get("Content-Type")),
		ACL:         aws.String("public-read"), // Make file publicly accessible
	})

	if err != nil {
		return nil, fmt.Errorf("failed to upload file to S3: %w", err)
	}

	// Generate public URL
	url := fmt.Sprintf("%s/%s", s.baseURL, filename)

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
		Bucket: aws.String(s.bucketName),
		Key:    aws.String(filename),
	})
	return err
}

func (s *S3StorageService) GetFileURL(filename string) string {
	return fmt.Sprintf("%s/%s", s.baseURL, filename)
}

func (s *S3StorageService) ValidateImageFile(fileHeader *multipart.FileHeader) error {
	// Reuse the same validation logic as local storage
	localStorage := &LocalStorageService{}
	return localStorage.ValidateImageFile(fileHeader)
}

// Utility functions
func GetImageSizeLimit() int64 {
	return 5 * 1024 * 1024 // 5MB
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
