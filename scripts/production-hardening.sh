#!/bin/bash

# Production Hardening Script for BlogCMS VPS Deployment
# Phase 14 - Hardening & Production Checklist

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
APP_DOMAIN=""
API_DOMAIN=""
EMAIL=""
BACKUP_RETENTION_DAYS=30
S3_BUCKET=""
AWS_ACCESS_KEY_ID=""
AWS_SECRET_ACCESS_KEY=""
AWS_REGION="us-east-1"

print_header() {
    echo -e "${PURPLE}"
    echo "╔══════════════════════════════════════════════════════════════════════════════╗"
    echo "║                         BlogCMS Production Hardening                        ║"
    echo "║                     Phase 14 - Security & Stability                         ║"
    echo "╚══════════════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Check if running as non-root
check_user() {
    if [[ $EUID -eq 0 ]]; then
        error "This script should not be run as root for security reasons"
    fi
}

# Get configuration from user
get_configuration() {
    step "Getting Configuration"
    
    read -p "Enter your main domain (e.g., example.com): " DOMAIN
    if [[ -z "$DOMAIN" ]]; then
        error "Domain is required"
    fi
    
    read -p "Enter API subdomain (e.g., api): " api_subdomain
    API_DOMAIN="${api_subdomain:-api}.${DOMAIN}"
    
    read -p "Enter App subdomain (e.g., app): " app_subdomain
    APP_DOMAIN="${app_subdomain:-app}.${DOMAIN}"
    
    read -p "Enter your email for Let's Encrypt: " EMAIL
    if [[ -z "$EMAIL" ]]; then
        error "Email is required for Let's Encrypt"
    fi
    
    echo ""
    echo "Configuration Summary:"
    echo "  API Domain: $API_DOMAIN"
    echo "  App Domain: $APP_DOMAIN"
    echo "  Email: $EMAIL"
    echo ""
    
    read -p "Is this configuration correct? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        error "Configuration cancelled"
    fi
}

# Configure S3 backup (optional)
configure_s3_backup() {
    step "S3 Backup Configuration (Optional)"
    
    read -p "Do you want to configure S3 backup? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        read -p "Enter S3 bucket name: " S3_BUCKET
        read -p "Enter AWS Access Key ID: " AWS_ACCESS_KEY_ID
        read -s -p "Enter AWS Secret Access Key: " AWS_SECRET_ACCESS_KEY
        echo
        read -p "Enter AWS Region (default: us-east-1): " aws_region
        AWS_REGION="${aws_region:-us-east-1}"
        
        read -p "Enter backup retention days (default: 30): " retention
        BACKUP_RETENTION_DAYS="${retention:-30}"
        
        log "S3 backup configured"
    else
        log "Skipping S3 backup configuration"
    fi
}

# Install required packages
install_packages() {
    step "Installing Required Packages"
    
    # Update system
    sudo apt update
    
    # Install security packages
    sudo apt install -y \
        ufw \
        fail2ban \
        unattended-upgrades \
        apt-listchanges \
        software-properties-common \
        certbot \
        python3-certbot-nginx \
        awscli \
        logrotate \
        rsyslog \
        htop \
        iotop \
        netstat-nat \
        tcpdump
    
    log "Required packages installed"
}

# Configure UFW Firewall
configure_firewall() {
    step "Configuring UFW Firewall"
    
    # Reset UFW to defaults
    sudo ufw --force reset
    
    # Set default policies
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    
    # Allow specific ports
    sudo ufw allow 22/tcp    # SSH
    sudo ufw allow 80/tcp    # HTTP
    sudo ufw allow 443/tcp   # HTTPS
    
    # Rate limit SSH
    sudo ufw limit ssh
    
    # Enable UFW
    sudo ufw --force enable
    
    log "UFW firewall configured and enabled"
}

# Configure Fail2Ban
configure_fail2ban() {
    step "Configuring Fail2Ban"
    
    # Create custom jail configuration
    sudo tee /etc/fail2ban/jail.local > /dev/null <<EOF
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5
backend = auto

[sshd]
enabled = true
port = ssh
logpath = /var/log/auth.log
maxretry = 3
bantime = 7200

[nginx-http-auth]
enabled = true
filter = nginx-http-auth
port = http,https
logpath = /var/log/nginx/error.log

[nginx-noscript]
enabled = true
port = http,https
filter = nginx-noscript
logpath = /var/log/nginx/access.log
maxretry = 6

[nginx-badbots]
enabled = true
port = http,https
filter = nginx-badbots
logpath = /var/log/nginx/access.log
maxretry = 2

[nginx-noproxy]
enabled = true
port = http,https
filter = nginx-noproxy
logpath = /var/log/nginx/access.log
maxretry = 2
EOF

    # Create custom filters for nginx
    sudo tee /etc/fail2ban/filter.d/nginx-noscript.conf > /dev/null <<EOF
[Definition]
failregex = ^<HOST> -.*GET.*(\.php|\.asp|\.exe|\.pl|\.cgi|\.scgi)
ignoreregex =
EOF

    sudo tee /etc/fail2ban/filter.d/nginx-badbots.conf > /dev/null <<EOF
[Definition]
failregex = ^<HOST> -.*"(GET|POST).*HTTP.*".*".*Nikto.*|.*python.*|.*curl.*|.*wget.*"$
ignoreregex =
EOF

    sudo tee /etc/fail2ban/filter.d/nginx-noproxy.conf > /dev/null <<EOF
[Definition]
failregex = ^<HOST> -.*GET http.*
ignoreregex =
EOF

    # Restart fail2ban
    sudo systemctl restart fail2ban
    sudo systemctl enable fail2ban
    
    log "Fail2Ban configured and enabled"
}

# Configure automatic security updates
configure_auto_updates() {
    step "Configuring Automatic Security Updates"
    
    # Configure unattended-upgrades
    sudo tee /etc/apt/apt.conf.d/20auto-upgrades > /dev/null <<EOF
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "1";
EOF

    # Configure which updates to install
    sudo tee /etc/apt/apt.conf.d/50unattended-upgrades > /dev/null <<EOF
Unattended-Upgrade::Allowed-Origins {
    "\${distro_id}:\${distro_codename}";
    "\${distro_id}:\${distro_codename}-security";
    "\${distro_id}ESMApps:\${distro_codename}-apps-security";
    "\${distro_id}ESM:\${distro_codename}-infra-security";
};

Unattended-Upgrade::AutoFixInterruptedDpkg "true";
Unattended-Upgrade::MinimalSteps "true";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "false";
Unattended-Upgrade::Mail "$EMAIL";
EOF

    log "Automatic security updates configured"
}

# Generate Let's Encrypt SSL certificates
generate_ssl_certificates() {
    step "Generating Let's Encrypt SSL Certificates"
    
    # Stop nginx if running
    sudo systemctl stop nginx 2>/dev/null || true
    
    # Generate certificate for API domain
    log "Generating certificate for $API_DOMAIN"
    sudo certbot certonly --standalone --non-interactive --agree-tos --email "$EMAIL" -d "$API_DOMAIN"
    
    # Generate certificate for App domain
    log "Generating certificate for $APP_DOMAIN"
    sudo certbot certonly --standalone --non-interactive --agree-tos --email "$EMAIL" -d "$APP_DOMAIN"
    
    # Setup auto-renewal
    echo "0 12 * * * /usr/bin/certbot renew --quiet" | sudo crontab -
    
    log "SSL certificates generated and auto-renewal configured"
}

# Configure log rotation
configure_log_rotation() {
    step "Configuring Log Rotation"
    
    # Create logrotate configuration for application logs
    sudo tee /etc/logrotate.d/blogcms > /dev/null <<EOF
/opt/blogcms/logs/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    copytruncate
    postrotate
        docker-compose -f /opt/blogcms/docker-compose.yml restart nginx 2>/dev/null || true
    endscript
}

/var/log/nginx/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    sharedscripts
    postrotate
        systemctl reload nginx 2>/dev/null || true
    endscript
}
EOF

    log "Log rotation configured"
}

# Main execution
main() {
    print_header
    
    check_user
    get_configuration
    configure_s3_backup
    install_packages
    configure_firewall
    configure_fail2ban
    configure_auto_updates
    generate_ssl_certificates
    configure_log_rotation
    
    log "Production hardening completed successfully!"
    
    echo ""
    echo -e "${CYAN}Next Steps:${NC}"
    echo "1. Update DNS records to point $API_DOMAIN and $APP_DOMAIN to this server"
    echo "2. Run ./production-setup.sh to deploy the application"
    echo "3. Test SSL certificates: https://www.ssllabs.com/ssltest/"
    echo "4. Monitor fail2ban: sudo fail2ban-client status"
    echo "5. Check firewall: sudo ufw status"
    
    echo ""
    echo -e "${GREEN}Production hardening completed! Your server is now secured.${NC}"
}

# Run main function
main "$@"
