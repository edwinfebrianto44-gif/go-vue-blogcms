package utils

import (
	"backend/internal/models"
	"net/http"

	"github.com/gin-gonic/gin"
)

// Standard error response helper
func ErrorResponse(c *gin.Context, status int, message, code string, details ...string) {
	response := models.ErrorResponse{
		Success: false,
		Error:   message,
		Code:    code,
	}
	
	if len(details) > 0 {
		response.Details = details[0]
	}

	c.JSON(status, response)
}

// Standard success response helper
func SuccessResponse(c *gin.Context, status int, message string, data interface{}) {
	response := models.APIResponse{
		Success: true,
		Message: message,
		Data:    data,
	}

	c.JSON(status, response)
}

// Validation error response helper
func ValidationErrorResponse(c *gin.Context, errors []models.ValidationError) {
	response := models.ValidationErrorResponse{
		Success: false,
		Error:   "Validation failed",
		Code:    "ERR_VALIDATION",
		Details: errors,
	}

	c.JSON(http.StatusBadRequest, response)
}

// Common error responses
func BadRequest(c *gin.Context, message string, details ...string) {
	ErrorResponse(c, http.StatusBadRequest, message, "ERR_BAD_REQUEST", details...)
}

func Unauthorized(c *gin.Context, message string, details ...string) {
	ErrorResponse(c, http.StatusUnauthorized, message, "ERR_UNAUTHORIZED", details...)
}

func Forbidden(c *gin.Context, message string, details ...string) {
	ErrorResponse(c, http.StatusForbidden, message, "ERR_FORBIDDEN", details...)
}

func NotFound(c *gin.Context, message string, details ...string) {
	ErrorResponse(c, http.StatusNotFound, message, "ERR_NOT_FOUND", details...)
}

func InternalServerError(c *gin.Context, message string, details ...string) {
	ErrorResponse(c, http.StatusInternalServerError, message, "ERR_INTERNAL_SERVER", details...)
}

func TooManyRequests(c *gin.Context, message string, details ...string) {
	ErrorResponse(c, http.StatusTooManyRequests, message, "ERR_RATE_LIMIT", details...)
}

// Success response helpers
func OK(c *gin.Context, message string, data interface{}) {
	SuccessResponse(c, http.StatusOK, message, data)
}

func Created(c *gin.Context, message string, data interface{}) {
	SuccessResponse(c, http.StatusCreated, message, data)
}

func NoContent(c *gin.Context) {
	c.Status(http.StatusNoContent)
}

// Pagination response helper
func PaginationResponse(c *gin.Context, data interface{}, total int64, page, perPage int) {
	totalPages := int((total + int64(perPage) - 1) / int64(perPage))
	
	response := models.APIResponse{
		Success: true,
		Data: models.PaginationResponse{
			Data:       data,
			Total:      total,
			Page:       page,
			PerPage:    perPage,
			TotalPages: totalPages,
		},
	}

	c.JSON(http.StatusOK, response)
}
