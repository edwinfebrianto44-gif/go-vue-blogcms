package tests

import (
	"backend/internal/config"
	"backend/internal/database"
	"backend/internal/handlers"
	"backend/internal/middleware"
	"backend/internal/repositories"
	"backend/internal/routes"
	"backend/internal/services"
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"mime/multipart"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"testing"

	"github.com/gin-gonic/gin"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestUploadImageHandler(t *testing.T) {
	// Setup test environment
	gin.SetMode(gin.TestMode)
	
	// Create test config
	cfg := &config.Config{
		Storage: config.StorageConfig{
			Driver:      "local",
			UploadDir:   "./test_uploads",
			BaseURL:     "http://localhost:8080",
			MaxFileSize: 5242880, // 5MB
		},
		JWT: config.JWTConfig{
			Secret:      "test-secret",
			ExpireHours: 24,
		},
	}
	
	// Create test upload directory
	err := os.MkdirAll(cfg.Storage.UploadDir, 0755)
	require.NoError(t, err)
	defer os.RemoveAll(cfg.Storage.UploadDir)
	
	// Setup test database
	db, err := database.Connect("file::memory:?cache=shared")
	require.NoError(t, err)
	
	err = database.AutoMigrate(db)
	require.NoError(t, err)
	
	// Initialize repositories and services
	userRepo := repositories.NewUserRepository(db)
	refreshTokenRepo := repositories.NewRefreshTokenRepository(db)
	jwtService := services.NewJWTService(refreshTokenRepo)
	authService := services.NewAuthService(userRepo, jwtService, cfg)
	storageService := services.NewStorageService(cfg)
	
	// Initialize handlers
	authHandler := handlers.NewAuthHandler(authService)
	uploadHandler := handlers.NewUploadHandler(storageService, cfg)
	
	// Setup router
	r := gin.New()
	r.Use(middleware.ErrorHandlerMiddleware())
	
	// Setup auth routes
	auth := r.Group("/auth")
	{
		auth.POST("/register", authHandler.Register)
		auth.POST("/login", authHandler.Login)
	}
	
	// Setup upload routes
	uploads := r.Group("/uploads")
	{
		uploads.GET("/info", uploadHandler.GetUploadInfo)
		uploads.POST("/images", middleware.AuthMiddleware(jwtService), uploadHandler.UploadImage)
	}
	
	// Create test user and get auth token
	token := createTestUserAndGetToken(t, r)
	
	t.Run("Upload Info Endpoint", func(t *testing.T) {
		req, _ := http.NewRequest("GET", "/uploads/info", nil)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)
		
		assert.Equal(t, http.StatusOK, w.Code)
		
		var response map[string]interface{}
		err := json.Unmarshal(w.Body.Bytes(), &response)
		require.NoError(t, err)
		
		assert.True(t, response["success"].(bool))
		data := response["data"].(map[string]interface{})
		assert.Equal(t, "local", data["storage_driver"])
		assert.Equal(t, float64(5242880), data["max_file_size_bytes"])
	})
	
	t.Run("Upload Valid Image", func(t *testing.T) {
		// Create a simple test image
		imageContent := createTestImageBytes()
		
		body := &bytes.Buffer{}
		writer := multipart.NewWriter(body)
		
		part, err := writer.CreateFormFile("image", "test.jpg")
		require.NoError(t, err)
		
		_, err = part.Write(imageContent)
		require.NoError(t, err)
		
		err = writer.Close()
		require.NoError(t, err)
		
		req, _ := http.NewRequest("POST", "/uploads/images", body)
		req.Header.Set("Content-Type", writer.FormDataContentType())
		req.Header.Set("Authorization", "Bearer "+token)
		
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)
		
		assert.Equal(t, http.StatusOK, w.Code)
		
		var response map[string]interface{}
		err = json.Unmarshal(w.Body.Bytes(), &response)
		require.NoError(t, err)
		
		assert.True(t, response["success"].(bool))
		assert.NotEmpty(t, response["filename"])
		assert.NotEmpty(t, response["url"])
		assert.Contains(t, response["url"], "http://localhost:8080/uploads/")
	})
	
	t.Run("Upload Without Authentication", func(t *testing.T) {
		imageContent := createTestImageBytes()
		
		body := &bytes.Buffer{}
		writer := multipart.NewWriter(body)
		
		part, err := writer.CreateFormFile("image", "test.jpg")
		require.NoError(t, err)
		
		_, err = part.Write(imageContent)
		require.NoError(t, err)
		
		err = writer.Close()
		require.NoError(t, err)
		
		req, _ := http.NewRequest("POST", "/uploads/images", body)
		req.Header.Set("Content-Type", writer.FormDataContentType())
		
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)
		
		assert.Equal(t, http.StatusUnauthorized, w.Code)
	})
	
	t.Run("Upload Non-Image File", func(t *testing.T) {
		textContent := []byte("This is not an image file")
		
		body := &bytes.Buffer{}
		writer := multipart.NewWriter(body)
		
		part, err := writer.CreateFormFile("image", "test.txt")
		require.NoError(t, err)
		
		_, err = part.Write(textContent)
		require.NoError(t, err)
		
		err = writer.Close()
		require.NoError(t, err)
		
		req, _ := http.NewRequest("POST", "/uploads/images", body)
		req.Header.Set("Content-Type", writer.FormDataContentType())
		req.Header.Set("Authorization", "Bearer "+token)
		
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)
		
		assert.Equal(t, http.StatusBadRequest, w.Code)
		
		var response map[string]interface{}
		err = json.Unmarshal(w.Body.Bytes(), &response)
		require.NoError(t, err)
		
		assert.False(t, response["success"].(bool))
		assert.Contains(t, response["error"], "file type not allowed")
	})
	
	t.Run("Upload File Too Large", func(t *testing.T) {
		// Create a large file content (6MB)
		largeContent := make([]byte, 6*1024*1024)
		
		body := &bytes.Buffer{}
		writer := multipart.NewWriter(body)
		
		part, err := writer.CreateFormFile("image", "large.jpg")
		require.NoError(t, err)
		
		// Set proper MIME type
		part.(*multipart.Part).FormName()
		
		_, err = part.Write(largeContent)
		require.NoError(t, err)
		
		err = writer.Close()
		require.NoError(t, err)
		
		req, _ := http.NewRequest("POST", "/uploads/images", body)
		req.Header.Set("Content-Type", writer.FormDataContentType())
		req.Header.Set("Authorization", "Bearer "+token)
		
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)
		
		assert.Equal(t, http.StatusRequestEntityTooLarge, w.Code)
	})
}

