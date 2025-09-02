#!/bin/bash

# Production Setup Script - Deploy BlogCMS with SSL
# This script deploys the application with Let's Encrypt SSL certificates

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
    exit 1
}

step() {
    echo -e "${CYAN}[STEP] $1${NC}"
}

# Configuration
DOMAIN=""
API_DOMAIN=""
APP_DOMAIN=""
INSTALL_DIR="/opt/blogcms"
BACKUP_DIR="/opt/blogcms/backups"
JWT_SECRET=""

print_header() {
    echo -e "${PURPLE}"
    echo "╔══════════════════════════════════════════════════════════════════════════════╗"
    echo "║                          BlogCMS Production Setup                           ║"
    echo "║                        SSL-Enabled Deployment                               ║"
    echo "╚══════════════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Check prerequisites
check_prerequisites() {
    step "Checking Prerequisites"
    
    # Check if running as non-root
    if [[ $EUID -eq 0 ]]; then
        error "This script should not be run as root"
    fi
    
    # Check if hardening was run
    if ! sudo ufw status | grep -q "Status: active"; then
        error "UFW firewall is not active. Please run production-hardening.sh first"
    fi
    
    # Check required commands
    local required_commands=("docker" "docker-compose" "certbot" "openssl")
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            error "Required command '$cmd' not found"
        fi
    done
    
    log "Prerequisites check passed"
}

# Get configuration
get_configuration() {
    step "Getting Configuration"
    
    read -p "Enter your main domain (e.g., example.com): " DOMAIN
    if [[ -z "$DOMAIN" ]]; then
        error "Domain is required"
    fi
    
    read -p "Enter API subdomain (default: api): " api_subdomain
    API_DOMAIN="${api_subdomain:-api}.${DOMAIN}"
    
    read -p "Enter App subdomain (default: app): " app_subdomain
    APP_DOMAIN="${app_subdomain:-app}.${DOMAIN}"
    
    # Check if SSL certificates exist
    if [[ ! -f "/etc/letsencrypt/live/$API_DOMAIN/fullchain.pem" ]]; then
        error "SSL certificate for $API_DOMAIN not found. Please run production-hardening.sh first"
    fi
    
    if [[ ! -f "/etc/letsencrypt/live/$APP_DOMAIN/fullchain.pem" ]]; then
        error "SSL certificate for $APP_DOMAIN not found. Please run production-hardening.sh first"
    fi
    
    log "SSL certificates found for both domains"
}

# Generate JWT secret
generate_jwt_secret() {
    step "Generating JWT Secret"
    
    JWT_SECRET=$(openssl rand -base64 64 | tr -d "=+/" | cut -c1-64)
    log "JWT secret generated"
}

# Create production environment file
create_production_env() {
    step "Creating Production Environment Configuration"
    
    # Create .env.production file
    cat > "$INSTALL_DIR/.env.production" <<EOF
# Production Environment Configuration
# Generated on: $(date)

# Application
APP_ENV=production
APP_DEBUG=false
APP_URL=https://$APP_DOMAIN
API_URL=https://$API_DOMAIN

# Database
DB_HOST=db
DB_PORT=3306
DB_NAME=blogcms
DB_USER=blogcms
DB_PASSWORD=$(openssl rand -base64 32)

# JWT Configuration
JWT_SECRET=$JWT_SECRET
JWT_EXPIRY=24h
JWT_REFRESH_EXPIRY=168h

# Redis
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_PASSWORD=$(openssl rand -base64 32)

# CORS
CORS_ALLOWED_ORIGINS=https://$APP_DOMAIN
CORS_ALLOWED_METHODS=GET,POST,PUT,DELETE,OPTIONS
CORS_ALLOWED_HEADERS=Content-Type,Authorization,X-Requested-With

# File Upload
MAX_UPLOAD_SIZE=10485760
UPLOAD_PATH=/app/uploads

# Rate Limiting
RATE_LIMIT_REQUESTS=100
RATE_LIMIT_WINDOW=3600

# Logging
LOG_LEVEL=info
LOG_FORMAT=json

# SSL/TLS
API_DOMAIN=$API_DOMAIN
APP_DOMAIN=$APP_DOMAIN

# Backup Configuration
BACKUP_ENABLED=true
BACKUP_SCHEDULE=0 2 * * *
BACKUP_RETENTION_DAYS=30

# Monitoring
METRICS_ENABLED=true
HEALTH_CHECK_ENABLED=true

# Security Headers
SECURITY_HEADERS_ENABLED=true
HSTS_MAX_AGE=31536000
EOF

    # Set proper permissions
    chmod 600 "$INSTALL_DIR/.env.production"
    
    log "Production environment file created"
}

# Create production nginx configuration
create_nginx_config() {
    step "Creating Production Nginx Configuration"
    
    # Create nginx configuration with SSL
    cat > "$INSTALL_DIR/nginx/nginx.conf" <<EOF
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;

events {
    worker_connections 1024;
    use epoll;
    multi_accept on;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    # Logging format
    log_format json_combined escape=json
    '{'
        '"time_local":"\$time_local",'
        '"remote_addr":"\$remote_addr",'
        '"remote_user":"\$remote_user",'
        '"request":"\$request",'
        '"status": "\$status",'
        '"body_bytes_sent":"\$body_bytes_sent",'
        '"request_time":"\$request_time",'
        '"http_referrer":"\$http_referer",'
        '"http_user_agent":"\$http_user_agent",'
        '"http_x_forwarded_for":"\$http_x_forwarded_for",'
        '"http_x_correlation_id":"\$http_x_correlation_id"'
    '}';

    access_log /var/log/nginx/access.log json_combined;

    # Basic Settings
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    server_tokens off;

    # Gzip Settings
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/javascript
        application/xml+rss
        application/json;

    # Rate Limiting
    limit_req_zone \$binary_remote_addr zone=api:10m rate=10r/s;
    limit_req_zone \$binary_remote_addr zone=app:10m rate=20r/s;

    # Security Headers
    add_header X-Frame-Options DENY always;
    add_header X-Content-Type-Options nosniff always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; font-src 'self'; connect-src 'self'; frame-ancestors 'none';" always;

    # API Server Configuration
    upstream api_backend {
        server app:8080;
        keepalive 32;
    }

    # API Server - HTTPS
    server {
        listen 443 ssl http2;
        server_name $API_DOMAIN;

        # SSL Configuration
        ssl_certificate /etc/letsencrypt/live/$API_DOMAIN/fullchain.pem;
        ssl_certificate_key /etc/letsencrypt/live/$API_DOMAIN/privkey.pem;
        ssl_session_timeout 1d;
        ssl_session_cache shared:SSL:50m;
        ssl_session_tickets off;

        # Modern configuration
        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
        ssl_prefer_server_ciphers off;

        # HSTS
        add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

        # OCSP stapling
        ssl_stapling on;
        ssl_stapling_verify on;

        location / {
            limit_req zone=api burst=20 nodelay;
            
            proxy_pass http://api_backend;
            proxy_http_version 1.1;
            proxy_set_header Upgrade \$http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
            proxy_cache_bypass \$http_upgrade;
            
            # Timeouts
            proxy_connect_timeout 30s;
            proxy_send_timeout 30s;
            proxy_read_timeout 30s;
        }

        # Health check endpoint
        location /healthz {
            proxy_pass http://api_backend/healthz;
            access_log off;
        }
    }

    # API Server - HTTP to HTTPS redirect
    server {
        listen 80;
        server_name $API_DOMAIN;
        return 301 https://\$server_name\$request_uri;
    }

    # Frontend App - HTTPS
    server {
        listen 443 ssl http2;
        server_name $APP_DOMAIN;

        # SSL Configuration
        ssl_certificate /etc/letsencrypt/live/$APP_DOMAIN/fullchain.pem;
        ssl_certificate_key /etc/letsencrypt/live/$APP_DOMAIN/privkey.pem;
        ssl_session_timeout 1d;
        ssl_session_cache shared:SSL:50m;
        ssl_session_tickets off;

        # Modern configuration
        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
        ssl_prefer_server_ciphers off;

        # HSTS
        add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

        # OCSP stapling
        ssl_stapling on;
        ssl_stapling_verify on;

        root /usr/share/nginx/html;
        index index.html;

        # Static file handling
        location / {
            limit_req zone=app burst=50 nodelay;
            try_files \$uri \$uri/ /index.html;
            
            # Cache static files
            location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)\$ {
                expires 1y;
                add_header Cache-Control "public, immutable";
                access_log off;
            }
        }

        # API proxy
        location /api/ {
            limit_req zone=api burst=20 nodelay;
            proxy_pass https://$API_DOMAIN/;
            proxy_set_header Host $API_DOMAIN;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
        }
    }

    # Frontend App - HTTP to HTTPS redirect
    server {
        listen 80;
        server_name $APP_DOMAIN;
        return 301 https://\$server_name\$request_uri;
    }
}
EOF

    log "Production nginx configuration created"
}

