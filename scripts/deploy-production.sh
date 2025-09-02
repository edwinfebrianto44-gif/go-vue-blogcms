#!/bin/bash

# Production Deployment Script
# Complete setup for BlogCMS production deployment on VPS

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging functions
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

info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $1${NC}"
}

step() {
    echo -e "${PURPLE}[$(date +'%Y-%m-%d %H:%M:%S')] STEP: $1${NC}"
}

success() {
    echo -e "${CYAN}[$(date +'%Y-%m-%d %H:%M:%S')] SUCCESS: $1${NC}"
}

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Default configuration
API_DOMAIN=""
APP_DOMAIN=""
EMAIL=""
SKIP_SSL=false
SKIP_SECURITY=false
SKIP_BACKUP=false
SKIP_ADMIN=false
DRY_RUN=false
FORCE=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --api-domain)
            API_DOMAIN="$2"
            shift 2
            ;;
        --app-domain)
            APP_DOMAIN="$2"
            shift 2
            ;;
        --email)
            EMAIL="$2"
            shift 2
            ;;
        --skip-ssl)
            SKIP_SSL=true
            shift
            ;;
        --skip-security)
            SKIP_SECURITY=true
            shift
            ;;
        --skip-backup)
            SKIP_BACKUP=true
            shift
            ;;
        --skip-admin)
            SKIP_ADMIN=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --force)
            FORCE=true
            shift
            ;;
        -h|--help)
            echo "BlogCMS Production Deployment Script"
            echo ""
            echo "Complete setup for production deployment on VPS"
            echo ""
            echo "Usage: $0 --api-domain api.example.com --app-domain app.example.com --email admin@example.com [OPTIONS]"
            echo ""
            echo "Required Options:"
            echo "  --api-domain DOMAIN   API domain (e.g., api.example.com)"
            echo "  --app-domain DOMAIN   App domain (e.g., app.example.com)"
            echo "  --email EMAIL         Email for SSL certificates and notifications"
            echo ""
            echo "Optional Options:"
            echo "  --skip-ssl           Skip SSL/TLS setup"
            echo "  --skip-security      Skip security hardening"
            echo "  --skip-backup        Skip backup automation setup"
            echo "  --skip-admin         Skip admin user creation"
            echo "  --dry-run           Show what would be done without executing"
            echo "  --force             Force execution without confirmation"
            echo "  -h, --help          Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0 --api-domain api.myblog.com --app-domain blog.myblog.com --email admin@myblog.com"
            echo "  $0 --api-domain api.example.com --app-domain example.com --email me@gmail.com --skip-admin"
            exit 0
            ;;
        *)
            error "Unknown option: $1. Use -h for help."
            ;;
    esac
done

# Validate required parameters
if [[ -z "$API_DOMAIN" ]]; then
    error "API domain is required. Use --api-domain option."
fi

if [[ -z "$APP_DOMAIN" ]]; then
    error "App domain is required. Use --app-domain option."
fi

if [[ -z "$EMAIL" ]]; then
    error "Email is required. Use --email option."
fi

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    error "This script must be run as root (use sudo)"
fi

