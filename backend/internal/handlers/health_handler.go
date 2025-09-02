package handlers

import (
	"backend/pkg/health"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

// HealthHandler handles health check endpoints
type HealthHandler struct {
	checker *health.HealthChecker
}

// NewHealthHandler creates a new health handler
func NewHealthHandler(db *gorm.DB) *HealthHandler {
	checker := health.NewHealthChecker()

	// Add database health checker
	checker.AddChecker("database", health.NewDatabaseChecker(db))

	// Add memory health checker (500MB limit)
	checker.AddChecker("memory", health.NewMemoryChecker(500))

	return &HealthHandler{
		checker: checker,
	}
}

// HealthCheck handles general health check
// @Summary Health Check
// @Description Check the health status of the API and its dependencies
// @Tags health
// @Produce json
// @Success 200 {object} health.HealthResponse
// @Router /health [get]
func (h *HealthHandler) HealthCheck(c *gin.Context) {
	h.checker.HealthHandler(c)
}

// LivenessCheck handles Kubernetes liveness probe
// @Summary Liveness Check
// @Description Check if the application is alive (Kubernetes liveness probe)
// @Tags health
// @Produce json
// @Success 200 {object} health.HealthResponse
// @Router /healthz [get]
func (h *HealthHandler) LivenessCheck(c *gin.Context) {
	h.checker.LivenessHandler(c)
}

// ReadinessCheck handles Kubernetes readiness probe
// @Summary Readiness Check
// @Description Check if the application is ready to serve traffic (Kubernetes readiness probe)
// @Tags health
// @Produce json
// @Success 200 {object} health.HealthResponse
// @Success 503 {object} health.HealthResponse
// @Router /readyz [get]
func (h *HealthHandler) ReadinessCheck(c *gin.Context) {
	h.checker.ReadinessHandler(c)
}
