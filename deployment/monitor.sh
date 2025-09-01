#!/bin/bash

# System Monitoring Script
# Monitors Docker containers and system resources

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Function to check container health
check_container_health() {
    local container_name=$1
    local health_status=$(docker inspect --format='{{.State.Health.Status}}' $container_name 2>/dev/null || echo "no-health-check")
    
    if [ "$health_status" = "healthy" ]; then
        print_status "$container_name is healthy"
    elif [ "$health_status" = "unhealthy" ]; then
        print_error "$container_name is unhealthy"
    elif [ "$health_status" = "starting" ]; then
        print_warning "$container_name is starting"
    else
        # Check if container is running
        if docker ps --format '{{.Names}}' | grep -q "^$container_name$"; then
            print_status "$container_name is running (no health check)"
        else
            print_error "$container_name is not running"
        fi
    fi
}

# Function to check API endpoint
check_api_endpoint() {
    local url=$1
    if curl -f -s "$url" > /dev/null 2>&1; then
        print_status "API endpoint $url is responding"
    else
        print_error "API endpoint $url is not responding"
    fi
}

clear
print_header "Blog CMS System Monitor - $(date)"

# System Resources
print_header "System Resources"
echo "CPU Usage: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)%"
echo "Memory Usage: $(free | grep Mem | awk '{printf("%.1f%%", $3/$2 * 100.0)}')"
echo "Disk Usage: $(df -h / | awk 'NR==2{printf "%s", $5}')"
echo "Load Average: $(uptime | awk -F'load average:' '{print $2}')"

# Docker Status
print_header "Docker Status"
if systemctl is-active --quiet docker; then
    print_status "Docker service is running"
else
    print_error "Docker service is not running"
fi

# Container Health
print_header "Container Health"
check_container_health "blogcms_mysql_prod"
check_container_health "blogcms_backend_prod"
check_container_health "blogcms_nginx_prod"
check_container_health "blogcms_adminer_prod"

# Container Stats
print_header "Container Resource Usage"
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}" | head -5

# API Health Check
print_header "API Health Check"
if [ -f .env ]; then
    source .env
    check_api_endpoint "https://$DOMAIN/health"
    check_api_endpoint "https://$DOMAIN/api/v1/auth/register"
else
    print_warning "No .env file found, skipping API checks"
fi

# Recent Logs
print_header "Recent Logs (Last 10 lines)"
echo "Backend logs:"
docker-compose logs --tail=5 backend 2>/dev/null || echo "No backend logs available"
echo ""
echo "MySQL logs:"
docker-compose logs --tail=5 mysql 2>/dev/null || echo "No MySQL logs available"

# SSL Certificate Status
print_header "SSL Certificate Status"
if [ -f "nginx/ssl/fullchain.pem" ]; then
    CERT_EXPIRY=$(openssl x509 -enddate -noout -in nginx/ssl/fullchain.pem | cut -d= -f2)
    CERT_EXPIRY_EPOCH=$(date -d "$CERT_EXPIRY" +%s)
    CURRENT_EPOCH=$(date +%s)
    DAYS_UNTIL_EXPIRY=$(( ($CERT_EXPIRY_EPOCH - $CURRENT_EPOCH) / 86400 ))
    
    if [ $DAYS_UNTIL_EXPIRY -lt 30 ]; then
        print_error "SSL certificate expires in $DAYS_UNTIL_EXPIRY days"
    elif [ $DAYS_UNTIL_EXPIRY -lt 90 ]; then
        print_warning "SSL certificate expires in $DAYS_UNTIL_EXPIRY days"
    else
        print_status "SSL certificate expires in $DAYS_UNTIL_EXPIRY days"
    fi
else
    print_error "SSL certificate not found"
fi

# Backup Status
print_header "Recent Backups"
if [ -d "backups" ]; then
    LATEST_BACKUP=$(ls -t backups/blogcms_backup_*.sql.gz 2>/dev/null | head -1)
    if [ ! -z "$LATEST_BACKUP" ]; then
        BACKUP_DATE=$(stat -c %y "$LATEST_BACKUP" | cut -d' ' -f1)
        BACKUP_SIZE=$(du -h "$LATEST_BACKUP" | cut -f1)
        print_status "Latest backup: $LATEST_BACKUP ($BACKUP_SIZE, $BACKUP_DATE)"
    else
        print_warning "No backups found"
    fi
else
    print_warning "Backup directory not found"
fi

print_header "Monitor Complete"
echo "Run 'docker-compose logs -f' to view live logs"
echo "Run './backup.sh' to create a database backup"