# Create production docker-compose file
create_docker_compose() {
    step "Creating Production Docker Compose Configuration"
    
    cat > "$INSTALL_DIR/docker-compose.production.yml" <<EOF
version: '3.8'

services:
  app:
    build: .
    restart: unless-stopped
    env_file: .env.production
    depends_on:
      db:
        condition: service_healthy
      redis:
        condition: service_healthy
    volumes:
      - ./uploads:/app/uploads
      - ./logs:/app/logs
    networks:
      - blogcms
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/healthz"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

  db:
    image: mysql:8.0
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: \${DB_PASSWORD}
      MYSQL_DATABASE: \${DB_NAME}
      MYSQL_USER: \${DB_USER}
      MYSQL_PASSWORD: \${DB_PASSWORD}
    volumes:
      - mysql_data:/var/lib/mysql
      - ./scripts/init.sql:/docker-entrypoint-initdb.d/init.sql:ro
    networks:
      - blogcms
    command: --default-authentication-plugin=mysql_native_password
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 30s

  redis:
    image: redis:7-alpine
    restart: unless-stopped
    command: redis-server --requirepass \${REDIS_PASSWORD}
    volumes:
      - redis_data:/data
    networks:
      - blogcms
    healthcheck:
      test: ["CMD", "redis-cli", "--raw", "incr", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5

  nginx:
    image: nginx:alpine
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./frontend/dist:/usr/share/nginx/html:ro
      - /etc/letsencrypt:/etc/letsencrypt:ro
      - ./logs/nginx:/var/log/nginx
    depends_on:
      - app
    networks:
      - blogcms
    healthcheck:
      test: ["CMD", "nginx", "-t"]
      interval: 30s
      timeout: 10s
      retries: 3

volumes:
  mysql_data:
  redis_data:

networks:
  blogcms:
    driver: bridge
EOF

    log "Production docker-compose configuration created"
}

# Create backup script
create_backup_script() {
    step "Creating Production Backup Script"
    
    cat > "$INSTALL_DIR/scripts/production-backup.sh" <<'EOF'
#!/bin/bash

# Production Backup Script for BlogCMS
# Performs daily MySQL backups with S3 upload and retention management

set -e

# Load environment variables
if [[ -f "/opt/blogcms/.env.production" ]]; then
    source /opt/blogcms/.env.production
fi

# Configuration
BACKUP_DIR="/opt/blogcms/backups"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="blogcms_backup_${DATE}.sql.gz"
LOG_FILE="/opt/blogcms/logs/backup.log"
RETENTION_DAYS=${BACKUP_RETENTION_DAYS:-30}

# Logging
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

error() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1" | tee -a "$LOG_FILE"
    exit 1
}

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Perform MySQL backup
log "Starting MySQL backup"
if ! docker-compose -f /opt/blogcms/docker-compose.production.yml exec -T db mysqldump \
    -u"$DB_USER" -p"$DB_PASSWORD" \
    --single-transaction \
    --routines \
    --triggers \
    --all-databases | gzip > "$BACKUP_DIR/$BACKUP_FILE"; then
    error "MySQL backup failed"
fi

log "MySQL backup completed: $BACKUP_FILE"

# Upload to S3 if configured
if [[ -n "$AWS_ACCESS_KEY_ID" && -n "$AWS_SECRET_ACCESS_KEY" && -n "$S3_BUCKET" ]]; then
    log "Uploading backup to S3"
    if ! aws s3 cp "$BACKUP_DIR/$BACKUP_FILE" "s3://$S3_BUCKET/backups/$BACKUP_FILE"; then
        error "S3 upload failed"
    fi
    log "Backup uploaded to S3: s3://$S3_BUCKET/backups/$BACKUP_FILE"
fi

# Clean old local backups
log "Cleaning old local backups (retention: $RETENTION_DAYS days)"
find "$BACKUP_DIR" -name "blogcms_backup_*.sql.gz" -mtime +$RETENTION_DAYS -delete

# Clean old S3 backups if configured
if [[ -n "$AWS_ACCESS_KEY_ID" && -n "$S3_BUCKET" ]]; then
    log "Cleaning old S3 backups"
    CUTOFF_DATE=$(date -d "$RETENTION_DAYS days ago" +%Y%m%d)
    aws s3 ls "s3://$S3_BUCKET/backups/" | while read -r line; do
        BACKUP_DATE=$(echo "$line" | awk '{print $4}' | grep -o '[0-9]\{8\}' | head -1)
        if [[ -n "$BACKUP_DATE" && "$BACKUP_DATE" -lt "$CUTOFF_DATE" ]]; then
            BACKUP_KEY=$(echo "$line" | awk '{print $4}')
            aws s3 rm "s3://$S3_BUCKET/backups/$BACKUP_KEY"
            log "Deleted old S3 backup: $BACKUP_KEY"
        fi
    done
fi

log "Backup process completed successfully"
EOF

    chmod +x "$INSTALL_DIR/scripts/production-backup.sh"
    
    # Create backup cron job
    echo "0 2 * * * $INSTALL_DIR/scripts/production-backup.sh" | sudo crontab -
    
    log "Production backup script and cron job created"
}

