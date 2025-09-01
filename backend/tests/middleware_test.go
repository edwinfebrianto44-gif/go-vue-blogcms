package middleware_test

import (
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"backend/internal/middleware"

	"github.com/gin-gonic/gin"
	"github.com/stretchr/testify/assert"
)

func TestRateLimitMiddleware(t *testing.T) {
	gin.SetMode(gin.TestMode)

	tests := []struct {
		name            string
		requestsPerMin  float64
		requestCount    int
		expectedStatus  int
		expectedBlocked bool
	}{
		{
			name:            "Within rate limit",
			requestsPerMin:  10,
			requestCount:    5,
			expectedStatus:  http.StatusOK,
			expectedBlocked: false,
		},
		{
			name:            "Exceeds rate limit",
			requestsPerMin:  2,
			requestCount:    5,
			expectedStatus:  http.StatusTooManyRequests,
			expectedBlocked: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			r := gin.New()
			r.Use(middleware.RateLimitMiddleware(tt.requestsPerMin))
			
			r.GET("/test", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{"message": "success"})
			})

			blocked := false
			for i := 0; i < tt.requestCount; i++ {
				req, _ := http.NewRequest("GET", "/test", nil)
				req.Header.Set("X-Forwarded-For", "192.168.1.1") // Consistent IP
				
				w := httptest.NewRecorder()
				r.ServeHTTP(w, req)

				if w.Code == http.StatusTooManyRequests {
					blocked = true
					break
				}

				// Small delay between requests
				time.Sleep(time.Millisecond * 100)
			}

			assert.Equal(t, tt.expectedBlocked, blocked)
		})
	}
}

func TestAdvancedRateLimitMiddleware(t *testing.T) {
	gin.SetMode(gin.TestMode)

	r := gin.New()
	r.Use(middleware.AdvancedRateLimitMiddleware())
	
	// Login endpoint (stricter limit)
	r.POST("/api/v1/auth/login", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"message": "login success"})
	})
	
	// Regular API endpoint (more lenient)
	r.GET("/api/v1/posts", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"message": "posts"})
	})

	t.Run("Login endpoint rate limiting", func(t *testing.T) {
		blocked := false
		for i := 0; i < 10; i++ {
			req, _ := http.NewRequest("POST", "/api/v1/auth/login", nil)
			req.Header.Set("X-Forwarded-For", "192.168.1.2")
			
			w := httptest.NewRecorder()
			r.ServeHTTP(w, req)

			if w.Code == http.StatusTooManyRequests {
				blocked = true
				break
			}
		}
		
		assert.True(t, blocked, "Login endpoint should be rate limited after several requests")
	})

	t.Run("Regular endpoint rate limiting", func(t *testing.T) {
		success := false
		for i := 0; i < 50; i++ {
			req, _ := http.NewRequest("GET", "/api/v1/posts", nil)
			req.Header.Set("X-Forwarded-For", "192.168.1.3")
			
			w := httptest.NewRecorder()
			r.ServeHTTP(w, req)

			if w.Code == http.StatusOK {
				success = true
			}
		}
		
		assert.True(t, success, "Regular endpoints should allow more requests")
	})
}

func TestCORSMiddleware(t *testing.T) {
	gin.SetMode(gin.TestMode)

	r := gin.New()
	r.Use(middleware.CORSMiddleware())
	
	r.GET("/test", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"message": "success"})
	})

	t.Run("CORS headers are set", func(t *testing.T) {
		req, _ := http.NewRequest("GET", "/test", nil)
		req.Header.Set("Origin", "http://localhost:3000")
		
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusOK, w.Code)
		assert.Contains(t, w.Header().Get("Access-Control-Allow-Origin"), "localhost:3000")
		assert.Equal(t, "true", w.Header().Get("Access-Control-Allow-Credentials"))
	})

	t.Run("OPTIONS request handling", func(t *testing.T) {
		req, _ := http.NewRequest("OPTIONS", "/test", nil)
		req.Header.Set("Origin", "http://localhost:3000")
		req.Header.Set("Access-Control-Request-Method", "POST")
		
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusOK, w.Code)
		assert.Contains(t, w.Header().Get("Access-Control-Allow-Methods"), "POST")
	})
}

func TestSecurityHeadersMiddleware(t *testing.T) {
	gin.SetMode(gin.TestMode)

	r := gin.New()
	r.Use(middleware.SecurityHeadersMiddleware())
	
	r.GET("/test", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"message": "success"})
	})

	req, _ := http.NewRequest("GET", "/test", nil)
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	assert.Equal(t, http.StatusOK, w.Code)
	assert.Equal(t, "nosniff", w.Header().Get("X-Content-Type-Options"))
	assert.Equal(t, "DENY", w.Header().Get("X-Frame-Options"))
	assert.Equal(t, "1; mode=block", w.Header().Get("X-XSS-Protection"))
	assert.Contains(t, w.Header().Get("Strict-Transport-Security"), "max-age=31536000")
	assert.Equal(t, "strict-origin-when-cross-origin", w.Header().Get("Referrer-Policy"))
	assert.Contains(t, w.Header().Get("Content-Security-Policy"), "default-src 'self'")
}

func TestRequestIDMiddleware(t *testing.T) {
	gin.SetMode(gin.TestMode)

	r := gin.New()
	r.Use(middleware.RequestIDMiddleware())
	
	r.GET("/test", func(c *gin.Context) {
		requestID, exists := c.Get("request_id")
		if exists {
			c.JSON(http.StatusOK, gin.H{"request_id": requestID})
		} else {
			c.JSON(http.StatusOK, gin.H{"message": "no request id"})
		}
	})

	t.Run("Request ID is generated", func(t *testing.T) {
		req, _ := http.NewRequest("GET", "/test", nil)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusOK, w.Code)
		assert.NotEmpty(t, w.Header().Get("X-Request-ID"))
	})

	t.Run("Existing Request ID is preserved", func(t *testing.T) {
		req, _ := http.NewRequest("GET", "/test", nil)
		req.Header.Set("X-Request-ID", "existing-request-id")
		
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusOK, w.Code)
		assert.Equal(t, "existing-request-id", w.Header().Get("X-Request-ID"))
	})
}
