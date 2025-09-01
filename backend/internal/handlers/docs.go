package handlers

import (
	"fmt"
	"io/ioutil"
	"net/http"
	"path/filepath"

	"github.com/gin-gonic/gin"
	ginSwagger "github.com/swaggo/gin-swagger"
	"github.com/swaggo/gin-swagger/swaggerFiles"
)

// DocsHandler handles documentation routes
type DocsHandler struct {
	openAPIPath string
}

// NewDocsHandler creates a new documentation handler
func NewDocsHandler() *DocsHandler {
	return &DocsHandler{
		openAPIPath: "docs/openapi.yaml",
	}
}

// SetupRoutes sets up documentation routes
func (h *DocsHandler) SetupRoutes(rg *gin.RouterGroup) {
	docs := rg.Group("/docs")
	{
		docs.GET("/", h.RedirectToSwagger)
		docs.GET("/swagger/*any", ginSwagger.WrapHandler(swaggerFiles.Handler))
		docs.GET("/openapi.yaml", h.ServeOpenAPISpec)
		docs.GET("/openapi.json", h.ServeOpenAPISpecJSON)
		docs.GET("/health", h.HealthCheck)
	}
}

// RedirectToSwagger redirects to Swagger UI
func (h *DocsHandler) RedirectToSwagger(c *gin.Context) {
	c.Redirect(http.StatusMovedPermanently, "/api/v1/docs/swagger/index.html")
}

// ServeOpenAPISpec serves the OpenAPI YAML specification
func (h *DocsHandler) ServeOpenAPISpec(c *gin.Context) {
	// Get the absolute path to the OpenAPI spec
	specPath, err := filepath.Abs(h.openAPIPath)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"status":  "error",
			"message": "Failed to resolve OpenAPI spec path",
		})
		return
	}

	// Read the OpenAPI specification file
	content, err := ioutil.ReadFile(specPath)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"status":  "error",
			"message": "OpenAPI specification not found",
		})
		return
	}

	c.Header("Content-Type", "application/x-yaml")
	c.Header("Access-Control-Allow-Origin", "*")
	c.Data(http.StatusOK, "application/x-yaml", content)
}

// ServeOpenAPISpecJSON serves the OpenAPI specification in JSON format
func (h *DocsHandler) ServeOpenAPISpecJSON(c *gin.Context) {
	// For now, redirect to YAML. In a real implementation, you might convert YAML to JSON
	c.JSON(http.StatusOK, gin.H{
		"status":  "info",
		"message": "JSON format not implemented yet. Please use /docs/openapi.yaml",
		"yaml_url": "/api/v1/docs/openapi.yaml",
	})
}

// HealthCheck provides API health status
func (h *DocsHandler) HealthCheck(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"status": "success",
		"message": "API documentation service is healthy",
		"data": gin.H{
			"service":     "BlogCMS API Documentation",
			"version":     "1.0.0",
			"swagger_ui":  "/api/v1/docs/swagger/index.html",
			"openapi_spec": "/api/v1/docs/openapi.yaml",
			"endpoints": gin.H{
				"swagger":     "/api/v1/docs/swagger/",
				"openapi":     "/api/v1/docs/openapi.yaml",
				"health":      "/api/v1/docs/health",
			},
		},
	})
}

// SetupSwaggerInfo sets up Swagger documentation info
func SetupSwaggerInfo() {
	// This would typically be done with swaggo/swag annotations
	// For now, we're serving the static OpenAPI YAML file
	fmt.Println("📚 Swagger UI available at: /api/v1/docs/swagger/index.html")
	fmt.Println("📄 OpenAPI Spec available at: /api/v1/docs/openapi.yaml")
}
