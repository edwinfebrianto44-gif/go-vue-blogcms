package health

import (
	"context"
	"fmt"
	"net/http"
	"runtime"
	"sync"
	"time"

	"backend/pkg/logger"
	"backend/pkg/metrics"

	"github.com/gin-gonic/gin"
	"go.uber.org/zap"
	"gorm.io/gorm"
)

// Status represents health check status
type Status string

const (
	StatusHealthy   Status = "healthy"
	StatusUnhealthy Status = "unhealthy"
	StatusDegraded  Status = "degraded"
)

// CheckResult represents the result of a health check
type CheckResult struct {
	Status    Status                 `json:"status"`
	Timestamp time.Time              `json:"timestamp"`
	Duration  time.Duration          `json:"duration_ms"`
	Details   map[string]interface{} `json:"details,omitempty"`
	Error     string                 `json:"error,omitempty"`
}

// HealthResponse represents the overall health response
type HealthResponse struct {
	Status    Status                 `json:"status"`
	Timestamp time.Time              `json:"timestamp"`
	Service   string                 `json:"service"`
	Version   string                 `json:"version"`
	Uptime    time.Duration          `json:"uptime_seconds"`
	Checks    map[string]CheckResult `json:"checks"`
	System    map[string]interface{} `json:"system"`
}

// Checker interface for health checks
type Checker interface {
	Check(ctx context.Context) CheckResult
	Name() string
}

// HealthChecker manages health checks
type HealthChecker struct {
	checkers  map[string]Checker
	mu        sync.RWMutex
	startTime time.Time
}

// NewHealthChecker creates a new health checker
func NewHealthChecker() *HealthChecker {
	return &HealthChecker{
		checkers:  make(map[string]Checker),
		startTime: time.Now(),
	}
}

// AddChecker adds a health checker
func (h *HealthChecker) AddChecker(name string, checker Checker) {
	h.mu.Lock()
	defer h.mu.Unlock()
	h.checkers[name] = checker
}

// RemoveChecker removes a health checker
func (h *HealthChecker) RemoveChecker(name string) {
	h.mu.Lock()
	defer h.mu.Unlock()
	delete(h.checkers, name)
}

// CheckHealth performs all health checks
func (h *HealthChecker) CheckHealth(ctx context.Context) HealthResponse {
	h.mu.RLock()
	checkers := make(map[string]Checker, len(h.checkers))
	for name, checker := range h.checkers {
		checkers[name] = checker
	}
	h.mu.RUnlock()

	checks := make(map[string]CheckResult)
	overallStatus := StatusHealthy

	// Run all checks
	for name, checker := range checkers {
		result := checker.Check(ctx)
		checks[name] = result

		// Update overall status
		if result.Status == StatusUnhealthy {
			overallStatus = StatusUnhealthy
		} else if result.Status == StatusDegraded && overallStatus == StatusHealthy {
			overallStatus = StatusDegraded
		}
	}

	return HealthResponse{
		Status:    overallStatus,
		Timestamp: time.Now(),
		Service:   "blogcms-api",
		Version:   "1.0.0",
		Uptime:    time.Since(h.startTime),
		Checks:    checks,
		System:    getSystemInfo(),
	}
}

// LivenessHandler handles liveness probe (Kubernetes)
func (h *HealthChecker) LivenessHandler(c *gin.Context) {
	ctx := c.Request.Context()

	// Simple liveness check - just verify the service is running
	response := HealthResponse{
		Status:    StatusHealthy,
		Timestamp: time.Now(),
		Service:   "blogcms-api",
		Version:   "1.0.0",
		Uptime:    time.Since(h.startTime),
		System:    getSystemInfo(),
	}

	logger.LogInfo(ctx, "Liveness check performed",
		zap.String("status", string(response.Status)),
		zap.Duration("uptime", response.Uptime),
	)

	c.JSON(http.StatusOK, response)
}

// ReadinessHandler handles readiness probe (Kubernetes)
func (h *HealthChecker) ReadinessHandler(c *gin.Context) {
	ctx := c.Request.Context()

	// Full readiness check - verify all dependencies
	health := h.CheckHealth(ctx)

	// Log readiness check
	logger.LogInfo(ctx, "Readiness check performed",
		zap.String("status", string(health.Status)),
		zap.Int("checks_count", len(health.Checks)),
	)

	// Return 503 if unhealthy for load balancer
	if health.Status == StatusUnhealthy {
		c.JSON(http.StatusServiceUnavailable, health)
		return
	}

	c.JSON(http.StatusOK, health)
}