# Validate email format
if [[ ! "$EMAIL" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
    error "Invalid email format: $EMAIL"
fi

# Display banner
display_banner() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════════════════════╗"
    echo "║                        BlogCMS Production Deployment                        ║"
    echo "║                          Phase 14 - Hardening & Setup                      ║"
    echo "╚══════════════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    echo -e "${BLUE}Configuration:${NC}"
    echo "  API Domain: $API_DOMAIN"
    echo "  App Domain: $APP_DOMAIN"
    echo "  Email: $EMAIL"
    echo "  SSL Setup: $([ "$SKIP_SSL" = true ] && echo "SKIPPED" || echo "ENABLED")"
    echo "  Security Hardening: $([ "$SKIP_SECURITY" = true ] && echo "SKIPPED" || echo "ENABLED")"
    echo "  Backup Automation: $([ "$SKIP_BACKUP" = true ] && echo "SKIPPED" || echo "ENABLED")"
    echo "  Admin Bootstrap: $([ "$SKIP_ADMIN" = true ] && echo "SKIPPED" || echo "ENABLED")"
    echo "  Dry Run: $([ "$DRY_RUN" = true ] && echo "YES" || echo "NO")"
    echo ""
}

# Execute command with dry run support
exec_cmd() {
    local cmd="$1"
    local description="$2"
    
    if [[ "$DRY_RUN" == true ]]; then
        info "[DRY RUN] Would execute: $description"
        info "[DRY RUN] Command: $cmd"
    else
        info "Executing: $description"
        eval "$cmd"
    fi
}

# Check prerequisites
check_prerequisites() {
    step "Checking prerequisites..."
    
    # Check required commands
    local required_commands=(
        "docker"
        "docker-compose"
        "nginx"
        "mysql"
        "openssl"
        "curl"
        "wget"
    )
    
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            error "Required command not found: $cmd"
        fi
    done
    
    # Check Docker service
    if ! systemctl is-active docker &> /dev/null; then
        error "Docker service is not running"
    fi
    
    # Check if domains resolve
    for domain in "$API_DOMAIN" "$APP_DOMAIN"; do
        if ! nslookup "$domain" &> /dev/null; then
            warn "Domain may not resolve: $domain"
        fi
    done
    
    success "Prerequisites check completed"
}

# Setup SSL certificates
setup_ssl() {
    if [[ "$SKIP_SSL" == true ]]; then
        info "Skipping SSL setup as requested"
        return 0
    fi
    
    step "Setting up SSL certificates with Let's Encrypt..."
    
    local ssl_script="$SCRIPT_DIR/setup-ssl.sh"
    if [[ ! -x "$ssl_script" ]]; then
        error "SSL setup script not found or not executable: $ssl_script"
    fi
    
    exec_cmd "$ssl_script --api-domain $API_DOMAIN --app-domain $APP_DOMAIN --email $EMAIL" "SSL certificate setup"
    
    success "SSL certificates configured"
}

# Security hardening
setup_security() {
    if [[ "$SKIP_SECURITY" == true ]]; then
        info "Skipping security hardening as requested"
        return 0
    fi
    
    step "Configuring security hardening..."
    
    local security_script="$SCRIPT_DIR/security-hardening.sh"
    if [[ ! -x "$security_script" ]]; then
        error "Security hardening script not found or not executable: $security_script"
    fi
    
    exec_cmd "$security_script" "Security hardening"
    
    success "Security hardening completed"
}

# Setup backup automation
setup_backup() {
    if [[ "$SKIP_BACKUP" == true ]]; then
        info "Skipping backup automation setup as requested"
        return 0
    fi
    
    step "Setting up backup automation..."
    
    local backup_script="$SCRIPT_DIR/setup-backup.sh"
    if [[ ! -x "$backup_script" ]]; then
        error "Backup setup script not found or not executable: $backup_script"
    fi
    
    exec_cmd "$backup_script" "Backup automation setup"
    
    success "Backup automation configured"
}

# Initialize production environment
init_environment() {
    step "Initializing production environment..."
    
    local env_script="$SCRIPT_DIR/env-manager.sh"
    if [[ ! -x "$env_script" ]]; then
        error "Environment manager script not found or not executable: $env_script"
    fi
    
    exec_cmd "$env_script init --non-interactive" "Production environment initialization"
    
    success "Production environment initialized"
}

# Run database migrations
run_migrations() {
    step "Running database migrations..."
    
    local migrate_script="$SCRIPT_DIR/migrate-db.sh"
    if [[ ! -x "$migrate_script" ]]; then
        error "Database migration script not found or not executable: $migrate_script"
    fi
    
    exec_cmd "$migrate_script" "Database migrations"
    
    success "Database migrations completed"
}

# Create admin user
create_admin() {
    if [[ "$SKIP_ADMIN" == true ]]; then
        info "Skipping admin user creation as requested"
        return 0
    fi
    
    step "Creating admin user..."
    
    local admin_script="$SCRIPT_DIR/admin-bootstrap.sh"
    if [[ ! -x "$admin_script" ]]; then
        error "Admin bootstrap script not found or not executable: $admin_script"
    fi
    
    exec_cmd "$admin_script --email $EMAIL --non-interactive" "Admin user creation"
    
    success "Admin user created"
}

# Configure Nginx
configure_nginx() {
    step "Configuring Nginx for production..."
    
    local nginx_config="/etc/nginx/sites-available/blogcms"
    
    if [[ "$DRY_RUN" == false ]]; then
        cat > "$nginx_config" << EOF
# BlogCMS Production Configuration
# API Server Configuration
server {
    listen 80;
    listen [::]:80;
    server_name $API_DOMAIN;
    
    # Redirect to HTTPS
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name $API_DOMAIN;
    
    # SSL Configuration (managed by Certbot)
    ssl_certificate /etc/letsencrypt/live/$API_DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$API_DOMAIN/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; font-src 'self' https:; connect-src 'self' https:;" always;
    
    # Rate limiting
    limit_req_zone \$binary_remote_addr zone=api_limit:10m rate=10r/s;
    limit_req zone=api_limit burst=20 nodelay;
    
    # API proxy configuration
    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
        
        # Body size
        client_max_body_size 10M;
    }
    
    # Health check endpoint
    location /health {
        proxy_pass http://127.0.0.1:8080/health;
        access_log off;
    }
    
    # Metrics endpoint (restrict access)
    location /metrics {
        allow 127.0.0.1;
        deny all;
        proxy_pass http://127.0.0.1:8080/metrics;
    }
}

# Frontend App Configuration
server {
    listen 80;
    listen [::]:80;
    server_name $APP_DOMAIN;
    
    # Redirect to HTTPS
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name $APP_DOMAIN;
    
    # SSL Configuration (managed by Certbot)
    ssl_certificate /etc/letsencrypt/live/$APP_DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$APP_DOMAIN/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    
    # Document root
    root /var/www/blogcms;
    index index.html index.htm;
    
    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/javascript application/xml+rss application/json;
    
    # Static files
    location / {
        try_files \$uri \$uri/ /index.html;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    # API calls to backend
    location /api/ {
        proxy_pass https://$API_DOMAIN/api/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF
        
        # Enable site
        ln -sf "$nginx_config" /etc/nginx/sites-enabled/blogcms
        
        # Remove default site
        rm -f /etc/nginx/sites-enabled/default
        
        # Test configuration
        nginx -t
        
        # Reload Nginx
        systemctl reload nginx
    else
        info "[DRY RUN] Would configure Nginx with API domain: $API_DOMAIN and App domain: $APP_DOMAIN"
    fi
    
    success "Nginx configuration completed"
}

# Deploy application
deploy_application() {
    step "Deploying application..."
    
    if [[ "$DRY_RUN" == false ]]; then
        cd "$PROJECT_ROOT"
        
        # Pull latest images
        docker-compose pull
        
        # Build and start services
        docker-compose up -d --build
        
        # Wait for services to be ready
        sleep 10
        
        # Check health
        local health_check_attempts=0
        local max_attempts=30
        
        while [[ $health_check_attempts -lt $max_attempts ]]; do
            if curl -s http://localhost:8080/health &> /dev/null; then
                break
            fi
            
            health_check_attempts=$((health_check_attempts + 1))
            sleep 2
        done
        
        if [[ $health_check_attempts -eq $max_attempts ]]; then
            warn "Application health check timeout, but continuing deployment"
        fi
    else
        info "[DRY RUN] Would deploy application using Docker Compose"
    fi
    
    success "Application deployed"
}

# Verify SSL configuration
verify_ssl() {
    if [[ "$SKIP_SSL" == true ]]; then
        return 0
    fi
    
    step "Verifying SSL configuration..."
    
    if [[ "$DRY_RUN" == false ]]; then
        # Test SSL certificates
        for domain in "$API_DOMAIN" "$APP_DOMAIN"; do
            info "Testing SSL certificate for $domain..."
            
            if openssl s_client -connect "$domain:443" -servername "$domain" < /dev/null 2>/dev/null | openssl x509 -noout -dates; then
                success "SSL certificate valid for $domain"
            else
                warn "SSL certificate test failed for $domain"
            fi
        done
        
        # SSL Labs test recommendation
        info "For comprehensive SSL testing, visit:"
        info "https://www.ssllabs.com/ssltest/analyze.html?d=$API_DOMAIN"
        info "https://www.ssllabs.com/ssltest/analyze.html?d=$APP_DOMAIN"
    else
        info "[DRY RUN] Would verify SSL certificates for $API_DOMAIN and $APP_DOMAIN"
    fi
    
    success "SSL verification completed"
}

# Post-deployment checks
post_deployment_checks() {
    step "Running post-deployment checks..."
    
    if [[ "$DRY_RUN" == false ]]; then
        # Check services
        local services=("nginx" "docker" "mysql" "fail2ban")
        for service in "${services[@]}"; do
            if systemctl is-active "$service" &> /dev/null; then
                success "$service is running"
            else
                warn "$service is not running"
            fi
        done
        
        # Check Docker containers
        docker-compose ps
        
        # Check firewall status
        ufw status
        
        # Check fail2ban status
        fail2ban-client status
        
        # Test API endpoints
        local api_url="https://$API_DOMAIN"
        if curl -s "$api_url/health" &> /dev/null; then
            success "API health check passed"
        else
            warn "API health check failed"
        fi
        
        # Check backup configuration
        if [[ "$SKIP_BACKUP" == false ]] && [[ -f "/usr/local/bin/mysql-backup-status" ]]; then
            /usr/local/bin/mysql-backup-status
        fi
    else
        info "[DRY RUN] Would run comprehensive post-deployment checks"
    fi
    
    success "Post-deployment checks completed"
}

# Display deployment summary
display_summary() {
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                        Deployment Summary                                   ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${GREEN}✅ Production deployment completed successfully!${NC}"
    echo ""
    echo -e "${BLUE}Services:${NC}"
    echo "  🌐 API: https://$API_DOMAIN"
    echo "  🌐 App: https://$APP_DOMAIN"
    echo "  📧 Admin Email: $EMAIL"
    echo ""
    echo -e "${BLUE}Security Features:${NC}"
    echo "  🔒 SSL/TLS with Let's Encrypt auto-renewal"
    echo "  🛡️  UFW Firewall (ports 22, 80, 443)"
    echo "  🚫 Fail2ban intrusion prevention"
    echo "  🔐 SSH hardening (key-only authentication)"
    echo "  📊 Security monitoring and daily reports"
    echo ""
    echo -e "${BLUE}Backup System:${NC}"
    echo "  💾 Daily MySQL backups (7-day retention)"
    echo "  📦 Weekly backups (30-day retention)"
    echo "  📅 Monthly backups (365-day retention)"
    echo "  ☁️  S3/MinIO integration available"
    echo ""
    echo -e "${BLUE}Management Commands:${NC}"
    echo "  👤 Admin: sudo /usr/local/bin/mysql-backup-status"
    echo "  🔄 Backup: sudo /usr/local/bin/mysql-backup-daily"
    echo "  🔑 JWT Rotate: sudo $SCRIPT_DIR/env-manager.sh rotate-jwt"
    echo "  🛡️  Security Report: sudo /usr/local/bin/daily-security-report.sh"
    echo ""
    echo -e "${YELLOW}Important Next Steps:${NC}"
    echo "  1. Save admin credentials securely"
    echo "  2. Configure S3/MinIO for remote backups"
    echo "  3. Set up email notifications"
    echo "  4. Test SSL grade: https://www.ssllabs.com/ssltest/"
    echo "  5. Monitor security logs regularly"
    echo ""
    warn "Please secure your admin credentials and configure backup storage!"
}

# Confirmation prompt
confirm_deployment() {
    if [[ "$FORCE" == true ]]; then
        return 0
    fi
    
    echo ""
    warn "This will set up production BlogCMS with:"
    warn "- SSL certificates for $API_DOMAIN and $APP_DOMAIN"
    warn "- Security hardening (firewall, fail2ban, SSH)"
    warn "- Backup automation with database encryption"
    warn "- Admin user creation"
    warn "- Production environment configuration"
    echo ""
    read -p "Are you sure you want to proceed? (yes/no): " confirm
    
    if [[ "$confirm" != "yes" ]]; then
        log "Deployment cancelled by user"
        exit 0
    fi
}

# Main deployment function
main() {
    display_banner
    
    # Confirmation
    confirm_deployment
    
    # Prerequisites
    check_prerequisites
    
    # Initialize environment
    init_environment
    
    # Security hardening
    setup_security
    
    # SSL setup
    setup_ssl
    
    # Configure Nginx
    configure_nginx
    
    # Run migrations
    run_migrations
    
    # Deploy application
    deploy_application
    
    # Backup setup
    setup_backup
    
    # Create admin user
    create_admin
    
    # Verify SSL
    verify_ssl
    
    # Post-deployment checks
    post_deployment_checks
    
    # Display summary
    display_summary
}

# Error handling
trap 'error "Deployment failed with exit code $?"' ERR

# Run main function
main "$@"
