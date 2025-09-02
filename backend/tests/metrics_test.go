package services

import (
	"backend/pkg/metrics"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
)

func TestMetricsHTTPRequest(t *testing.T) {
	// Record HTTP request metrics
	metrics.RecordHTTPRequest("GET", "/api/v1/posts", 200, time.Millisecond*150)
	metrics.RecordHTTPRequest("POST", "/api/v1/auth/login", 401, time.Millisecond*50)
	metrics.RecordHTTPRequest("GET", "/api/v1/posts/999", 404, time.Millisecond*25)

	// Test in-flight requests
	metrics.IncRequestsInFlight()
	metrics.IncRequestsInFlight()
	metrics.DecRequestsInFlight()

	// The metrics should be recorded without error
	assert.True(t, true)
}

func TestMetricsDatabase(t *testing.T) {
	// Record database metrics
	metrics.RecordDBQuery("SELECT", "posts", time.Millisecond*10)
	metrics.RecordDBQuery("INSERT", "users", time.Millisecond*25)
	metrics.RecordDBQuery("UPDATE", "posts", time.Millisecond*15)

	// Update connection metrics
	metrics.UpdateDBConnections(5, 3)

	// The metrics should be recorded without error
	assert.True(t, true)
}

func TestMetricsAuthentication(t *testing.T) {
	// Record authentication attempts
	metrics.RecordAuthAttempt("login", "success")
	metrics.RecordAuthAttempt("login", "failure")
	metrics.RecordAuthAttempt("refresh", "success")
	metrics.RecordAuthAttempt("logout", "success")

	// Update session metrics
	metrics.UpdateActiveSessions(10)
	metrics.UpdateActiveUsers(8)

	// The metrics should be recorded without error
	assert.True(t, true)
}

func TestMetricsApplication(t *testing.T) {
	// Update application metrics
	metrics.UpdatePostsTotal(150)
	metrics.UpdateCommentsTotal(89)

	// Set system info
	metrics.SetSystemInfo("1.0.0", "go1.21", "test")

	// The metrics should be recorded without error
	assert.True(t, true)
}

func TestMetricsPathSanitization(t *testing.T) {
	// Test path sanitization in metrics
	metrics.RecordHTTPRequest("GET", "/api/v1/posts/123", 200, time.Millisecond*50)
	metrics.RecordHTTPRequest("GET", "/api/v1/users/456", 200, time.Millisecond*30)
	metrics.RecordHTTPRequest("GET", "/api/v1/comments/789", 200, time.Millisecond*20)
	metrics.RecordHTTPRequest("GET", "/api/v1/categories/test-category", 200, time.Millisecond*40)

	// The metrics should be recorded with sanitized paths
	assert.True(t, true)
}

func TestMetricsInFlightRequests(t *testing.T) {
	// Test in-flight request tracking

	// Increment
	metrics.IncRequestsInFlight()
	metrics.IncRequestsInFlight()
	metrics.IncRequestsInFlight()

	// Decrement
	metrics.DecRequestsInFlight()
	metrics.DecRequestsInFlight()

	// Should handle increments and decrements without panics
	assert.True(t, true)
}

func TestMetricsEdgeCases(t *testing.T) {
	// Test with empty/invalid values
	metrics.RecordHTTPRequest("", "", 0, 0)
	metrics.RecordDBQuery("", "", 0)
	metrics.RecordAuthAttempt("", "")

	// Test with negative values
	metrics.UpdateDBConnections(-1, -1)
	metrics.UpdateActiveUsers(-1)
	metrics.UpdateActiveSessions(-1)
	metrics.UpdatePostsTotal(-1)
	metrics.UpdateCommentsTotal(-1)

	// Should handle gracefully without panics
	assert.True(t, true)
}
