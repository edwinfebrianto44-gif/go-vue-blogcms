package handlers

import (
	"backend/pkg/metrics"

	"github.com/gin-gonic/gin"
)

// MetricsHandler handles Prometheus metrics endpoint
type MetricsHandler struct{}

// NewMetricsHandler creates a new metrics handler
func NewMetricsHandler() *MetricsHandler {
	return &MetricsHandler{}
}

// Metrics handles Prometheus metrics endpoint
// @Summary Prometheus Metrics
// @Description Get Prometheus metrics for monitoring
// @Tags metrics
// @Produce text/plain
// @Success 200 {string} string "Prometheus metrics"
// @Router /metrics [get]
func (h *MetricsHandler) Metrics(c *gin.Context) {
	metrics.Handler()(c)
}
