# Observability Quick Start Guide

This guide shows how to use the observability features implemented in Phase 13.

## 🚀 Starting the Application

```bash
# Start with observability enabled
cd /workspaces/go-vue-blogcms/backend
go run cmd/server/main.go
```

You'll see structured logs like:
```json
{
  "level": "info",
  "timestamp": "2025-09-02T10:30:45.123Z",
  "message": "Starting BlogCMS API Server",
  "service": "blogcms-api",
  "hostname": "server-01",
  "environment": "development",
  "port": "8080"
}
```

## 🏥 Health Check Endpoints

### Kubernetes Liveness Probe
```bash
curl http://localhost:8080/healthz
```

Response:
```json
{
  "status": "healthy",
  "timestamp": "2025-09-02T10:30:45.123Z",
  "service": "blogcms-api",
  "version": "1.0.0",
  "uptime_seconds": 3600.5
}
```

### Kubernetes Readiness Probe
```bash
curl http://localhost:8080/readyz
```

Response (503 if unhealthy):
```json
{
  "status": "healthy",
  "checks": {
    "database": {"status": "healthy", "duration_ms": 15.2},
    "memory": {"status": "healthy", "duration_ms": 2.1}
  }
}
```

### Detailed Health Information
```bash
curl http://localhost:8080/health | jq '.'
```

## 📊 Prometheus Metrics

### View All Metrics
```bash
curl http://localhost:8080/metrics
```

### Specific Metrics Examples
```bash
# HTTP request metrics
curl -s http://localhost:8080/metrics | grep blogcms_http_requests_total

# Database connection metrics
curl -s http://localhost:8080/metrics | grep blogcms_db_connections

# Application metrics
curl -s http://localhost:8080/metrics | grep blogcms_posts_total
```

## 🔍 Request Tracing with Correlation ID

### Send Request with Custom Request ID
```bash
curl -H "X-Request-ID: my-custom-request-123" \
     http://localhost:8080/api/v1/posts
```

### Auto-Generated Request ID
```bash
curl -v http://localhost:8080/api/v1/posts
# Check the X-Request-ID in response headers
```

### Follow Request in Logs
```bash
# In another terminal, follow logs
tail -f logs/app.log | grep "my-custom-request-123"
```

## 📱 Testing Different Scenarios

### Generate Load for Metrics
```bash
# Generate various HTTP requests
for i in {1..100}; do
  curl -s -H "X-Request-ID: load-test-$i" \
       http://localhost:8080/api/v1/posts >/dev/null &
done

# Check metrics after load
curl -s http://localhost:8080/metrics | grep blogcms_http_requests_total
```

### Test Error Scenarios
```bash
# Generate 404 errors
curl http://localhost:8080/api/v1/posts/nonexistent

# Generate 401 errors  
curl http://localhost:8080/api/v1/auth/profile

# Check error metrics
curl -s http://localhost:8080/metrics | grep 'status_code="404"'
```

### Test Database Health
```bash
# Stop database temporarily (in another terminal)
docker-compose stop mysql

# Check readiness probe (should return 503)
curl -w "%{http_code}" http://localhost:8080/readyz

# Start database again
docker-compose start mysql

# Check readiness probe (should return 200)
curl -w "%{http_code}" http://localhost:8080/readyz
```

## 🐳 Docker Compose with Health Checks

```bash
# Start with health checks enabled
docker-compose up -d

# Check container health status
docker-compose ps

# View health check logs
docker inspect blogcms-backend | jq '.[0].State.Health'
```

## 📊 Log Analysis Examples

### View Structured Logs
```bash
# Follow logs with JSON formatting
docker-compose logs -f backend | jq '.'

# Filter by log level
docker-compose logs backend | jq 'select(.level=="error")'

# Filter by request ID
docker-compose logs backend | jq 'select(.request_id=="abc123")'
```

### Performance Analysis
```bash
# Find slow requests (>1 second)
docker-compose logs backend | jq 'select(.duration > 1000) | {request_id, method, path, duration}'

# Group requests by status code
docker-compose logs backend | jq -r '.status_code' | sort | uniq -c
```

## 🔧 Configuration Examples

### Environment Variables
```bash
# Set log level to debug
export LOG_LEVEL=debug

# Disable metrics in production
export METRICS_ENABLED=false

# Set memory limit for health checks
export MEMORY_LIMIT_MB=1000
```

### Production Configuration
```bash
# Production settings
export GIN_MODE=release
export LOG_FORMAT=json
export LOG_LEVEL=info
export METRICS_ENABLED=true
```

## 🚨 Monitoring Setup

### Prometheus Configuration
```yaml
# prometheus.yml
scrape_configs:
  - job_name: 'blogcms'
    static_configs:
      - targets: ['localhost:8080']
    metrics_path: '/metrics'
    scrape_interval: 15s
```

### Grafana Dashboard Queries
```promql
# Request rate
rate(blogcms_http_requests_total[5m])

# Error rate percentage
(rate(blogcms_http_requests_total{status_code=~"5.."}[5m]) / rate(blogcms_http_requests_total[5m])) * 100

# 95th percentile response time
histogram_quantile(0.95, rate(blogcms_http_request_duration_seconds_bucket[5m]))

# Active database connections
blogcms_db_connections_active
```

### Alert Examples
```yaml
# Alertmanager configuration
groups:
- name: blogcms
  rules:
  - alert: HighErrorRate
    expr: (rate(blogcms_http_requests_total{status_code=~"5.."}[5m]) / rate(blogcms_http_requests_total[5m])) > 0.05
    for: 2m
    labels:
      severity: warning
    annotations:
      summary: "High error rate in BlogCMS API"
      
  - alert: ServiceDown
    expr: up{job="blogcms"} == 0
    for: 1m
    labels:
      severity: critical
    annotations:
      summary: "BlogCMS API is down"
```

## 🎯 Best Practices

### Request ID Usage
- Always include X-Request-ID in client requests
- Use request ID for support case tracking
- Include request ID in error reports

### Health Check Strategy
- Use `/healthz` for Kubernetes liveness probes
- Use `/readyz` for load balancer health checks
- Monitor `/health` for detailed diagnostics

### Metrics Collection
- Set up Prometheus to scrape `/metrics` every 15s
- Create dashboards for key business metrics
- Set up alerts for SLA violations

### Log Management
- Use structured JSON logs in production
- Set up log aggregation (ELK stack, Fluentd)
- Implement log retention policies
- Monitor log error rates

This implementation provides enterprise-grade observability for production monitoring, debugging, and performance optimization!
