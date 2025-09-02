#!/bin/bash

# SSL Setup Script with Let's Encrypt
# This script sets up SSL certificates for production deployment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

# Configuration
DOMAINS=""
EMAIL=""
STAGING=false
FORCE_RENEWAL=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--domains)
            DOMAINS="$2"
            shift 2
            ;;
        -e|--email)
            EMAIL="$2"
            shift 2
            ;;
        --staging)
            STAGING=true
            shift
            ;;
        --force)
            FORCE_RENEWAL=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 -d 'api.domain.com,app.domain.com' -e 'admin@domain.com' [--staging] [--force]"
            echo ""
            echo "Options:"
            echo "  -d, --domains     Comma-separated list of domains"
            echo "  -e, --email       Email address for Let's Encrypt"
            echo "  --staging         Use Let's Encrypt staging environment"
            echo "  --force           Force certificate renewal"
            echo "  -h, --help        Show this help message"
            exit 0
            ;;
        *)
            error "Unknown option: $1. Use -h for help."
            ;;
    esac
done

# Validate required parameters
if [[ -z "$DOMAINS" ]]; then
    error "Domains are required. Use -d option."
fi

if [[ -z "$EMAIL" ]]; then
    error "Email is required. Use -e option."
fi

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    error "This script must be run as root (use sudo)"
fi

log "Starting SSL setup for domains: $DOMAINS"
log "Email: $EMAIL"
log "Staging mode: $STAGING"

# Install certbot if not present
if ! command -v certbot &> /dev/null; then
    log "Installing certbot..."
    apt-get update
    apt-get install -y certbot python3-certbot-nginx
fi

# Create SSL directories
mkdir -p /etc/nginx/ssl
mkdir -p /var/log/letsencrypt

# Convert comma-separated domains to array
IFS=',' read -ra DOMAIN_ARRAY <<< "$DOMAINS"

# Build certbot command
CERTBOT_CMD="certbot --nginx"

if [[ "$STAGING" == true ]]; then
    CERTBOT_CMD+=" --staging"
    warn "Using staging environment - certificates will not be trusted by browsers"
fi

if [[ "$FORCE_RENEWAL" == true ]]; then
    CERTBOT_CMD+=" --force-renewal"
fi

CERTBOT_CMD+=" --email $EMAIL --agree-tos --non-interactive"

# Add domains to certbot command
for domain in "${DOMAIN_ARRAY[@]}"; do
    domain=$(echo "$domain" | xargs) # trim whitespace
    CERTBOT_CMD+=" -d $domain"
done

log "Running certbot command..."
log "Command: $CERTBOT_CMD"

# Run certbot
if $CERTBOT_CMD; then
    log "SSL certificates obtained successfully!"
else
    error "Failed to obtain SSL certificates"
fi

# Set up automatic renewal
log "Setting up automatic renewal..."

# Create renewal script
cat > /etc/cron.d/certbot-renewal << 'EOF'
# Let's Encrypt automatic renewal
# Runs twice a day at random times to renew certificates
0 */12 * * * root /usr/bin/certbot renew --quiet --post-hook "systemctl reload nginx"

# Clean up old log files (keep 30 days)
0 2 * * 0 root find /var/log/letsencrypt -name "*.log" -mtime +30 -delete
EOF

# Create renewal monitoring script
cat > /usr/local/bin/check-ssl-expiry.sh << 'EOF'
#!/bin/bash

# SSL Certificate Expiry Check Script
# Checks certificate expiry and sends alerts if needed

NOTIFICATION_EMAIL="${ADMIN_EMAIL:-admin@localhost}"
WARNING_DAYS=30
CRITICAL_DAYS=7

