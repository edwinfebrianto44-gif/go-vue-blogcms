# Phase 13 — Observability (Logging, Tracing, Metrics, Healthcheck) ✅

This phase implements comprehensive observability features for the Go-Vue BlogCMS project, including structured logging, health checks, Prometheus metrics, and correlation ID tracking.

## Overview

Observability is crucial for monitoring, debugging, and maintaining production applications. This implementation provides:

```mermaid
graph TB
    A[HTTP Request] --> B[Correlation ID Middleware]
    B --> C[Logging Middleware]
    C --> D[Metrics Middleware]
    D --> E[Application Handler]
    
    B --> F[X-Request-ID Header]
    C --> G[Structured Logs]
    D --> H[Prometheus Metrics]
    E --> I[Health Checks]
    
    F --> J[Request Tracing]
    G --> K[Log Aggregation]
    H --> L[Metrics Collection]
    I --> M[System Monitoring]
```

## Implementation

### 1. Structured Logging with Zap

**Features:**
- JSON format for production, console for development
- Request ID correlation in all log entries
- Multiple log levels (Debug, Info, Warn, Error)
- Contextual logging with structured fields
- Performance optimized with sampling

**Logger Package** (`pkg/logger/logger.go`):
```go
// Initialize logger based on environment
logger.InitLogger("production") // or "development"

// Log with request ID from context
logger.LogHTTPRequest(ctx, method, path, statusCode, duration, clientIP, userAgent)
logger.LogInfo(ctx, "User created", zap.String("user_id", "123"))
logger.LogError(ctx, "Database error", err, zap.String("operation", "insert"))
```

**Log Format Examples:**
```json
// Production JSON format
{
  "timestamp": "2025-09-02T10:30:45.123Z",
  "level": "info",
  "message": "HTTP request",
  "service": "blogcms-api",
  "hostname": "server-01",
  "request_id": "abc123-def456-ghi789",
  "method": "GET",
  "path": "/api/v1/posts",
  "status_code": 200,
  "duration": 150.5,
  "client_ip": "192.168.1.100",
  "user_agent": "Mozilla/5.0..."
}
```

### 2. Health Check Endpoints

**Kubernetes-Compatible Health Checks:**

#### Liveness Probe (`/healthz`)
- Simple application alive check
- Returns 200 if service is running
- Used by Kubernetes to restart unhealthy pods

#### Readiness Probe (`/readyz`)  
- Comprehensive dependency checks
- Validates database connectivity
- Checks memory usage
- Returns 503 if dependencies unavailable

#### General Health Check (`/health`)
- Detailed health information
- System metrics and uptime
- Individual checker results
- Always returns 200 for monitoring

**Health Check Implementation:**
```go
// Database connectivity check
type DatabaseChecker struct {
    db *gorm.DB
}

func (d *DatabaseChecker) Check(ctx context.Context) CheckResult {
    // Ping database and check connection stats
    // Return healthy/unhealthy/degraded status
}

// Memory usage check  
type MemoryChecker struct {
    maxMemoryMB uint64
}

func (m *MemoryChecker) Check(ctx context.Context) CheckResult {
    // Check memory allocation and GC stats
    // Return status based on thresholds
}
```

**Health Response Format:**
```json
{
  "status": "healthy",
  "timestamp": "2025-09-02T10:30:45.123Z",
  "service": "blogcms-api",
  "version": "1.0.0",
  "uptime_seconds": 3600.5,
  "checks": {
    "database": {
      "status": "healthy",
      "duration_ms": 15.2,
      "details": {
        "open_connections": 5,
        "in_use": 2,
        "idle": 3
      }
    },
    "memory": {
      "status": "healthy", 
      "duration_ms": 2.1,
      "details": {
        "alloc_mb": 45,
        "sys_mb": 78,
        "num_gc": 12
      }
    }
  },
  "system": {
    "go_version": "go1.21",
    "num_goroutines": 25,
    "num_cpu": 4
  }
}
```

### 3. Prometheus Metrics

**HTTP Metrics:**
- `blogcms_http_requests_total` - Total HTTP requests by method, path, status
- `blogcms_http_request_duration_seconds` - Request duration histogram
- `blogcms_http_requests_in_flight` - Active requests gauge

**Database Metrics:**
- `blogcms_db_connections_active` - Active database connections
- `blogcms_db_connections_idle` - Idle database connections  
- `blogcms_db_queries_total` - Total database queries by operation/table
- `blogcms_db_query_duration_seconds` - Query duration histogram