// HealthHandler handles general health endpoint
func (h *HealthChecker) HealthHandler(c *gin.Context) {
	ctx := c.Request.Context()

	health := h.CheckHealth(ctx)

	// Update metrics
	if health.Status == StatusHealthy {
		metrics.RecordAuthAttempt("health_check", "success")
	} else {
		metrics.RecordAuthAttempt("health_check", "failure")
	}

	// Always return 200 for general health endpoint
	c.JSON(http.StatusOK, health)
}

// getSystemInfo returns system information
func getSystemInfo() map[string]interface{} {
	var m runtime.MemStats
	runtime.ReadMemStats(&m)

	return map[string]interface{}{
		"go_version":     runtime.Version(),
		"num_goroutines": runtime.NumGoroutine(),
		"num_cpu":        runtime.NumCPU(),
		"memory_alloc":   bToMb(m.Alloc),
		"memory_total":   bToMb(m.TotalAlloc),
		"memory_sys":     bToMb(m.Sys),
		"gc_runs":        m.NumGC,
	}
}

// bToMb converts bytes to megabytes
func bToMb(b uint64) uint64 {
	return b / 1024 / 1024
}

// DatabaseChecker checks database connectivity
type DatabaseChecker struct {
	db *gorm.DB
}

// NewDatabaseChecker creates a new database checker
func NewDatabaseChecker(db *gorm.DB) *DatabaseChecker {
	return &DatabaseChecker{db: db}
}

// Check performs database health check
func (d *DatabaseChecker) Check(ctx context.Context) CheckResult {
	start := time.Now()

	// Get underlying sql.DB
	sqlDB, err := d.db.DB()
	if err != nil {
		return CheckResult{
			Status:    StatusUnhealthy,
			Timestamp: time.Now(),
			Duration:  time.Since(start),
			Error:     fmt.Sprintf("failed to get sql.DB: %v", err),
		}
	}

	// Ping database
	err = sqlDB.PingContext(ctx)
	if err != nil {
		return CheckResult{
			Status:    StatusUnhealthy,
			Timestamp: time.Now(),
			Duration:  time.Since(start),
			Error:     fmt.Sprintf("database ping failed: %v", err),
		}
	}

	// Get connection stats
	stats := sqlDB.Stats()
	details := map[string]interface{}{
		"open_connections":    stats.OpenConnections,
		"in_use":              stats.InUse,
		"idle":                stats.Idle,
		"wait_count":          stats.WaitCount,
		"wait_duration":       stats.WaitDuration.String(),
		"max_idle_closed":     stats.MaxIdleClosed,
		"max_lifetime_closed": stats.MaxLifetimeClosed,
	}

	// Update metrics
	metrics.UpdateDBConnections(stats.InUse, stats.Idle)

	// Determine status based on connection health
	status := StatusHealthy
	if stats.OpenConnections == 0 {
		status = StatusUnhealthy
	} else if float64(stats.InUse)/float64(stats.OpenConnections) > 0.8 {
		status = StatusDegraded
	}

	return CheckResult{
		Status:    status,
		Timestamp: time.Now(),
		Duration:  time.Since(start),
		Details:   details,
	}
}

// Name returns the checker name
func (d *DatabaseChecker) Name() string {
	return "database"
}

// MemoryChecker checks memory usage
type MemoryChecker struct {
	maxMemoryMB uint64
}

// NewMemoryChecker creates a new memory checker
func NewMemoryChecker(maxMemoryMB uint64) *MemoryChecker {
	return &MemoryChecker{maxMemoryMB: maxMemoryMB}
}

// Check performs memory health check
func (m *MemoryChecker) Check(ctx context.Context) CheckResult {
	start := time.Now()

	var memStats runtime.MemStats
	runtime.ReadMemStats(&memStats)

	allocMB := bToMb(memStats.Alloc)
	sysMB := bToMb(memStats.Sys)

	details := map[string]interface{}{
		"alloc_mb":        allocMB,
		"sys_mb":          sysMB,
		"num_gc":          memStats.NumGC,
		"gc_cpu_fraction": memStats.GCCPUFraction,
	}

	status := StatusHealthy
	if m.maxMemoryMB > 0 {
		if allocMB > m.maxMemoryMB {
			status = StatusUnhealthy
		} else if allocMB > m.maxMemoryMB*8/10 { // 80% threshold
			status = StatusDegraded
		}
	}

	return CheckResult{
		Status:    status,
		Timestamp: time.Now(),
		Duration:  time.Since(start),
		Details:   details,
	}
}

// Name returns the checker name
func (m *MemoryChecker) Name() string {
	return "memory"
}