check_domain() {
    local domain=$1
    local expiry_date
    local days_until_expiry
    
    # Get certificate expiry date
    expiry_date=$(echo | openssl s_client -servername "$domain" -connect "$domain:443" 2>/dev/null | \
                  openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2)
    
    if [[ -z "$expiry_date" ]]; then
        echo "ERROR: Could not retrieve certificate for $domain"
        return 1
    fi
    
    # Calculate days until expiry
    expiry_epoch=$(date -d "$expiry_date" +%s)
    current_epoch=$(date +%s)
    days_until_expiry=$(( (expiry_epoch - current_epoch) / 86400 ))
    
    echo "Domain: $domain - Expires in $days_until_expiry days ($expiry_date)"
    
    # Check if renewal is needed
    if [[ $days_until_expiry -le $CRITICAL_DAYS ]]; then
        echo "CRITICAL: SSL certificate for $domain expires in $days_until_expiry days!"
        # Send critical alert
        if command -v mail &> /dev/null; then
            echo "CRITICAL: SSL certificate for $domain expires in $days_until_expiry days!" | \
                mail -s "CRITICAL: SSL Certificate Expiry - $domain" "$NOTIFICATION_EMAIL"
        fi
    elif [[ $days_until_expiry -le $WARNING_DAYS ]]; then
        echo "WARNING: SSL certificate for $domain expires in $days_until_expiry days"
        # Send warning
        if command -v mail &> /dev/null; then
            echo "WARNING: SSL certificate for $domain expires in $days_until_expiry days" | \
                mail -s "WARNING: SSL Certificate Expiry - $domain" "$NOTIFICATION_EMAIL"
        fi
    fi
    
    return 0
}

# Check all domains
for domain in "${DOMAIN_ARRAY[@]}"; do
    check_domain "$domain"
done
EOF

chmod +x /usr/local/bin/check-ssl-expiry.sh

# Set up SSL monitoring cron
cat > /etc/cron.d/ssl-monitoring << 'EOF'
# SSL Certificate monitoring
# Check certificate expiry daily at 9 AM
0 9 * * * root /usr/local/bin/check-ssl-expiry.sh
EOF

# Test nginx configuration
log "Testing nginx configuration..."
if nginx -t; then
    log "Nginx configuration is valid"
    systemctl reload nginx
    log "Nginx reloaded successfully"
else
    error "Nginx configuration test failed"
fi

# Create SSL configuration snippet
cat > /etc/nginx/snippets/ssl-params.conf << 'EOF'
# SSL Configuration
ssl_protocols TLSv1.2 TLSv1.3;
ssl_prefer_server_ciphers on;
ssl_dhparam /etc/nginx/ssl/dhparam.pem;
ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-SHA384;
ssl_ecdh_curve secp384r1;
ssl_session_timeout 10m;
ssl_session_cache shared:SSL:10m;
ssl_session_tickets off;
ssl_stapling on;
ssl_stapling_verify on;

# Security headers
add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload" always;
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-XSS-Protection "1; mode=block" always;
add_header Referrer-Policy "strict-origin-when-cross-origin" always;
add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; font-src 'self' data:; connect-src 'self'; frame-ancestors 'none';" always;

# OCSP stapling
resolver 8.8.8.8 8.8.4.4 valid=300s;
resolver_timeout 5s;
EOF

# Generate dhparam if it doesn't exist
if [[ ! -f /etc/nginx/ssl/dhparam.pem ]]; then
    log "Generating DH parameters (this may take a while)..."
    openssl dhparam -out /etc/nginx/ssl/dhparam.pem 2048
    log "DH parameters generated"
fi

# Test certificate renewal
log "Testing certificate renewal..."
if certbot renew --dry-run; then
    log "Certificate renewal test passed"
else
    warn "Certificate renewal test failed - please check configuration"
fi

# Display SSL test information
log "SSL setup completed successfully!"
log ""
log "Next steps:"
log "1. Test your SSL configuration at: https://www.ssllabs.com/ssltest/"
log "2. Check certificate expiry with: /usr/local/bin/check-ssl-expiry.sh"
log "3. Monitor renewal logs at: /var/log/letsencrypt/"
log ""
log "SSL Grade A+ Configuration:"
log "- TLS 1.2+ only"
log "- Strong cipher suites"
log "- HSTS enabled with preload"
log "- OCSP stapling enabled"
log "- Security headers configured"
log ""
log "Automatic renewal:"
log "- Certificates will be renewed automatically"
log "- Renewal attempts twice daily"
log "- Nginx will be reloaded after renewal"
log "- SSL monitoring runs daily at 9 AM"

# Final security recommendations
log ""
log "Security Recommendations:"
log "1. Ensure firewall (UFW) is configured"
log "2. Set up fail2ban for SSH protection"
log "3. Configure log monitoring"
log "4. Regular security updates"
log "5. Monitor SSL Labs rating"
