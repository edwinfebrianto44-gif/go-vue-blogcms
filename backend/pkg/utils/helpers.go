package utils

import (
	"math"
	"regexp"
	"strconv"
	"strings"

	"backend/internal/models"

	"github.com/gin-gonic/gin"
)

func GenerateSlug(title string) string {
	// Convert to lowercase
	slug := strings.ToLower(title)
	
	// Replace spaces with hyphens
	slug = strings.ReplaceAll(slug, " ", "-")
	
	// Remove special characters except hyphens
	reg := regexp.MustCompile(`[^a-z0-9\-]`)
	slug = reg.ReplaceAllString(slug, "")
	
	// Remove multiple consecutive hyphens
	reg = regexp.MustCompile(`-+`)
	slug = reg.ReplaceAllString(slug, "-")
	
	// Trim hyphens from start and end
	slug = strings.Trim(slug, "-")
	
	return slug
}

func SuccessResponse(message string, data interface{}) models.APIResponse {
	return models.APIResponse{
		Success: true,
		Message: message,
		Data:    data,
	}
}

func ErrorResponse(message string, err string) models.APIResponse {
	return models.APIResponse{
		Success: false,
		Message: message,
		Error:   err,
	}
}

func GetPaginationParams(c *gin.Context) (page int, perPage int) {
	page = 1
	perPage = 10

	if p := c.Query("page"); p != "" {
		if parsed, err := strconv.Atoi(p); err == nil && parsed > 0 {
			page = parsed
		}
	}

	if pp := c.Query("per_page"); pp != "" {
		if parsed, err := strconv.Atoi(pp); err == nil && parsed > 0 && parsed <= 100 {
			perPage = parsed
		}
	}

	// Also support 'limit' parameter
	if limit := c.Query("limit"); limit != "" {
		if parsed, err := strconv.Atoi(limit); err == nil && parsed > 0 && parsed <= 100 {
			perPage = parsed
		}
	}

	return page, perPage
}

func PaginationResponse(data interface{}, total int64, page, perPage int) models.PaginationResponse {
	totalPages := int(math.Ceil(float64(total) / float64(perPage)))
	
	return models.PaginationResponse{
		Data:       data,
		Total:      total,
		Page:       page,
		PerPage:    perPage,
		TotalPages: totalPages,
	}
}

// Enhanced pagination response with meta structure
func PaginatedAPIResponse(data interface{}, total int64, page, limit int, message string) models.PaginatedAPIResponse {
	totalPages := int(math.Ceil(float64(total) / float64(limit)))
	
	return models.PaginatedAPIResponse{
		Success: true,
		Message: message,
		Data:    data,
		Meta: models.MetaData{
			Page:       page,
			Limit:      limit,
			Total:      total,
			TotalPages: totalPages,
		},
	}
}
