package metrics

import (
	"context"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
	"github.com/prometheus/client_golang/prometheus/promhttp"
)

var (
	// HTTP metrics
	httpRequestsTotal = promauto.NewCounterVec(
		prometheus.CounterOpts{
			Name: "blogcms_http_requests_total",
			Help: "Total number of HTTP requests",
		},
		[]string{"method", "path", "status_code"},
	)

	httpRequestDuration = promauto.NewHistogramVec(
		prometheus.HistogramOpts{
			Name:    "blogcms_http_request_duration_seconds",
			Help:    "HTTP request duration in seconds",
			Buckets: []float64{0.001, 0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10},
		},
		[]string{"method", "path", "status_code"},
	)

	httpRequestsInFlight = promauto.NewGauge(
		prometheus.GaugeOpts{
			Name: "blogcms_http_requests_in_flight",
			Help: "Number of HTTP requests currently being processed",
		},
	)

	// Database metrics
	dbConnectionsActive = promauto.NewGauge(
		prometheus.GaugeOpts{
			Name: "blogcms_db_connections_active",
			Help: "Number of active database connections",
		},
	)

	dbConnectionsIdle = promauto.NewGauge(
		prometheus.GaugeOpts{
			Name: "blogcms_db_connections_idle",
			Help: "Number of idle database connections",
		},
	)

	dbQueriesTotal = promauto.NewCounterVec(
		prometheus.CounterOpts{
			Name: "blogcms_db_queries_total",
			Help: "Total number of database queries",
		},
		[]string{"operation", "table"},
	)

	dbQueryDuration = promauto.NewHistogramVec(
		prometheus.HistogramOpts{
			Name:    "blogcms_db_query_duration_seconds",
			Help:    "Database query duration in seconds",
			Buckets: []float64{0.001, 0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5},
		},
		[]string{"operation", "table"},
	)

	// Application metrics
	activeUsers = promauto.NewGauge(
		prometheus.GaugeOpts{
			Name: "blogcms_active_users",
			Help: "Number of active users",
		},
	)

	postsTotal = promauto.NewGauge(
		prometheus.GaugeOpts{
			Name: "blogcms_posts_total",
			Help: "Total number of posts",
		},
	)

	commentsTotal = promauto.NewGauge(
		prometheus.GaugeOpts{
			Name: "blogcms_comments_total",
			Help: "Total number of comments",
		},
	)

	// Authentication metrics
	authAttemptsTotal = promauto.NewCounterVec(
		prometheus.CounterOpts{
			Name: "blogcms_auth_attempts_total",
			Help: "Total number of authentication attempts",
		},
		[]string{"type", "status"},
	)

	activeSessionsTotal = promauto.NewGauge(
		prometheus.GaugeOpts{
			Name: "blogcms_active_sessions_total",
			Help: "Number of active user sessions",
		},
	)

	// System metrics
	systemInfo = promauto.NewGaugeVec(
		prometheus.GaugeOpts{
			Name: "blogcms_system_info",
			Help: "System information",
		},
		[]string{"version", "go_version", "environment"},
	)
)

// RecordHTTPRequest records HTTP request metrics
func RecordHTTPRequest(method, path string, statusCode int, duration time.Duration) {
	labels := prometheus.Labels{
		"method":      method,
		"path":        sanitizePath(path),
		"status_code": strconv.Itoa(statusCode),
	}

	httpRequestsTotal.With(labels).Inc()
	httpRequestDuration.With(labels).Observe(duration.Seconds())
}

// IncRequestsInFlight increments the in-flight requests counter
func IncRequestsInFlight() {
	httpRequestsInFlight.Inc()
}

// DecRequestsInFlight decrements the in-flight requests counter
func DecRequestsInFlight() {
	httpRequestsInFlight.Dec()
}

// RecordDBQuery records database query metrics
func RecordDBQuery(operation, table string, duration time.Duration) {
	labels := prometheus.Labels{
		"operation": operation,
		"table":     table,
	}

	dbQueriesTotal.With(labels).Inc()
	dbQueryDuration.With(labels).Observe(duration.Seconds())
}

// UpdateDBConnections updates database connection metrics
func UpdateDBConnections(active, idle int) {
	dbConnectionsActive.Set(float64(active))
	dbConnectionsIdle.Set(float64(idle))
}

// RecordAuthAttempt records authentication attempt
func RecordAuthAttempt(authType, status string) {
	authAttemptsTotal.With(prometheus.Labels{
		"type":   authType,
		"status": status,
	}).Inc()
}

// UpdateActiveUsers updates active users count
func UpdateActiveUsers(count int) {
	activeUsers.Set(float64(count))
}

// UpdateActiveSessions updates active sessions count
func UpdateActiveSessions(count int) {
	activeSessionsTotal.Set(float64(count))
}

// UpdatePostsTotal updates total posts count
func UpdatePostsTotal(count int) {
	postsTotal.Set(float64(count))
}

// UpdateCommentsTotal updates total comments count
func UpdateCommentsTotal(count int) {
	commentsTotal.Set(float64(count))
}

// SetSystemInfo sets system information metrics
func SetSystemInfo(version, goVersion, environment string) {
	systemInfo.With(prometheus.Labels{
		"version":     version,
		"go_version":  goVersion,
		"environment": environment,
	}).Set(1)
}

// PrometheusMiddleware returns Gin middleware for Prometheus metrics
func PrometheusMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		// Skip metrics endpoint itself
		if c.Request.URL.Path == "/metrics" {
			c.Next()
			return
		}

		start := time.Now()
		IncRequestsInFlight()
		defer DecRequestsInFlight()

		c.Next()

		duration := time.Since(start)
		RecordHTTPRequest(
			c.Request.Method,
			c.FullPath(),
			c.Writer.Status(),
			duration,
		)
	}
}

// Handler returns Prometheus metrics HTTP handler
func Handler() gin.HandlerFunc {
	h := promhttp.Handler()
	return gin.WrapH(h)
}

// sanitizePath removes dynamic parameters from URL path for metrics
func sanitizePath(path string) string {
	// Replace common parameter patterns
	// This is a simple implementation - you might want to make it more sophisticated
	if path == "" {
		return "unknown"
	}

	// Common patterns to normalize
	patterns := map[string]string{
		"/api/v1/posts/":      "/api/v1/posts/:id",
		"/api/v1/users/":      "/api/v1/users/:id",
		"/api/v1/comments/":   "/api/v1/comments/:id",
		"/api/v1/categories/": "/api/v1/categories/:id",
	}

	for pattern, replacement := range patterns {
		if len(path) > len(pattern) && path[:len(pattern)] == pattern {
			return replacement
		}
	}

	return path
}

// GetMetricsContext creates a context for metrics collection
func GetMetricsContext(ctx context.Context) context.Context {
	// Add any metrics-specific context here
	return ctx
}