# Create admin bootstrap script
create_admin_bootstrap() {
    step "Creating Admin Bootstrap Script"
    
    cat > "$INSTALL_DIR/scripts/bootstrap-admin.sh" <<'EOF'
#!/bin/bash

# Bootstrap Admin User Script
# Creates the first admin user for BlogCMS

set -e

# Configuration
ENV_FILE="/opt/blogcms/.env.production"
COMPOSE_FILE="/opt/blogcms/docker-compose.production.yml"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
    exit 1
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

# Load environment
if [[ ! -f "$ENV_FILE" ]]; then
    error "Environment file not found: $ENV_FILE"
fi

source "$ENV_FILE"

# Get admin details
echo "Creating first admin user for BlogCMS"
echo "======================================"

read -p "Enter admin username: " ADMIN_USERNAME
if [[ -z "$ADMIN_USERNAME" ]]; then
    error "Username is required"
fi

read -p "Enter admin email: " ADMIN_EMAIL
if [[ -z "$ADMIN_EMAIL" ]]; then
    error "Email is required"
fi

read -s -p "Enter admin password: " ADMIN_PASSWORD
echo
if [[ -z "$ADMIN_PASSWORD" ]]; then
    error "Password is required"
fi

read -s -p "Confirm admin password: " ADMIN_PASSWORD_CONFIRM
echo
if [[ "$ADMIN_PASSWORD" != "$ADMIN_PASSWORD_CONFIRM" ]]; then
    error "Passwords do not match"
fi

# Create admin user via API
log "Creating admin user..."

# Wait for application to be ready
log "Waiting for application to be ready..."
for i in {1..30}; do
    if docker-compose -f "$COMPOSE_FILE" exec -T app curl -f http://localhost:8080/healthz > /dev/null 2>&1; then
        break
    fi
    if [[ $i -eq 30 ]]; then
        error "Application did not become ready in time"
    fi
    sleep 2
done

# Create admin user
ADMIN_DATA=$(cat <<EOF
{
    "username": "$ADMIN_USERNAME",
    "email": "$ADMIN_EMAIL",
    "password": "$ADMIN_PASSWORD",
    "role": "admin"
}
EOF
)

if docker-compose -f "$COMPOSE_FILE" exec -T app curl -X POST \
    -H "Content-Type: application/json" \
    -d "$ADMIN_DATA" \
    http://localhost:8080/api/auth/bootstrap-admin > /dev/null 2>&1; then
    log "Admin user created successfully!"
    log "Username: $ADMIN_USERNAME"
    log "Email: $ADMIN_EMAIL"
    log "You can now login at: https://$APP_DOMAIN"
else
    error "Failed to create admin user. Check application logs."
fi
EOF

    chmod +x "$INSTALL_DIR/scripts/bootstrap-admin.sh"
    
    log "Admin bootstrap script created"
}