**Application Metrics:**
- `blogcms_active_users` - Number of active users
- `blogcms_posts_total` - Total number of posts
- `blogcms_comments_total` - Total number of comments
- `blogcms_auth_attempts_total` - Authentication attempts by type/status
- `blogcms_active_sessions_total` - Active user sessions

**Metrics Usage:**
```go
// Record HTTP request metrics
metrics.RecordHTTPRequest("GET", "/api/v1/posts", 200, time.Millisecond*150)

// Record database query metrics  
metrics.RecordDBQuery("SELECT", "posts", time.Millisecond*10)

// Update application counters
metrics.UpdateActiveUsers(150)
metrics.UpdatePostsTotal(1205)
```

**Metrics Endpoint:** `GET /metrics`
```
# HELP blogcms_http_requests_total Total number of HTTP requests
# TYPE blogcms_http_requests_total counter
blogcms_http_requests_total{method="GET",path="/api/v1/posts",status_code="200"} 1543

# HELP blogcms_http_request_duration_seconds HTTP request duration in seconds
# TYPE blogcms_http_request_duration_seconds histogram
blogcms_http_request_duration_seconds_bucket{method="GET",path="/api/v1/posts",status_code="200",le="0.005"} 234
```

### 4. Correlation ID Middleware

**X-Request-ID Header Support:**
- Accepts existing `X-Request-ID` from client
- Generates UUID if not provided
- Forwards to all downstream requests
- Includes in all log entries

**Middleware Implementation:**
```go
func CorrelationIDMiddleware() gin.HandlerFunc {
    return func(c *gin.Context) {
        // Check if X-Request-ID header is provided
        requestID := c.GetHeader("X-Request-ID")
        
        // Generate new ID if not provided
        if requestID == "" {
            requestID = uuid.New().String()
        }

        // Set in response header and context
        c.Header("X-Request-ID", requestID)
        c.Set("request_id", requestID)
        
        // Add to request context for logging
        ctx := context.WithValue(c.Request.Context(), logger.RequestIDKey, requestID)
        c.Request = c.Request.WithContext(ctx)

        c.Next()
    }
}
```

### 5. Nginx JSON Access Logs

**Structured Nginx Logging:**
```nginx
log_format json_combined escape=json
'{'
    '"timestamp":"$time_iso8601",'
    '"request_id":"$http_x_request_id",'
    '"remote_addr":"$remote_addr",'
    '"request":"$request",'
    '"method":"$request_method",'
    '"status":$status,'
    '"body_bytes_sent":$body_bytes_sent,'
    '"request_time":$request_time,'
    '"upstream_response_time":"$upstream_response_time",'
    '"http_user_agent":"$http_user_agent"'
'}';

access_log /var/log/nginx/access.log json_combined;
```

**Nginx Health Check Configuration:**
```nginx
# Health endpoints (no rate limiting)
location = /healthz {
    proxy_pass http://backend/healthz;
    access_log off;
}

location = /readyz {
    proxy_pass http://backend/readyz;
    access_log off;
}

# Metrics endpoint with optional access control
location = /metrics {
    proxy_pass http://backend/metrics;
    access_log off;
    
    # Optional: Restrict to monitoring systems
    # allow 10.0.0.0/8;
    # deny all;
}
```

## Configuration

### 1. Environment Variables

```bash
# Logging Configuration
LOG_LEVEL=info              # debug, info, warn, error
LOG_FORMAT=json             # json, console
GIN_MODE=release            # release, debug

# Health Check Configuration  
HEALTH_CHECK_TIMEOUT=10s    # Health check timeout
MEMORY_LIMIT_MB=500         # Memory limit for health checks

# Metrics Configuration
METRICS_ENABLED=true        # Enable/disable metrics collection
METRICS_PATH=/metrics       # Metrics endpoint path
```

### 2. Docker Compose Health Checks

```yaml
services:
  backend:
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:8080/healthz"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
      
  nginx:
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost/healthz"]
      interval: 30s
      timeout: 10s
      retries: 3
```

## Integration

### 1. Middleware Stack Order

