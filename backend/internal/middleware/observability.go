package middleware

import (
	"context"
	"time"

	"backend/pkg/logger"
	"backend/pkg/metrics"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"go.uber.org/zap"
)

// CorrelationIDMiddleware adds correlation ID to each request
func CorrelationIDMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		// Check if X-Request-ID header is provided
		requestID := c.GetHeader("X-Request-ID")

		// Generate new ID if not provided
		if requestID == "" {
			requestID = uuid.New().String()
		}

		// Set in response header
		c.Header("X-Request-ID", requestID)

		// Add to Gin context
		c.Set("request_id", requestID)

		// Add to request context for logging
		ctx := context.WithValue(c.Request.Context(), logger.RequestIDKey, requestID)
		c.Request = c.Request.WithContext(ctx)

		c.Next()
	}
}

// LoggingMiddleware logs HTTP requests with structured logging
func LoggingMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		start := time.Now()
		path := c.Request.URL.Path
		method := c.Request.Method
		clientIP := c.ClientIP()
		userAgent := c.Request.UserAgent()

		// Process request
		c.Next()

		// Calculate duration
		duration := time.Since(start)
		statusCode := c.Writer.Status()

		// Get request ID from context
		ctx := c.Request.Context()

		// Log the request
		logger.LogHTTPRequest(
			ctx,
			method,
			path,
			statusCode,
			duration,
			clientIP,
			userAgent,
		)

		// Log errors if any
		if len(c.Errors) > 0 {
			for _, ginErr := range c.Errors {
				logger.LogError(ctx, "Request error occurred", ginErr.Err,
					zap.String("method", method),
					zap.String("path", path),
					zap.Int("status_code", statusCode),
				)
			}
		}
	}
}

// MetricsMiddleware collects Prometheus metrics
func MetricsMiddleware() gin.HandlerFunc {
	return metrics.PrometheusMiddleware()
}
