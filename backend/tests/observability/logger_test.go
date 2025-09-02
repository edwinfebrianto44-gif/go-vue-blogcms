package observability

import (
	"backend/pkg/logger"
	"context"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"go.uber.org/zap"
)

func TestLoggerInitialization(t *testing.T) {
	// Test production logger initialization
	err := logger.InitLogger("production")
	assert.NoError(t, err)
	assert.NotNil(t, logger.GetLogger())

	// Test development logger initialization
	err = logger.InitLogger("development")
	assert.NoError(t, err)
	assert.NotNil(t, logger.GetLogger())
}

func TestRequestIDLogging(t *testing.T) {
	// Initialize logger
	err := logger.InitLogger("test")
	assert.NoError(t, err)

	// Create context with request ID
	ctx := context.WithValue(context.Background(), logger.RequestIDKey, "test-request-123")

	// Test logging with request ID
	logger.LogInfo(ctx, "Test message", zap.String("test_field", "test_value"))

	// Test logging without request ID
	logger.LogInfo(context.Background(), "Test message without request ID")

	// No error should occur
	assert.True(t, true)
}

func TestHTTPRequestLogging(t *testing.T) {
	// Initialize logger
	err := logger.InitLogger("test")
	assert.NoError(t, err)

	// Create context with request ID
	ctx := context.WithValue(context.Background(), logger.RequestIDKey, "test-request-456")

	// Test HTTP request logging
	logger.LogHTTPRequest(
		ctx,
		"GET",
		"/api/v1/posts",
		200,
		time.Millisecond*150,
		"192.168.1.1",
		"Mozilla/5.0",
	)

	// Test with different status codes
	logger.LogHTTPRequest(ctx, "POST", "/api/v1/auth/login", 401, time.Millisecond*50, "192.168.1.1", "curl/7.68.0")
	logger.LogHTTPRequest(ctx, "GET", "/api/v1/posts/999", 404, time.Millisecond*25, "192.168.1.1", "PostmanRuntime/7.28.0")
	logger.LogHTTPRequest(ctx, "POST", "/api/v1/posts", 500, time.Millisecond*1000, "192.168.1.1", "Mozilla/5.0")

	// No error should occur
	assert.True(t, true)
}

func TestLoggerLevels(t *testing.T) {
	// Initialize logger
	err := logger.InitLogger("test")
	assert.NoError(t, err)

	ctx := context.Background()

	// Test different log levels
	logger.LogDebug(ctx, "Debug message", zap.String("level", "debug"))
	logger.LogInfo(ctx, "Info message", zap.String("level", "info"))
	logger.LogWarn(ctx, "Warning message", zap.String("level", "warn"))
	logger.LogError(ctx, "Error message", assert.AnError, zap.String("level", "error"))

	// No error should occur
	assert.True(t, true)
}

func TestLoggerWithoutInitialization(t *testing.T) {
	// Reset logger
	logger.Logger = nil

	// Should not panic when getting logger without initialization
	assert.NotNil(t, logger.GetLogger())

	// Should work with fallback logger
	logger.LogInfo(context.Background(), "Test message with fallback logger")

	assert.True(t, true)
}
