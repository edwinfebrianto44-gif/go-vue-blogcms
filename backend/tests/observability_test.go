package tests

import (
	"backend/internal/middleware"
	"backend/pkg/logger"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gin-gonic/gin"
	"github.com/stretchr/testify/assert"
)

func TestCorrelationIDMiddleware(t *testing.T) {
	// Initialize logger for testing
	err := logger.InitLogger("test")
	assert.NoError(t, err)

	gin.SetMode(gin.TestMode)

	r := gin.New()
	r.Use(middleware.CorrelationIDMiddleware())

	r.GET("/test", func(c *gin.Context) {
		requestID := c.GetHeader("X-Request-ID")
		assert.NotEmpty(t, requestID)

		// Check if request ID is available in context
		ctxRequestID, exists := c.Get("request_id")
		assert.True(t, exists)
		assert.Equal(t, requestID, ctxRequestID)

		c.JSON(http.StatusOK, gin.H{"request_id": requestID})
	})

	// Test with provided request ID
	req1, _ := http.NewRequest("GET", "/test", nil)
	req1.Header.Set("X-Request-ID", "custom-request-123")
	w1 := httptest.NewRecorder()
	r.ServeHTTP(w1, req1)

	assert.Equal(t, http.StatusOK, w1.Code)
	assert.Equal(t, "custom-request-123", w1.Header().Get("X-Request-ID"))

	// Test without provided request ID (should generate one)
	req2, _ := http.NewRequest("GET", "/test", nil)
	w2 := httptest.NewRecorder()
	r.ServeHTTP(w2, req2)

	assert.Equal(t, http.StatusOK, w2.Code)
	assert.NotEmpty(t, w2.Header().Get("X-Request-ID"))
	assert.Len(t, w2.Header().Get("X-Request-ID"), 36) // UUID length
}

func TestLoggingMiddleware(t *testing.T) {
	// Initialize logger for testing
	err := logger.InitLogger("test")
	assert.NoError(t, err)

	gin.SetMode(gin.TestMode)

	r := gin.New()
	r.Use(middleware.CorrelationIDMiddleware())
	r.Use(middleware.LoggingMiddleware())

	r.GET("/test", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"message": "success"})
	})

	r.POST("/error", func(c *gin.Context) {
		c.Error(assert.AnError)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "test error"})
	})

	// Test successful request
	req1, _ := http.NewRequest("GET", "/test", nil)
	req1.Header.Set("User-Agent", "TestAgent/1.0")
	w1 := httptest.NewRecorder()
	r.ServeHTTP(w1, req1)

	assert.Equal(t, http.StatusOK, w1.Code)

	// Test request with error
	req2, _ := http.NewRequest("POST", "/error", nil)
	w2 := httptest.NewRecorder()
	r.ServeHTTP(w2, req2)

	assert.Equal(t, http.StatusInternalServerError, w2.Code)
}

func TestMetricsMiddleware(t *testing.T) {
	gin.SetMode(gin.TestMode)

	r := gin.New()
	r.Use(middleware.MetricsMiddleware())

	r.GET("/test", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"message": "success"})
	})

	r.GET("/metrics", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"metrics": "endpoint"})
	})

	// Test normal endpoint (should be tracked)
	req1, _ := http.NewRequest("GET", "/test", nil)
	w1 := httptest.NewRecorder()
	r.ServeHTTP(w1, req1)

	assert.Equal(t, http.StatusOK, w1.Code)

	// Test metrics endpoint (should be skipped)
	req2, _ := http.NewRequest("GET", "/metrics", nil)
	w2 := httptest.NewRecorder()
	r.ServeHTTP(w2, req2)

	assert.Equal(t, http.StatusOK, w2.Code)
}

func TestObservabilityMiddlewareStack(t *testing.T) {
	// Initialize logger for testing
	err := logger.InitLogger("test")
	assert.NoError(t, err)

	gin.SetMode(gin.TestMode)

	// Set up complete observability middleware stack
	r := gin.New()
	r.Use(middleware.CorrelationIDMiddleware())
	r.Use(middleware.LoggingMiddleware())
	r.Use(middleware.MetricsMiddleware())

	r.GET("/api/v1/posts", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"posts":      []string{"post1", "post2"},
			"request_id": c.GetHeader("X-Request-ID"),
		})
	})

	// Test complete stack
	req, _ := http.NewRequest("GET", "/api/v1/posts", nil)
	req.Header.Set("X-Request-ID", "integration-test-123")
	req.Header.Set("User-Agent", "IntegrationTest/1.0")
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	assert.Equal(t, http.StatusOK, w.Code)
	assert.Equal(t, "integration-test-123", w.Header().Get("X-Request-ID"))
	assert.Contains(t, w.Body.String(), "integration-test-123")
}