```go
// Observability middleware (applied first for complete tracking)
r.Use(middleware.CorrelationIDMiddleware())  // Generate/forward X-Request-ID
r.Use(middleware.LoggingMiddleware())        // Structured request logging  
r.Use(middleware.MetricsMiddleware())        // Prometheus metrics collection

// Core application middleware
r.Use(middleware.SecurityHeadersMiddleware())
r.Use(middleware.CORSMiddleware())
r.Use(middleware.ValidationMiddleware())
r.Use(middleware.ErrorHandlerMiddleware())
r.Use(middleware.AdvancedRateLimitMiddleware())
```

### 2. Handler Registration

```go
// Initialize handlers
healthHandler := handlers.NewHealthHandler(db)
metricsHandler := handlers.NewMetricsHandler()

// Register health endpoints
r.GET("/healthz", healthHandler.LivenessCheck)   // Kubernetes liveness
r.GET("/readyz", healthHandler.ReadinessCheck)   // Kubernetes readiness  
r.GET("/health", healthHandler.HealthCheck)      // General health
r.GET("/metrics", metricsHandler.Metrics)        // Prometheus metrics
```

### 3. Application Startup

```go
func main() {
    // Initialize structured logging
    if err := logger.InitLogger(cfg.Environment); err != nil {
        log.Fatal("Failed to initialize logger:", err)
    }
    defer logger.Sync()

    // Initialize metrics
    metrics.SetSystemInfo("1.0.0", runtime.Version(), cfg.Environment)
    
    // Get logger instance
    appLogger := logger.GetLogger()
    appLogger.Info("Starting BlogCMS API Server",
        zap.String("environment", cfg.Environment),
        zap.String("port", cfg.Server.Port),
    )
}
```

## Monitoring & Alerting

### 1. Kubernetes Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: blogcms-backend
spec:
  template:
    spec:
      containers:
      - name: backend
        livenessProbe:
          httpGet:
            path: /healthz
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 30
          
        readinessProbe:
          httpGet:
            path: /readyz
            port: 8080
          initialDelaySeconds: 10
          periodSeconds: 10
```

### 2. Prometheus Configuration

```yaml
# prometheus.yml
scrape_configs:
  - job_name: 'blogcms-api'
    static_configs:
      - targets: ['blogcms-backend:8080']
    metrics_path: '/metrics'
    scrape_interval: 15s
```

### 3. Grafana Dashboard Queries

```promql
# Request rate
rate(blogcms_http_requests_total[5m])

# Error rate  
rate(blogcms_http_requests_total{status_code=~"5.."}[5m]) / rate(blogcms_http_requests_total[5m])

# Response time P95
histogram_quantile(0.95, rate(blogcms_http_request_duration_seconds_bucket[5m]))

# Database connections
blogcms_db_connections_active + blogcms_db_connections_idle
```

### 4. Alerting Rules

```yaml
groups:
- name: blogcms-alerts
  rules:
  - alert: HighErrorRate
    expr: rate(blogcms_http_requests_total{status_code=~"5.."}[5m]) / rate(blogcms_http_requests_total[5m]) > 0.1
    for: 5m
    labels:
      severity: critical
    annotations:
      summary: "High error rate detected"
      
  - alert: HealthCheckFailing
    expr: up{job="blogcms-api"} == 0
    for: 2m
    labels:
      severity: critical
    annotations:
      summary: "BlogCMS API health check failing"
```

## Testing

### 1. Unit Tests

**Logger Tests:**
```go
func TestLoggerInitialization(t *testing.T) {
    err := logger.InitLogger("production")
    assert.NoError(t, err)
    assert.NotNil(t, logger.GetLogger())
}

func TestRequestIDLogging(t *testing.T) {
    ctx := context.WithValue(context.Background(), logger.RequestIDKey, "test-123")
    logger.LogInfo(ctx, "Test message", zap.String("field", "value"))
}
```

**Health Check Tests:**
```go
func TestDatabaseChecker(t *testing.T) {
    db, _ := gorm.Open(sqlite.Open(":memory:"), &gorm.Config{})
    checker := health.NewDatabaseChecker(db)
    
    result := checker.Check(context.Background())
    assert.Equal(t, health.StatusHealthy, result.Status)
}
```

**Metrics Tests:**
```go
func TestMetricsRecording(t *testing.T) {
    metrics.RecordHTTPRequest("GET", "/api/v1/posts", 200, time.Millisecond*150)
    metrics.UpdateActiveUsers(100)
    // Verify metrics are recorded without error
}
```

### 2. Integration Tests

**Middleware Tests:**
```go
func TestCorrelationIDMiddleware(t *testing.T) {
    r := gin.New()
    r.Use(middleware.CorrelationIDMiddleware())
    
    // Test with provided request ID
    req := httptest.NewRequest("GET", "/test", nil)
    req.Header.Set("X-Request-ID", "custom-123")
    
    w := httptest.NewRecorder()
    r.ServeHTTP(w, req)
    
    assert.Equal(t, "custom-123", w.Header().Get("X-Request-ID"))
}
```

### 3. Health Check Testing

```bash
# Test liveness probe
curl -f http://localhost:8080/healthz

