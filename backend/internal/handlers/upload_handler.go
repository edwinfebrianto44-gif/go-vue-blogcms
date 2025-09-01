package handlers

import (
	"fmt"
	"net/http"
	"path/filepath"
	"strings"

	"backend/internal/config"
	"backend/internal/services"
	"backend/pkg/utils"

	"github.com/gin-gonic/gin"
)

type UploadHandler struct {
	storageService services.StorageService
	config         *config.Config
}

func NewUploadHandler(storageService services.StorageService, cfg *config.Config) *UploadHandler {
	return &UploadHandler{
		storageService: storageService,
		config:         cfg,
	}
}

// UploadImage handles image upload
// @Summary Upload image
// @Description Upload an image file for posts
// @Tags uploads
// @Accept multipart/form-data
// @Produce json
// @Security ApiKeyAuth
// @Param image formData file true "Image file to upload"
// @Success 200 {object} models.UploadResponse
// @Failure 400 {object} utils.ErrorResponse
// @Failure 401 {object} utils.ErrorResponse
// @Failure 413 {object} utils.ErrorResponse
// @Failure 500 {object} utils.ErrorResponse
// @Router /uploads/images [post]
func (h *UploadHandler) UploadImage(c *gin.Context) {
	// Get user ID from context (set by auth middleware)
	userIDInterface, exists := c.Get("user_id")
	if !exists {
		utils.ErrorResponse(c, http.StatusUnauthorized, "User not authenticated", "ERR_AUTH_REQUIRED")
		return
	}

	userID, ok := userIDInterface.(uint)
	if !ok {
		utils.ErrorResponse(c, http.StatusUnauthorized, "Invalid user ID", "ERR_AUTH_INVALID_USER")
		return
	}

	// Get uploaded file
	fileHeader, err := c.FormFile("image")
	if err != nil {
		utils.ErrorResponse(c, http.StatusBadRequest, "No image file provided", "ERR_NO_FILE")
		return
	}

	// Upload file using storage service
	uploadResponse, err := h.storageService.UploadFile(fileHeader, userID)
	if err != nil {
		// Check if it's a validation error
		if strings.Contains(err.Error(), "exceeds maximum allowed size") {
			utils.ErrorResponse(c, http.StatusRequestEntityTooLarge, err.Error(), "ERR_FILE_TOO_LARGE")
			return
		}
		utils.ErrorResponse(c, http.StatusBadRequest, err.Error(), "ERR_UPLOAD_FAILED")
		return
	}

	c.JSON(http.StatusOK, uploadResponse)
}

// GetUploadInfo provides information about upload requirements
// @Summary Get upload information
// @Description Get information about file upload requirements and limits
// @Tags uploads
// @Produce json
// @Success 200 {object} gin.H
// @Router /uploads/info [get]
func (h *UploadHandler) GetUploadInfo(c *gin.Context) {
	info := gin.H{
		"max_file_size":      fmt.Sprintf("%d bytes", h.config.Storage.MaxFileSize),
		"max_file_size_mb":   float64(h.config.Storage.MaxFileSize) / (1024 * 1024),
		"max_file_size_bytes": h.config.Storage.MaxFileSize,
		"allowed_types":      services.GetAllowedImageTypes(),
		"allowed_mime_types": services.GetAllowedMimeTypes(),
		"storage_driver":     h.config.Storage.Driver,
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    info,
	})
}

// DeleteImage handles image deletion (admin only)
// @Summary Delete image
// @Description Delete an uploaded image file (admin only)
// @Tags uploads
// @Accept json
// @Produce json
// @Security ApiKeyAuth
// @Param filename path string true "Filename to delete"
// @Success 200 {object} gin.H
// @Failure 400 {object} utils.ErrorResponse
// @Failure 401 {object} utils.ErrorResponse
// @Failure 403 {object} utils.ErrorResponse
// @Failure 404 {object} utils.ErrorResponse
// @Failure 500 {object} utils.ErrorResponse
// @Router /uploads/images/{filename} [delete]
func (h *UploadHandler) DeleteImage(c *gin.Context) {
	// Get user role from context
	userRoleInterface, exists := c.Get("user_role")
	if !exists {
		utils.ErrorResponse(c, http.StatusUnauthorized, "User not authenticated", "ERR_AUTH_REQUIRED")
		return
	}

	userRole, ok := userRoleInterface.(string)
	if !ok || userRole != "admin" {
		utils.ErrorResponse(c, http.StatusForbidden, "Admin access required", "ERR_AUTH_ADMIN_REQUIRED")
		return
	}

	filename := c.Param("filename")
	if filename == "" {
		utils.ErrorResponse(c, http.StatusBadRequest, "Filename is required", "ERR_MISSING_FILENAME")
		return
	}

	// Delete file using storage service
	err := h.storageService.DeleteFile(filename)
	if err != nil {
		utils.ErrorResponse(c, http.StatusInternalServerError, "Failed to delete file", "ERR_DELETE_FAILED")
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "File deleted successfully",
	})
}

// ServeLocalImage serves local images (only for local storage)
// @Summary Serve local image
// @Description Serve a locally stored image file
// @Tags uploads
// @Produce image/jpeg,image/png,image/gif,image/webp
// @Param filename path string true "Image filename"
// @Success 200 {file} file
// @Failure 404 {object} utils.ErrorResponse
// @Router /uploads/{filename} [get]
func (h *UploadHandler) ServeLocalImage(c *gin.Context) {
	filename := c.Param("filename")
	if filename == "" {
		utils.ErrorResponse(c, http.StatusBadRequest, "Filename is required", "ERR_MISSING_FILENAME")
		return
	}

	// Only serve files for local storage
	if h.config.Storage.Driver != "local" {
		utils.ErrorResponse(c, http.StatusNotFound, "File not found", "ERR_FILE_NOT_FOUND")
		return
	}

	// Create file path
	filePath := filepath.Join(h.config.Storage.UploadDir, filename)

	// Set cache headers for images
	c.Header("Cache-Control", "public, max-age=31536000") // 1 year
	c.Header("Expires", "Thu, 31 Dec 2025 23:59:59 GMT")

	// Serve the file
	c.File(filePath)
}

// Routes setup
func SetupUploadRoutes(router *gin.Engine, uploadHandler *UploadHandler, authMiddleware gin.HandlerFunc) {
	uploadGroup := router.Group("/uploads")
	{
		// Public routes
		uploadGroup.GET("/info", uploadHandler.GetUploadInfo)
		
		// Serve local images (only for local storage)
		uploadGroup.GET("/:filename", uploadHandler.ServeLocalImage)
		
		// Protected routes (require authentication)
		uploadGroup.POST("/images", authMiddleware, uploadHandler.UploadImage)
		uploadGroup.DELETE("/images/:filename", authMiddleware, uploadHandler.DeleteImage)
	}
}