func createTestUserAndGetToken(t *testing.T, r *gin.Engine) string {
	// Register user
	registerBody := map[string]string{
		"username": "testuser",
		"email":    "test@example.com",
		"password": "testpassword123",
		"name":     "Test User",
		"role":     "author",
	}
	
	registerData, _ := json.Marshal(registerBody)
	req, _ := http.NewRequest("POST", "/auth/register", bytes.NewBuffer(registerData))
	req.Header.Set("Content-Type", "application/json")
	
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)
	
	require.Equal(t, http.StatusCreated, w.Code)
	
	// Login to get token
	loginBody := map[string]string{
		"email":    "test@example.com",
		"password": "testpassword123",
	}
	
	loginData, _ := json.Marshal(loginBody)
	req, _ = http.NewRequest("POST", "/auth/login", bytes.NewBuffer(loginData))
	req.Header.Set("Content-Type", "application/json")
	
	w = httptest.NewRecorder()
	r.ServeHTTP(w, req)
	
	require.Equal(t, http.StatusOK, w.Code)
	
	var loginResponse map[string]interface{}
	err := json.Unmarshal(w.Body.Bytes(), &loginResponse)
	require.NoError(t, err)
	
	return loginResponse["access_token"].(string)
}

func createTestImageBytes() []byte {
	// Create a minimal JPEG header
	// This is a very small valid JPEG file
	return []byte{
		0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01,
		0x01, 0x01, 0x00, 0x48, 0x00, 0x48, 0x00, 0x00, 0xFF, 0xDB, 0x00, 0x43,
		0x00, 0x08, 0x06, 0x06, 0x07, 0x06, 0x05, 0x08, 0x07, 0x07, 0x07, 0x09,
		0x09, 0x08, 0x0A, 0x0C, 0x14, 0x0D, 0x0C, 0x0B, 0x0B, 0x0C, 0x19, 0x12,
		0x13, 0x0F, 0x14, 0x1D, 0x1A, 0x1F, 0x1E, 0x1D, 0x1A, 0x1C, 0x1C, 0x20,
		0x24, 0x2E, 0x27, 0x20, 0x22, 0x2C, 0x23, 0x1C, 0x1C, 0x28, 0x37, 0x29,
		0x2C, 0x30, 0x31, 0x34, 0x34, 0x34, 0x1F, 0x27, 0x39, 0x3D, 0x38, 0x32,
		0x3C, 0x2E, 0x33, 0x34, 0x32, 0xFF, 0xC0, 0x00, 0x11, 0x08, 0x00, 0x01,
		0x00, 0x01, 0x01, 0x01, 0x11, 0x00, 0x02, 0x11, 0x01, 0x03, 0x11, 0x01,
		0xFF, 0xC4, 0x00, 0x14, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
		0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x08, 0xFF, 0xC4,
		0x00, 0x14, 0x10, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
		0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xFF, 0xDA, 0x00, 0x0C,
		0x03, 0x01, 0x00, 0x02, 0x11, 0x03, 0x11, 0x00, 0x3F, 0x00, 0xB2, 0xFF, 0xD9,
	}
}

