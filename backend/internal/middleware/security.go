package middleware

import (
	"net/http"
	"os"
	"strings"
	"time"

	"backend/internal/models"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
	"github.com/didip/tollbooth/v7"
	"github.com/didip/tollbooth/v7/limiter"
	"golang.org/x/time/rate"
)

// CORS middleware with strict configuration
func CORSMiddleware() gin.HandlerFunc {
	allowedOrigins := []string{
		"http://localhost:3000",  // Default frontend dev
		"http://localhost:5173",  // Vite dev server
		"http://localhost:8080",  // Backend docs
	}

	// Add custom origins from environment
	if envOrigins := os.Getenv("ALLOWED_ORIGINS"); envOrigins != "" {
		customOrigins := strings.Split(envOrigins, ",")
		for _, origin := range customOrigins {
			origin = strings.TrimSpace(origin)
			if origin != "" {
				allowedOrigins = append(allowedOrigins, origin)
			}
		}
	}

	return cors.New(cors.Config{
		AllowOrigins:     allowedOrigins,
		AllowMethods:     []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"},
		AllowHeaders:     []string{"Origin", "Content-Type", "Accept", "Authorization", "X-Requested-With"},
		ExposeHeaders:    []string{"Content-Length", "X-Rate-Limit-Remaining", "X-Rate-Limit-Reset"},
		AllowCredentials: true,
		MaxAge:           12 * time.Hour,
	})
}

// Rate limiting middleware using tollbooth
func RateLimitMiddleware(requestsPerMinute float64) gin.HandlerFunc {
	lmt := tollbooth.NewLimiter(requestsPerMinute, &limiter.ExpirableOptions{
		DefaultExpirationTTL: time.Hour,
	})

	// Customize limiter
	lmt.SetIPLookups([]string{"X-Forwarded-For", "X-Real-IP", "RemoteAddr"})
	lmt.SetMethods([]string{"GET", "POST", "PUT", "DELETE"})

	return func(c *gin.Context) {
		httpError := tollbooth.LimitByRequest(lmt, c.Writer, c.Request)
		if httpError != nil {
			c.JSON(http.StatusTooManyRequests, models.ErrorResponse{
				Success: false,
				Error:   "Rate limit exceeded",
				Code:    "ERR_RATE_LIMIT",
				Details: "Too many requests. Please try again later.",
			})
			c.Abort()
			return
		}
		c.Next()
	}
}

// Advanced rate limiting with different tiers
type RateLimiter struct {
	limiters map[string]*rate.Limiter
}

func NewRateLimiter() *RateLimiter {
	return &RateLimiter{
		limiters: make(map[string]*rate.Limiter),
	}
}

func (rl *RateLimiter) GetLimiter(key string, r rate.Limit, b int) *rate.Limiter {
	if limiter, exists := rl.limiters[key]; exists {
		return limiter
	}

	newLimiter := rate.NewLimiter(r, b)
	rl.limiters[key] = newLimiter
	return newLimiter
}

// Advanced rate limiting middleware with different limits per endpoint
func AdvancedRateLimitMiddleware() gin.HandlerFunc {
	rateLimiter := NewRateLimiter()

	return func(c *gin.Context) {
		clientIP := c.ClientIP()
		path := c.Request.URL.Path
		method := c.Request.Method

		// Define rate limits for different endpoints
		var r rate.Limit
		var b int

		switch {
		case strings.HasPrefix(path, "/api/v1/auth/login"):
			// Login: 5 requests per minute
			r = rate.Every(time.Minute / 5)
			b = 5
		case strings.HasPrefix(path, "/api/v1/auth/register"):
			// Register: 3 requests per minute
			r = rate.Every(time.Minute / 3)
			b = 3
		case strings.HasPrefix(path, "/api/v1/auth/refresh"):
			// Refresh: 10 requests per minute
			r = rate.Every(time.Minute / 10)
			b = 10
		case method == "POST" || method == "PUT" || method == "DELETE":
			// Write operations: 30 requests per minute
			r = rate.Every(time.Minute / 30)
			b = 30
		default:
			// Read operations: 60 requests per minute
			r = rate.Every(time.Minute / 60)
			b = 60
		}

		key := clientIP + ":" + path
		limiter := rateLimiter.GetLimiter(key, r, b)

		if !limiter.Allow() {
			c.Header("X-Rate-Limit-Remaining", "0")
			c.Header("X-Rate-Limit-Reset", "60")
			
			c.JSON(http.StatusTooManyRequests, models.ErrorResponse{
				Success: false,
				Error:   "Rate limit exceeded for this endpoint",
				Code:    "ERR_RATE_LIMIT_ENDPOINT",
				Details: "Too many requests to this endpoint. Please try again later.",
			})
			c.Abort()
			return
		}

		c.Header("X-Rate-Limit-Remaining", "1")
		c.Next()
	}
}

// Security headers middleware
func SecurityHeadersMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		// Security headers
		c.Header("X-Content-Type-Options", "nosniff")
		c.Header("X-Frame-Options", "DENY")
		c.Header("X-XSS-Protection", "1; mode=block")
		c.Header("Strict-Transport-Security", "max-age=31536000; includeSubDomains")
		c.Header("Referrer-Policy", "strict-origin-when-cross-origin")
		c.Header("Content-Security-Policy", "default-src 'self'")
		
		// Remove server information
		c.Header("Server", "")

		c.Next()
	}
}

// Request ID middleware for tracing
func RequestIDMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		requestID := c.GetHeader("X-Request-ID")
		if requestID == "" {
			requestID = generateRequestID()
		}
		c.Header("X-Request-ID", requestID)
		c.Set("request_id", requestID)
		c.Next()
	}
}

func generateRequestID() string {
	// Simple request ID generation
	return time.Now().Format("20060102150405") + "-" + randomString(8)
}

func randomString(length int) string {
	const charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	b := make([]byte, length)
	for i := range b {
		b[i] = charset[time.Now().UnixNano()%int64(len(charset))]
	}
	return string(b)
}