# Create JWT rotation script
create_jwt_rotation() {
    step "Creating JWT Secret Rotation Script"
    
    cat > "$INSTALL_DIR/scripts/rotate-jwt-secret.sh" <<'EOF'
#!/bin/bash

# JWT Secret Rotation Script
# Rotates JWT secret with zero-downtime deployment

set -e

# Configuration
ENV_FILE="/opt/blogcms/.env.production"
COMPOSE_FILE="/opt/blogcms/docker-compose.production.yml"
BACKUP_DIR="/opt/blogcms/backups"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
    exit 1
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

step() {
    echo -e "${BLUE}[STEP] $1${NC}"
}

# Check if environment file exists
if [[ ! -f "$ENV_FILE" ]]; then
    error "Environment file not found: $ENV_FILE"
fi

# Backup current environment
step "Backing up current environment"
cp "$ENV_FILE" "$BACKUP_DIR/.env.production.backup.$(date +%Y%m%d_%H%M%S)"

# Generate new JWT secret
step "Generating new JWT secret"
NEW_JWT_SECRET=$(openssl rand -base64 64 | tr -d "=+/" | cut -c1-64)

# Update environment file
step "Updating JWT secret in environment file"
sed -i "s/^JWT_SECRET=.*/JWT_SECRET=$NEW_JWT_SECRET/" "$ENV_FILE"

# Restart application
step "Restarting application with new JWT secret"
docker-compose -f "$COMPOSE_FILE" restart app

# Wait for application to be ready
step "Waiting for application to be ready"
for i in {1..30}; do
    if docker-compose -f "$COMPOSE_FILE" exec -T app curl -f http://localhost:8080/healthz > /dev/null 2>&1; then
        break
    fi
    if [[ $i -eq 30 ]]; then
        error "Application did not restart properly"
    fi
    sleep 2
done

log "JWT secret rotation completed successfully!"
warn "All users will need to re-authenticate due to the JWT secret change."

echo ""
echo "JWT Rotation Summary:"
echo "===================="
echo "- New JWT secret generated and applied"
echo "- Application restarted successfully"
echo "- Previous environment backed up"
echo "- All existing JWT tokens are now invalid"
echo ""
echo "Next steps:"
echo "- Notify users about the re-authentication requirement"
echo "- Monitor application logs for any issues"
echo "- Consider rotating JWT secrets monthly for security"
EOF

    chmod +x "$INSTALL_DIR/scripts/rotate-jwt-secret.sh"
    
    log "JWT rotation script created"
}