func TestStorageServiceValidation(t *testing.T) {
	cfg := &config.StorageConfig{
		Driver:      "local",
		UploadDir:   "./test_uploads",
		BaseURL:     "http://localhost:8080",
		MaxFileSize: 1024, // 1KB for testing
	}
	
	storageService := services.NewLocalStorageService(cfg)
	defer os.RemoveAll(cfg.UploadDir)
	
	t.Run("Valid Image File", func(t *testing.T) {
		// Create a test file header
		fileHeader := &multipart.FileHeader{
			Filename: "test.jpg",
			Size:     500, // Less than 1KB
			Header:   make(map[string][]string),
		}
		fileHeader.Header.Set("Content-Type", "image/jpeg")
		
		err := storageService.ValidateImageFile(fileHeader)
		assert.NoError(t, err)
	})
	
	t.Run("File Too Large", func(t *testing.T) {
		fileHeader := &multipart.FileHeader{
			Filename: "large.jpg",
			Size:     2048, // 2KB, larger than limit
			Header:   make(map[string][]string),
		}
		fileHeader.Header.Set("Content-Type", "image/jpeg")
		
		err := storageService.ValidateImageFile(fileHeader)
		assert.Error(t, err)
		assert.Contains(t, err.Error(), "exceeds maximum allowed size")
	})
	
	t.Run("Invalid File Extension", func(t *testing.T) {
		fileHeader := &multipart.FileHeader{
			Filename: "document.pdf",
			Size:     500,
			Header:   make(map[string][]string),
		}
		fileHeader.Header.Set("Content-Type", "application/pdf")
		
		err := storageService.ValidateImageFile(fileHeader)
		assert.Error(t, err)
		assert.Contains(t, err.Error(), "file type not allowed")
	})
	
	t.Run("Invalid MIME Type", func(t *testing.T) {
		fileHeader := &multipart.FileHeader{
			Filename: "fake.jpg",
			Size:     500,
			Header:   make(map[string][]string),
		}
		fileHeader.Header.Set("Content-Type", "text/plain")
		
		err := storageService.ValidateImageFile(fileHeader)
		assert.Error(t, err)
		assert.Contains(t, err.Error(), "invalid MIME type")
	})
}
