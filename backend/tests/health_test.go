package services

import (
	"backend/pkg/health"
	"context"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

func TestHealthChecker(t *testing.T) {
	// Create health checker
	checker := health.NewHealthChecker()
	assert.NotNil(t, checker)

	// Test without any checkers
	response := checker.CheckHealth(context.Background())
	assert.Equal(t, health.StatusHealthy, response.Status)
	assert.Equal(t, "blogcms-api", response.Service)
	assert.NotZero(t, response.Timestamp)
	assert.Greater(t, response.Uptime, time.Duration(0))
}

func TestDatabaseChecker(t *testing.T) {
	// Create in-memory SQLite database for testing
	db, err := gorm.Open(sqlite.Open(":memory:"), &gorm.Config{})
	assert.NoError(t, err)

	// Create database checker
	dbChecker := health.NewDatabaseChecker(db)
	assert.NotNil(t, dbChecker)
	assert.Equal(t, "database", dbChecker.Name())

	// Test database health check
	result := dbChecker.Check(context.Background())
	assert.Equal(t, health.StatusHealthy, result.Status)
	assert.NotZero(t, result.Timestamp)
	assert.Greater(t, result.Duration, time.Duration(0))
	assert.NotNil(t, result.Details)

	// Check details contain expected fields
	details := result.Details
	assert.Contains(t, details, "open_connections")
	assert.Contains(t, details, "in_use")
	assert.Contains(t, details, "idle")
}

func TestMemoryChecker(t *testing.T) {
	// Create memory checker with 100MB limit
	memChecker := health.NewMemoryChecker(100)
	assert.NotNil(t, memChecker)
	assert.Equal(t, "memory", memChecker.Name())

	// Test memory health check
	result := memChecker.Check(context.Background())
	assert.NotEmpty(t, result.Status)
	assert.NotZero(t, result.Timestamp)
	assert.Greater(t, result.Duration, time.Duration(0))
	assert.NotNil(t, result.Details)

	// Check details contain expected fields
	details := result.Details
	assert.Contains(t, details, "alloc_mb")
	assert.Contains(t, details, "sys_mb")
	assert.Contains(t, details, "num_gc")
}

func TestHealthCheckerWithMultipleCheckers(t *testing.T) {
	// Create health checker
	checker := health.NewHealthChecker()

	// Create and add database checker
	db, err := gorm.Open(sqlite.Open(":memory:"), &gorm.Config{})
	assert.NoError(t, err)
	dbChecker := health.NewDatabaseChecker(db)
	checker.AddChecker("database", dbChecker)

	// Create and add memory checker
	memChecker := health.NewMemoryChecker(1000) // 1GB limit
	checker.AddChecker("memory", memChecker)

	// Test health check with multiple checkers
	response := checker.CheckHealth(context.Background())
	assert.Equal(t, health.StatusHealthy, response.Status)
	assert.Len(t, response.Checks, 2)
	assert.Contains(t, response.Checks, "database")
	assert.Contains(t, response.Checks, "memory")

	// Test removing checker
	checker.RemoveChecker("memory")
	response = checker.CheckHealth(context.Background())
	assert.Len(t, response.Checks, 1)
	assert.Contains(t, response.Checks, "database")
	assert.NotContains(t, response.Checks, "memory")
}

func TestHealthCheckerWithUnhealthyChecker(t *testing.T) {
	// Create health checker
	checker := health.NewHealthChecker()

	// Add a mock unhealthy checker
	checker.AddChecker("mock_unhealthy", &MockUnhealthyChecker{})

	// Test health check with unhealthy checker
	response := checker.CheckHealth(context.Background())
	assert.Equal(t, health.StatusUnhealthy, response.Status)
	assert.Len(t, response.Checks, 1)
	assert.Equal(t, health.StatusUnhealthy, response.Checks["mock_unhealthy"].Status)
}

func TestHealthCheckerWithDegradedChecker(t *testing.T) {
	// Create health checker
	checker := health.NewHealthChecker()

	// Add a mock degraded checker
	checker.AddChecker("mock_degraded", &MockDegradedChecker{})

	// Test health check with degraded checker
	response := checker.CheckHealth(context.Background())
	assert.Equal(t, health.StatusDegraded, response.Status)
	assert.Len(t, response.Checks, 1)
	assert.Equal(t, health.StatusDegraded, response.Checks["mock_degraded"].Status)
}

// Mock checkers for testing

type MockUnhealthyChecker struct{}

func (m *MockUnhealthyChecker) Check(ctx context.Context) health.CheckResult {
	return health.CheckResult{
		Status:    health.StatusUnhealthy,
		Timestamp: time.Now(),
		Duration:  time.Millisecond * 10,
		Error:     "Mock unhealthy error",
	}
}

func (m *MockUnhealthyChecker) Name() string {
	return "mock_unhealthy"
}

type MockDegradedChecker struct{}

func (m *MockDegradedChecker) Check(ctx context.Context) health.CheckResult {
	return health.CheckResult{
		Status:    health.StatusDegraded,
		Timestamp: time.Now(),
		Duration:  time.Millisecond * 5,
		Details:   map[string]interface{}{"warning": "performance degraded"},
	}
}

func (m *MockDegradedChecker) Name() string {
	return "mock_degraded"
}