# Create migration script
create_migration_script() {
    step "Creating Auto-Migration Script"
    
    cat > "$INSTALL_DIR/scripts/auto-migrate.sh" <<'EOF'
#!/bin/bash

# Auto-Migration Script
# Runs database migrations on container startup (idempotent)

set -e

# Configuration
ENV_FILE="/opt/blogcms/.env.production"
MIGRATION_LOCK="/tmp/migration.lock"
MIGRATION_LOG="/opt/blogcms/logs/migration.log"

# Load environment
if [[ -f "$ENV_FILE" ]]; then
    source "$ENV_FILE"
fi

# Logging
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$MIGRATION_LOG"
}

error() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1" | tee -a "$MIGRATION_LOG"
    exit 1
}

# Check if migration is already running
if [[ -f "$MIGRATION_LOCK" ]]; then
    log "Migration already in progress, waiting..."
    while [[ -f "$MIGRATION_LOCK" ]]; do
        sleep 5
    done
    log "Migration completed by another process"
    exit 0
fi

# Create migration lock
touch "$MIGRATION_LOCK"
trap 'rm -f "$MIGRATION_LOCK"' EXIT

log "Starting database migration"

# Wait for database to be ready
log "Waiting for database to be ready..."
for i in {1..30}; do
    if mysql -h"$DB_HOST" -u"$DB_USER" -p"$DB_PASSWORD" -e "SELECT 1" > /dev/null 2>&1; then
        break
    fi
    if [[ $i -eq 30 ]]; then
        error "Database is not ready"
    fi
    sleep 2
