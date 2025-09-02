#!/bin/bash

# Production Validation Script
# Validates that all Phase 14 security requirements are met

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
API_DOMAIN=""
APP_DOMAIN=""
INSTALL_DIR="/opt/blogcms"

# Counters
PASSED=0
FAILED=0
WARNINGS=0

print_header() {
    echo -e "${PURPLE}"
    echo "╔══════════════════════════════════════════════════════════════════════════════╗"
    echo "║                       BlogCMS Production Validation                         ║"
    echo "║                    Phase 14 Security Requirements                           ║"
    echo "╚══════════════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

log() {
    echo -e "${GREEN}✓ $1${NC}"
    ((PASSED++))
}

warn() {
    echo -e "${YELLOW}⚠ WARNING: $1${NC}"
    ((WARNINGS++))
}

error() {
    echo -e "${RED}✗ ERROR: $1${NC}"
    ((FAILED++))
}

info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

step() {
    echo -e "${CYAN}[CHECKING] $1${NC}"
}

# Get configuration
get_config() {
    if [[ -f "$INSTALL_DIR/.env.production" ]]; then
        source "$INSTALL_DIR/.env.production"
        API_DOMAIN="$API_DOMAIN"
        APP_DOMAIN="$APP_DOMAIN"
    else
        read -p "Enter API domain: " API_DOMAIN
        read -p "Enter App domain: " APP_DOMAIN
    fi
}

# Validate SSL certificates
validate_ssl() {
    step "SSL Certificate Validation"
    
    # Check Let's Encrypt certificates exist
    for domain in "$API_DOMAIN" "$APP_DOMAIN"; do
        if [[ -f "/etc/letsencrypt/live/$domain/fullchain.pem" ]]; then
            log "SSL certificate exists for $domain"
            
            # Check expiration
            if openssl x509 -in "/etc/letsencrypt/live/$domain/cert.pem" -noout -checkend 604800; then
                log "SSL certificate for $domain is valid for >7 days"
            else
                warn "SSL certificate for $domain expires within 7 days"
            fi
        else
            error "SSL certificate missing for $domain"
        fi
    done
    
    # Test SSL Labs rating
    info "To verify SSL Labs A+ rating, visit:"
    info "https://www.ssllabs.com/ssltest/analyze.html?d=$API_DOMAIN"
    info "https://www.ssllabs.com/ssltest/analyze.html?d=$APP_DOMAIN"
}

# Validate firewall configuration
validate_firewall() {
    step "Firewall Configuration"
    
    if sudo ufw status | grep -q "Status: active"; then
        log "UFW firewall is active"
        
        # Check allowed ports
        if sudo ufw status | grep -q "22/tcp"; then
            log "SSH port 22 is allowed"
        else
            error "SSH port 22 is not allowed"
        fi
        
        if sudo ufw status | grep -q "80/tcp"; then
            log "HTTP port 80 is allowed"
        else
            error "HTTP port 80 is not allowed"
        fi
        
        if sudo ufw status | grep -q "443/tcp"; then
            log "HTTPS port 443 is allowed"
        else
            error "HTTPS port 443 is not allowed"
        fi
    else
        error "UFW firewall is not active"
    fi
}

# Validate Fail2ban
validate_fail2ban() {
    step "Fail2ban Configuration"
    
    if systemctl is-active --quiet fail2ban; then
        log "Fail2ban service is active"
        
        if sudo fail2ban-client status | grep -q "sshd"; then
            log "SSH jail is configured"
        else
            warn "SSH jail is not configured"
        fi
        
        if sudo fail2ban-client status | grep -q "nginx"; then
            log "Nginx jails are configured"
        else
            warn "Nginx jails are not configured"
        fi
    else
        error "Fail2ban service is not running"
    fi
}

# Validate environment security
validate_environment() {
    step "Environment Security"
    
    if [[ -f "$INSTALL_DIR/.env.production" ]]; then
        log ".env.production file exists"
        
        # Check permissions
        PERMS=$(stat -c "%a" "$INSTALL_DIR/.env.production")
        if [[ "$PERMS" == "600" ]]; then
            log ".env.production has secure permissions (600)"
        else
            warn ".env.production permissions are $PERMS (should be 600)"
        fi
        
        # Check for secrets
        if grep -q "JWT_SECRET=" "$INSTALL_DIR/.env.production"; then
            log "JWT_SECRET is configured"
            
            JWT_SECRET=$(grep "JWT_SECRET=" "$INSTALL_DIR/.env.production" | cut -d'=' -f2)
            if [[ ${#JWT_SECRET} -ge 64 ]]; then
                log "JWT_SECRET length is adequate (${#JWT_SECRET} chars)"
            else
                warn "JWT_SECRET is too short (${#JWT_SECRET} chars, should be ≥64)"
            fi
        else
            error "JWT_SECRET is not configured"
        fi
        
        if grep -q "DB_PASSWORD=" "$INSTALL_DIR/.env.production"; then
            log "Database password is configured"
        else
            error "Database password is not configured"
        fi
    else
        error ".env.production file does not exist"
    fi
    
    # Check .env.production is not in git
    if git check-ignore "$INSTALL_DIR/.env.production" > /dev/null 2>&1; then
        log ".env.production is properly ignored by git"
    else
        warn ".env.production may not be ignored by git"
    fi
}

# Validate backup configuration
validate_backups() {
    step "Backup Configuration"
    
    if [[ -f "$INSTALL_DIR/scripts/production-backup.sh" ]]; then
        log "Backup script exists"
        
        if [[ -x "$INSTALL_DIR/scripts/production-backup.sh" ]]; then
            log "Backup script is executable"
        else
            error "Backup script is not executable"
        fi
        
        # Check cron job
        if crontab -l | grep -q "production-backup.sh"; then
            log "Backup cron job is configured"
        else
            warn "Backup cron job is not configured"
        fi
        
        # Check backup directory
        if [[ -d "$INSTALL_DIR/backups" ]]; then
            log "Backup directory exists"
        else
            warn "Backup directory does not exist"
        fi
    else
        error "Backup script does not exist"
    fi
}

# Validate monitoring
validate_monitoring() {
    step "Monitoring Configuration"
    
    if [[ -f "$INSTALL_DIR/scripts/monitor-production.sh" ]]; then
        log "Monitoring script exists"
        
        if [[ -x "$INSTALL_DIR/scripts/monitor-production.sh" ]]; then
            log "Monitoring script is executable"
        else
            error "Monitoring script is not executable"
        fi
        
        # Check monitoring cron job
        if crontab -l | grep -q "monitor-production.sh"; then
            log "Monitoring cron job is configured"
        else
            warn "Monitoring cron job is not configured"
        fi
    else
        error "Monitoring script does not exist"
    fi
}

# Validate application health
validate_application() {
    step "Application Health"
    
    if [[ -f "$INSTALL_DIR/docker-compose.production.yml" ]]; then
        log "Production docker-compose file exists"
        
        cd "$INSTALL_DIR"
        
        # Check if containers are running
        if docker-compose -f docker-compose.production.yml ps | grep -q "Up"; then
            log "Production containers are running"
            
            # Check health endpoints
            if curl -f "https://$API_DOMAIN/healthz" > /dev/null 2>&1; then
                log "API health endpoint is responding"
            else
                error "API health endpoint is not responding"
            fi
            
            if curl -f "https://$APP_DOMAIN" > /dev/null 2>&1; then
                log "App is accessible"
            else
                error "App is not accessible"
            fi
        else
            error "Production containers are not running"
        fi
    else
        error "Production docker-compose file does not exist"
    fi
}

# Validate security headers
validate_security_headers() {
    step "Security Headers"
    
    # Test security headers
    HEADERS=$(curl -I "https://$API_DOMAIN" 2>/dev/null)
    
    if echo "$HEADERS" | grep -q "Strict-Transport-Security"; then
        log "HSTS header is present"
    else
        warn "HSTS header is missing"
    fi
    
    if echo "$HEADERS" | grep -q "X-Frame-Options"; then
        log "X-Frame-Options header is present"
    else
        warn "X-Frame-Options header is missing"
    fi
    
    if echo "$HEADERS" | grep -q "X-Content-Type-Options"; then
        log "X-Content-Type-Options header is present"
    else
        warn "X-Content-Type-Options header is missing"
    fi
    
    if echo "$HEADERS" | grep -q "X-XSS-Protection"; then
        log "X-XSS-Protection header is present"
    else
        warn "X-XSS-Protection header is missing"
    fi
}

# Validate log rotation
validate_logs() {
    step "Log Management"
    
    if [[ -f "/etc/logrotate.d/blogcms" ]]; then
        log "Log rotation is configured"
    else
        warn "Log rotation is not configured"
    fi
    
    if [[ -d "$INSTALL_DIR/logs" ]]; then
        log "Log directory exists"
    else
        warn "Log directory does not exist"
    fi
}

# Validate auto-updates
validate_auto_updates() {
    step "Automatic Updates"
    
    if [[ -f "/etc/apt/apt.conf.d/20auto-upgrades" ]]; then
        log "Automatic updates are configured"
    else
        warn "Automatic updates are not configured"
    fi
    
    if systemctl is-enabled --quiet unattended-upgrades; then
        log "Unattended upgrades service is enabled"
    else
        warn "Unattended upgrades service is not enabled"
    fi
}

# Generate report
generate_report() {
    echo ""
    echo -e "${CYAN}Validation Summary:${NC}"
    echo "=================="
    echo -e "${GREEN}Passed: $PASSED${NC}"
    echo -e "${YELLOW}Warnings: $WARNINGS${NC}"
    echo -e "${RED}Failed: $FAILED${NC}"
    
    echo ""
    if [[ $FAILED -eq 0 ]]; then
        echo -e "${GREEN}🎉 Production validation PASSED!${NC}"
        echo -e "${GREEN}Your BlogCMS deployment meets Phase 14 security requirements.${NC}"
        
        if [[ $WARNINGS -gt 0 ]]; then
            echo -e "${YELLOW}Note: Please review the warnings above for optimal security.${NC}"
        fi
    else
        echo -e "${RED}❌ Production validation FAILED!${NC}"
        echo -e "${RED}Please fix the errors above before deploying to production.${NC}"
        exit 1
    fi
}

# Main execution
main() {
    print_header
    get_config
    
    validate_ssl
    validate_firewall
    validate_fail2ban
    validate_environment
    validate_backups
    validate_monitoring
    validate_application
    validate_security_headers
    validate_logs
    validate_auto_updates
    
    generate_report
}

# Run validation
main "$@"
