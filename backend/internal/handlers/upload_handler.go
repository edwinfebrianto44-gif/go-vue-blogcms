package handlers

import (
	"net/http"
	"os"

	"backend/internal/services"
	"backend/internal/utils"

	"github.com/gin-gonic/gin"
)

type UploadHandler struct {
	storageService services.StorageService
}

func NewUploadHandler(storageService services.StorageService) *UploadHandler {
	return &UploadHandler{
		storageService: storageService,
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
		utils.ErrorResponse(c, http.StatusUnauthorized, "User not authenticated")
		return
	}

	userID, ok := userIDInterface.(uint)
	if !ok {
		utils.ErrorResponse(c, http.StatusUnauthorized, "Invalid user ID")
		return
	}

	// Get uploaded file
	fileHeader, err := c.FormFile("image")
	if err != nil {
		utils.ErrorResponse(c, http.StatusBadRequest, "No image file provided")
		return
	}

	// Upload file using storage service
	uploadResponse, err := h.storageService.UploadFile(fileHeader, userID)
	if err != nil {
		// Check if it's a validation error
		if err.Error() == "file size exceeds maximum allowed size of 5MB" {
			utils.ErrorResponse(c, http.StatusRequestEntityTooLarge, err.Error())
			return
		}
		utils.ErrorResponse(c, http.StatusBadRequest, err.Error())
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
		"max_file_size":      "5MB",
		"max_file_size_bytes": services.GetImageSizeLimit(),
		"allowed_types":      services.GetAllowedImageTypes(),
		"allowed_mime_types": services.GetAllowedMimeTypes(),
		"storage_driver":     getStorageDriver(),
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
		utils.ErrorResponse(c, http.StatusUnauthorized, "User not authenticated")
		return
	}

	userRole, ok := userRoleInterface.(string)
	if !ok || userRole != "admin" {
		utils.ErrorResponse(c, http.StatusForbidden, "Admin access required")
		return
	}

	filename := c.Param("filename")
	if filename == "" {
		utils.ErrorResponse(c, http.StatusBadRequest, "Filename is required")
		return
	}

	// Delete file using storage service
	err := h.storageService.DeleteFile(filename)
	if err != nil {
		utils.ErrorResponse(c, http.StatusInternalServerError, "Failed to delete file")
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
		utils.ErrorResponse(c, http.StatusBadRequest, "Filename is required")
		return
	}

	// Only serve files for local storage
	if getStorageDriver() != "local" {
		utils.ErrorResponse(c, http.StatusNotFound, "File not found")
		return
	}

	// Get upload directory
	uploadDir := getUploadDir()
	filePath := uploadDir + "/" + filename

	// Set cache headers for images
	c.Header("Cache-Control", "public, max-age=31536000") // 1 year
	c.Header("Expires", "Thu, 31 Dec 2025 23:59:59 GMT")

	// Serve the file
	c.File(filePath)
}

// Helper functions
func getStorageDriver() string {
	driver := "local" // default
	if envDriver := os.Getenv("STORAGE_DRIVER"); envDriver != "" {
		driver = envDriver
	}
	return driver
}

func getUploadDir() string {
	uploadDir := "./storage/uploads" // default
	if envDir := os.Getenv("UPLOAD_DIR"); envDir != "" {
		uploadDir = envDir
	}
	return uploadDir
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