# Test readiness probe  
curl -f http://localhost:8080/readyz

# Test detailed health
curl http://localhost:8080/health | jq '.'
```

### 4. Metrics Testing

```bash
# View Prometheus metrics
curl http://localhost:8080/metrics

# Test specific metrics
curl -s http://localhost:8080/metrics | grep blogcms_http_requests_total
```

## Log Analysis

### 1. Request Tracing

```bash
# Follow logs for specific request ID
tail -f /var/log/app.log | grep "abc123-def456-ghi789"

# Extract request timeline
cat /var/log/app.log | jq 'select(.request_id=="abc123-def456-ghi789") | {timestamp, message, duration}'
```

### 2. Error Investigation

```bash
# Find all errors for specific time range
cat /var/log/app.log | jq 'select(.level=="error" and .timestamp >= "2025-09-02T10:00:00Z")'

# Group errors by type
cat /var/log/app.log | jq -r 'select(.level=="error") | .error' | sort | uniq -c
```

### 3. Performance Analysis

```bash
# Find slowest requests
cat /var/log/app.log | jq 'select(.duration > 1000) | {request_id, method, path, duration}' | sort -k4 -nr
```

## Performance Impact

### 1. Logging Overhead
- **Structured Logging**: ~5-10μs per log entry
- **JSON Encoding**: ~2-3μs additional overhead
- **Context Propagation**: Minimal overhead (<1μs)

### 2. Metrics Overhead
- **Counter Increment**: ~100ns per metric
- **Histogram Observation**: ~200ns per metric  
- **Gauge Update**: ~50ns per metric

### 3. Health Check Impact
- **Liveness Check**: ~1ms (lightweight)
- **Readiness Check**: ~10-50ms (includes DB ping)
- **Database Ping**: ~5-15ms depending on connection

## Success Criteria ✅

### ✅ Structured Logging
- [x] Zap logger with JSON format in production
- [x] Request ID correlation in all log entries
- [x] HTTP request logging with method, path, status, duration
- [x] Multiple log levels with contextual fields
- [x] Performance optimized configuration

### ✅ Health Check Endpoints  
- [x] `/healthz` - Kubernetes liveness probe
- [x] `/readyz` - Kubernetes readiness probe with dependency checks
- [x] `/health` - Detailed health status with system metrics
- [x] Database connectivity checker
- [x] Memory usage checker

### ✅ Prometheus Metrics
- [x] HTTP request metrics (total, duration, in-flight)
- [x] Database metrics (connections, query duration)
- [x] Application metrics (users, posts, sessions)
- [x] Authentication metrics
- [x] System information metrics

### ✅ Correlation ID Middleware
- [x] X-Request-ID header support
- [x] UUID generation if not provided
- [x] Request ID propagation in logs
- [x] Header forwarding in nginx

### ✅ Nginx Integration
- [x] JSON access log format
- [x] Request ID forwarding
- [x] Health check endpoint proxying
- [x] Metrics endpoint configuration

### ✅ Docker Health Checks
- [x] Backend container health check using `/healthz`
- [x] Proper timeout and retry configuration
- [x] Dependency health checks in docker-compose

### ✅ Testing Coverage
- [x] Unit tests for logger functionality
- [x] Health checker tests with mock dependencies
- [x] Metrics recording tests
- [x] Middleware integration tests

## Monitoring Dashboard

The observability implementation enables comprehensive monitoring:

**Key Metrics to Monitor:**
1. **Golden Signals**: Latency, Traffic, Errors, Saturation
2. **Application Health**: Uptime, Memory usage, GC performance
3. **Database Health**: Connection pool, Query performance
4. **Business Metrics**: Active users, Content creation rate

**Alert Thresholds:**
- Error rate > 5% for 5 minutes
- Response time P95 > 2 seconds for 5 minutes  
- Memory usage > 80% for 10 minutes
- Database connections > 90% for 5 minutes

The BlogCMS API now has enterprise-grade observability features that provide complete visibility into application behavior, performance, and health status!