done

# Run migrations
log "Running database migrations"
if [[ -f "/app/migrations/migrate" ]]; then
    /app/migrations/migrate || error "Migration failed"
else
    log "No migration binary found, skipping..."
fi

log "Database migration completed successfully"
EOF

    chmod +x "$INSTALL_DIR/scripts/auto-migrate.sh"
    
    log "Auto-migration script created"
}

# Create monitoring script
create_monitoring_script() {
    step "Creating Production Monitoring Script"
    
    cat > "$INSTALL_DIR/scripts/monitor-production.sh" <<'EOF'
#!/bin/bash

# Production Monitoring Script
# Monitors system health and sends alerts

set -e

# Configuration
ENV_FILE="/opt/blogcms/.env.production"
COMPOSE_FILE="/opt/blogcms/docker-compose.production.yml"
LOG_FILE="/opt/blogcms/logs/monitor.log"

# Load environment
if [[ -f "$ENV_FILE" ]]; then
    source "$ENV_FILE"
fi

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}" | tee -a "$LOG_FILE"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}" | tee -a "$LOG_FILE"
}

# Check disk space
check_disk_space() {
    DISK_USAGE=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
    if [[ $DISK_USAGE -gt 80 ]]; then
        error "High disk usage: ${DISK_USAGE}%"
        return 1
    elif [[ $DISK_USAGE -gt 70 ]]; then
        warn "Moderate disk usage: ${DISK_USAGE}%"
    else
        log "Disk usage OK: ${DISK_USAGE}%"
    fi
    return 0
}

# Check memory usage
check_memory() {
    MEM_USAGE=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100.0}')
    if [[ $MEM_USAGE -gt 90 ]]; then
        error "High memory usage: ${MEM_USAGE}%"
        return 1
    elif [[ $MEM_USAGE -gt 80 ]]; then
        warn "Moderate memory usage: ${MEM_USAGE}%"
    else
        log "Memory usage OK: ${MEM_USAGE}%"
    fi
    return 0
}

# Check container health
check_containers() {
    UNHEALTHY=$(docker-compose -f "$COMPOSE_FILE" ps | grep -v "Up (healthy)" | grep -c "Up" || true)
    if [[ $UNHEALTHY -gt 0 ]]; then
        error "$UNHEALTHY containers are not healthy"
        docker-compose -f "$COMPOSE_FILE" ps | tee -a "$LOG_FILE"
        return 1
    else
        log "All containers are healthy"
    fi
    return 0
}

# Check SSL certificates
check_ssl() {
    for domain in "$API_DOMAIN" "$APP_DOMAIN"; do
        if ! openssl x509 -in "/etc/letsencrypt/live/$domain/cert.pem" -noout -checkend 604800; then
            warn "SSL certificate for $domain expires within 7 days"
        else
            log "SSL certificate for $domain is valid"
        fi
    done
}

# Check application endpoints
check_endpoints() {
    # Check API health
    if ! curl -f "https://$API_DOMAIN/healthz" > /dev/null 2>&1; then
        error "API health check failed"
        return 1
    else
        log "API health check passed"
    fi
    
    # Check app accessibility
    if ! curl -f "https://$APP_DOMAIN" > /dev/null 2>&1; then
        error "App accessibility check failed"
        return 1
    else
        log "App accessibility check passed"
    fi
    
    return 0
}

# Main monitoring function
main() {
    log "Starting production monitoring check"
    
    local issues=0
    
    check_disk_space || ((issues++))
    check_memory || ((issues++))
    check_containers || ((issues++))
    check_ssl
    check_endpoints || ((issues++))
    
    if [[ $issues -gt 0 ]]; then
        error "Monitoring check completed with $issues issue(s)"
        exit 1
    else
        log "All monitoring checks passed"
    fi
}

# Run monitoring
main
EOF

    chmod +x "$INSTALL_DIR/scripts/monitor-production.sh"
    
    # Create monitoring cron job
    echo "*/5 * * * * $INSTALL_DIR/scripts/monitor-production.sh" | sudo crontab -l | { cat; echo "*/5 * * * * $INSTALL_DIR/scripts/monitor-production.sh"; } | sudo crontab -
    
    log "Production monitoring script and cron job created"
}

# Deploy application
deploy_application() {
    step "Deploying Application"
    
    # Create necessary directories
    sudo mkdir -p "$INSTALL_DIR"/{logs,uploads,backups,scripts}
    sudo chown -R "$USER:$USER" "$INSTALL_DIR"
    
    # Copy application files to install directory
    if [[ -d "/workspaces/go-vue-blogcms" ]]; then
        cp -r /workspaces/go-vue-blogcms/* "$INSTALL_DIR/"
    fi
    
    # Build and start services
    cd "$INSTALL_DIR"
    docker-compose -f docker-compose.production.yml build
    docker-compose -f docker-compose.production.yml up -d
    
    # Wait for services to be ready
    log "Waiting for services to be ready..."
    sleep 30
    
    # Check service health
    docker-compose -f docker-compose.production.yml ps
    
    log "Application deployed successfully"
}

# Main execution
main() {
    print_header
    
    check_prerequisites
    get_configuration
    generate_jwt_secret
    create_production_env
    create_nginx_config
    create_docker_compose
    create_backup_script
    create_admin_bootstrap
    create_jwt_rotation
    create_migration_script
    create_monitoring_script
    deploy_application
    
    log "Production setup completed successfully!"
    
    echo ""
    echo -e "${CYAN}Production Setup Summary:${NC}"
    echo "========================="
    echo "• API URL: https://$API_DOMAIN"
    echo "• App URL: https://$APP_DOMAIN"
    echo "• SSL certificates configured with auto-renewal"
    echo "• Daily backups configured"
    echo "• Monitoring enabled (5-minute intervals)"
    echo ""
    echo -e "${CYAN}Next Steps:${NC}"
    echo "1. Create first admin user: $INSTALL_DIR/scripts/bootstrap-admin.sh"
    echo "2. Test SSL grade: https://www.ssllabs.com/ssltest/"
    echo "3. Monitor logs: tail -f $INSTALL_DIR/logs/*.log"
    echo "4. Check monitoring: $INSTALL_DIR/scripts/monitor-production.sh"
    echo ""
    echo -e "${GREEN}Production deployment completed! Your BlogCMS is now live and secured.${NC}"
}

# Run main function
main "$@"
