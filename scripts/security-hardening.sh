#!/bin/bash

# Security Hardening Script for Production VPS
# Configures UFW firewall, fail2ban, and basic security measures

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

info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $1${NC}"
}

# Configuration
SSH_PORT=22
ENABLE_IPV6=true
FAIL2BAN_MAXRETRY=5
FAIL2BAN_BANTIME=3600
FAIL2BAN_FINDTIME=600

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --ssh-port)
            SSH_PORT="$2"
            shift 2
            ;;
        --disable-ipv6)
            ENABLE_IPV6=false
            shift
            ;;
        --fail2ban-maxretry)
            FAIL2BAN_MAXRETRY="$2"
            shift 2
            ;;
        --fail2ban-bantime)
            FAIL2BAN_BANTIME="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --ssh-port PORT        SSH port (default: 22)"
            echo "  --disable-ipv6         Disable IPv6 support"
            echo "  --fail2ban-maxretry N  Max retry attempts (default: 5)"
            echo "  --fail2ban-bantime S   Ban time in seconds (default: 3600)"
            echo "  -h, --help            Show this help message"
            exit 0
            ;;
        *)
            error "Unknown option: $1. Use -h for help."
            ;;
    esac
done

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    error "This script must be run as root (use sudo)"
fi

log "Starting security hardening..."
log "SSH Port: $SSH_PORT"
log "IPv6 Enabled: $ENABLE_IPV6"
log "Fail2ban Max Retry: $FAIL2BAN_MAXRETRY"
log "Fail2ban Ban Time: $FAIL2BAN_BANTIME seconds"

# Update system packages
log "Updating system packages..."
apt-get update
apt-get upgrade -y

# Install required packages
log "Installing security packages..."
apt-get install -y ufw fail2ban unattended-upgrades apt-listchanges

# Configure UFW (Uncomplicated Firewall)
log "Configuring UFW firewall..."

# Reset UFW to defaults
ufw --force reset

# Set default policies
ufw default deny incoming
ufw default allow outgoing

# Allow SSH (with custom port if specified)
if [[ $SSH_PORT -ne 22 ]]; then
    ufw allow $SSH_PORT/tcp comment 'SSH custom port'
    warn "Remember to update your SSH configuration to use port $SSH_PORT"
else
    ufw allow ssh comment 'SSH default port'
fi

# Allow HTTP and HTTPS
ufw allow 80/tcp comment 'HTTP'
ufw allow 443/tcp comment 'HTTPS'

# Configure IPv6 if enabled
if [[ "$ENABLE_IPV6" == true ]]; then
    sed -i 's/IPV6=no/IPV6=yes/' /etc/default/ufw
    log "IPv6 support enabled"
else
    sed -i 's/IPV6=yes/IPV6=no/' /etc/default/ufw
    log "IPv6 support disabled"
fi

# Enable UFW
log "Enabling UFW firewall..."
ufw --force enable

# Show UFW status
log "UFW firewall status:"
ufw status verbose

# Configure fail2ban
log "Configuring fail2ban..."

# Create jail.local configuration
cat > /etc/fail2ban/jail.local << EOF
[DEFAULT]
# Ban settings
bantime = $FAIL2BAN_BANTIME
findtime = $FAIL2BAN_FINDTIME
maxretry = $FAIL2BAN_MAXRETRY

# Email notifications (configure if needed)
# destemail = admin@example.com
# sender = fail2ban@example.com
# mta = sendmail

# Default action
action = %(action_)s

[sshd]
enabled = true
port = $SSH_PORT
logpath = %(sshd_log)s
backend = %(sshd_backend)s
maxretry = $FAIL2BAN_MAXRETRY
bantime = $FAIL2BAN_BANTIME

[nginx-http-auth]
enabled = true
filter = nginx-http-auth
logpath = /var/log/nginx/error.log
maxretry = 3
bantime = 1800

[nginx-noscript]
enabled = true
filter = nginx-noscript
logpath = /var/log/nginx/access.log
maxretry = 6
bantime = 86400

[nginx-badbots]
enabled = true
filter = nginx-badbots
logpath = /var/log/nginx/access.log
maxretry = 2
bantime = 86400

[nginx-noproxy]
enabled = true
filter = nginx-noproxy
logpath = /var/log/nginx/access.log
maxretry = 2
bantime = 86400

[nginx-limit-req]
enabled = true
filter = nginx-limit-req
logpath = /var/log/nginx/error.log
maxretry = 10
bantime = 3600

[recidive]
enabled = true
filter = recidive
logpath = /var/log/fail2ban.log
action = %(action_mwl)s
bantime = 604800  ; 1 week
findtime = 86400   ; 1 day
maxretry = 5
EOF

# Create custom nginx filters for fail2ban
log "Creating custom fail2ban filters..."

# BlogCMS API rate limiting filter
cat > /etc/fail2ban/filter.d/nginx-blogcms-api.conf << 'EOF'
# Fail2ban filter for BlogCMS API abuse
[Definition]
failregex = ^<HOST>.*"(GET|POST|PUT|DELETE) /api/.*" (429|403) .*$
            ^<HOST>.*"(GET|POST|PUT|DELETE) /api/v1/auth/.*" 401 .*$
ignoreregex =
EOF

# Add BlogCMS API jail
cat >> /etc/fail2ban/jail.local << EOF

[nginx-blogcms-api]
enabled = true
filter = nginx-blogcms-api
logpath = /var/log/nginx/access.log
maxretry = 10
bantime = 3600
findtime = 300
EOF

# Start and enable fail2ban
systemctl enable fail2ban
systemctl start fail2ban
systemctl reload fail2ban

log "Fail2ban status:"
fail2ban-client status

# Configure automatic security updates
log "Configuring automatic security updates..."

cat > /etc/apt/apt.conf.d/20auto-upgrades << EOF
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "1";
EOF

cat > /etc/apt/apt.conf.d/50unattended-upgrades << EOF
Unattended-Upgrade::Allowed-Origins {
    "\${distro_id}:\${distro_codename}";
    "\${distro_id}:\${distro_codename}-security";
    "\${distro_id}ESMApps:\${distro_codename}-apps-security";
    "\${distro_id}ESM:\${distro_codename}-infra-security";
};

Unattended-Upgrade::Package-Blacklist {
    // "vim";
    // "libc6-dev";
    // "mysql-server";
};

Unattended-Upgrade::AutoFixInterruptedDpkg "true";
Unattended-Upgrade::MinimalSteps "true";
Unattended-Upgrade::InstallOnShutdown "false";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Remove-New-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "false";
Unattended-Upgrade::Automatic-Reboot-WithUsers "false";
Unattended-Upgrade::Automatic-Reboot-Time "02:00";

Unattended-Upgrade::Mail "root";
Unattended-Upgrade::MailOnlyOnError "true";
EOF

# Configure SSH hardening
log "Hardening SSH configuration..."

# Backup original SSH config
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup

# Create hardened SSH configuration
cat > /etc/ssh/sshd_config << EOF
# SSH Hardened Configuration for BlogCMS Production

# Network
Port $SSH_PORT
AddressFamily inet
ListenAddress 0.0.0.0

# Protocol
Protocol 2

# Authentication
LoginGraceTime 30
PermitRootLogin no
StrictModes yes
MaxAuthTries 3
MaxSessions 2
MaxStartups 2

# Public key authentication
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys

# Password authentication (disabled for security)
PasswordAuthentication no
PermitEmptyPasswords no
ChallengeResponseAuthentication no
KerberosAuthentication no
GSSAPIAuthentication no

# X11 forwarding
X11Forwarding no

# Other options
PermitUserEnvironment no
AllowTcpForwarding no
AllowStreamLocalForwarding no
GatewayPorts no
PermitTunnel no
PrintMotd no
PrintLastLog yes
TCPKeepAlive yes
ClientAliveInterval 300
ClientAliveCountMax 2

# Logging
SyslogFacility AUTH
LogLevel INFO

# Ciphers and algorithms (secure)
KexAlgorithms curve25519-sha256@libssh.org,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr
MACs hmac-sha2-256-etm@openssh.com,hmac-sha2-512-etm@openssh.com,hmac-sha2-256,hmac-sha2-512

# Override for some broken clients
# Ciphers +aes128-cbc,aes192-cbc,aes256-cbc

# Banner
Banner /etc/ssh/banner
EOF

# Create SSH banner
cat > /etc/ssh/banner << 'EOF'
********************************************************************************
*                              AUTHORIZED ACCESS ONLY                         *
********************************************************************************
*                                                                              *
*  This system is for authorized users only. All activities are monitored     *
*  and logged. Unauthorized access is strictly prohibited and will be         *
*  prosecuted to the full extent of the law.                                  *
*                                                                              *
*  BlogCMS Production Server                                                   *
*                                                                              *
********************************************************************************
EOF

# Test SSH configuration
log "Testing SSH configuration..."
sshd -t
if [[ $? -eq 0 ]]; then
    log "SSH configuration test passed"
    systemctl reload ssh
    log "SSH service reloaded"
else
    error "SSH configuration test failed - restoring backup"
    cp /etc/ssh/sshd_config.backup /etc/ssh/sshd_config
    systemctl reload ssh
fi

# Configure kernel security parameters
log "Configuring kernel security parameters..."

cat > /etc/sysctl.d/99-security.conf << EOF
# Network security
net.ipv4.ip_forward = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.default.secure_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0
net.ipv6.conf.default.accept_source_route = 0

# ICMP redirects
net.ipv4.conf.all.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0

# Log suspicious packets
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1

# Ignore ping requests
net.ipv4.icmp_echo_ignore_all = 0
net.ipv4.icmp_echo_ignore_broadcasts = 1

# Ignore bogus ICMP responses
net.ipv4.icmp_ignore_bogus_error_responses = 1

# SYN flood protection
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 2048
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_syn_retries = 5

# Memory protection
kernel.dmesg_restrict = 1
kernel.kptr_restrict = 2
kernel.yama.ptrace_scope = 1

# Filesystem protection
fs.protected_hardlinks = 1
fs.protected_symlinks = 1
fs.suid_dumpable = 0
EOF

# Apply sysctl settings
sysctl -p /etc/sysctl.d/99-security.conf

# Create security monitoring script
log "Creating security monitoring script..."

cat > /usr/local/bin/security-monitor.sh << 'EOF'
#!/bin/bash

# Security Monitoring Script
# Checks for security issues and sends alerts

LOGFILE="/var/log/security-monitor.log"
NOTIFICATION_EMAIL="${ADMIN_EMAIL:-admin@localhost}"

log_with_timestamp() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" >> "$LOGFILE"
}

check_failed_logins() {
    local failed_count
    failed_count=$(journalctl --since "1 hour ago" | grep "Failed password" | wc -l)
    
    if [[ $failed_count -gt 10 ]]; then
        log_with_timestamp "WARNING: $failed_count failed login attempts in the last hour"
        if command -v mail &> /dev/null; then
            echo "WARNING: $failed_count failed login attempts detected in the last hour" | \
                mail -s "Security Alert: Failed Login Attempts" "$NOTIFICATION_EMAIL"
        fi
    fi
}

check_disk_usage() {
    local disk_usage
    disk_usage=$(df / | awk 'NR==2{print $5}' | sed 's/%//')
    
    if [[ $disk_usage -gt 90 ]]; then
        log_with_timestamp "WARNING: Disk usage is at ${disk_usage}%"
        if command -v mail &> /dev/null; then
            echo "WARNING: Disk usage is at ${disk_usage}%" | \
                mail -s "Security Alert: High Disk Usage" "$NOTIFICATION_EMAIL"
        fi
    fi
}

check_memory_usage() {
    local memory_usage
    memory_usage=$(free | grep Mem | awk '{printf("%.0f", $3/$2 * 100.0)}')
    
    if [[ $memory_usage -gt 90 ]]; then
        log_with_timestamp "WARNING: Memory usage is at ${memory_usage}%"
        if command -v mail &> /dev/null; then
            echo "WARNING: Memory usage is at ${memory_usage}%" | \
                mail -s "Security Alert: High Memory Usage" "$NOTIFICATION_EMAIL"
        fi
    fi
}

check_suspicious_processes() {
    local suspicious_processes
    suspicious_processes=$(ps aux | grep -E "(nc|netcat|nmap|nikto|sqlmap)" | grep -v grep)
    
    if [[ -n "$suspicious_processes" ]]; then
        log_with_timestamp "WARNING: Suspicious processes detected: $suspicious_processes"
        if command -v mail &> /dev/null; then
            echo "WARNING: Suspicious processes detected: $suspicious_processes" | \
                mail -s "Security Alert: Suspicious Processes" "$NOTIFICATION_EMAIL"
        fi
    fi
}

# Run checks
check_failed_logins
check_disk_usage
check_memory_usage
check_suspicious_processes

# Clean up old logs (keep 30 days)
find /var/log -name "*.log" -mtime +30 -delete 2>/dev/null || true
EOF

chmod +x /usr/local/bin/security-monitor.sh

# Set up security monitoring cron
cat > /etc/cron.d/security-monitoring << 'EOF'
# Security monitoring
# Run every hour
0 * * * * root /usr/local/bin/security-monitor.sh
EOF

# Create daily security report
cat > /usr/local/bin/daily-security-report.sh << 'EOF'
#!/bin/bash

# Daily Security Report
REPORT_FILE="/tmp/security-report-$(date +%Y%m%d).txt"
NOTIFICATION_EMAIL="${ADMIN_EMAIL:-admin@localhost}"

{
    echo "Daily Security Report - $(date)"
    echo "================================"
    echo ""
    
    echo "System Information:"
    echo "-------------------"
    echo "Hostname: $(hostname)"
    echo "Uptime: $(uptime)"
    echo "Load: $(cat /proc/loadavg)"
    echo "Memory: $(free -h | grep Mem)"
    echo "Disk: $(df -h / | tail -1)"
    echo ""
    
    echo "UFW Status:"
    echo "----------"
    ufw status numbered
    echo ""
    
    echo "Fail2ban Status:"
    echo "---------------"
    fail2ban-client status
    echo ""
    
    echo "Failed Login Attempts (Last 24h):"
    echo "---------------------------------"
    journalctl --since "24 hours ago" | grep "Failed password" | wc -l
    echo ""
    
    echo "Active Fail2ban Bans:"
    echo "--------------------"
    fail2ban-client status sshd | grep "Banned IP list"
    echo ""
    
    echo "System Updates Available:"
    echo "------------------------"
    apt list --upgradable 2>/dev/null | wc -l
    echo ""
    
    echo "SSL Certificate Status:"
    echo "----------------------"
    if [[ -f /usr/local/bin/check-ssl-expiry.sh ]]; then
        /usr/local/bin/check-ssl-expiry.sh
    else
        echo "SSL monitoring not configured"
    fi
    
} > "$REPORT_FILE"

# Send report via email if mail is configured
if command -v mail &> /dev/null; then
    mail -s "Daily Security Report - $(hostname)" "$NOTIFICATION_EMAIL" < "$REPORT_FILE"
fi

# Keep reports for 7 days
find /tmp -name "security-report-*.txt" -mtime +7 -delete 2>/dev/null || true
EOF

chmod +x /usr/local/bin/daily-security-report.sh

# Set up daily security report cron
cat > /etc/cron.d/daily-security-report << 'EOF'
# Daily security report
# Run at 6 AM every day
0 6 * * * root /usr/local/bin/daily-security-report.sh
EOF

# Display summary
log "Security hardening completed successfully!"
log ""
log "Security Configuration Summary:"
log "==============================="
log "✅ UFW Firewall: Enabled (ports 22, 80, 443)"
log "✅ Fail2ban: Configured with SSH and Nginx protection"
log "✅ SSH: Hardened configuration (no root, no passwords)"
log "✅ Automatic Updates: Enabled for security patches"
log "✅ Kernel Security: Enhanced network security parameters"
log "✅ Monitoring: Hourly security checks and daily reports"
log ""
log "Important Notes:"
log "- SSH port: $SSH_PORT"
log "- Only key-based authentication allowed"
log "- Root login disabled"
log "- Automatic security updates enabled"
log "- Security monitoring active"
log ""
log "Next Steps:"
log "1. Configure SSH key authentication"
log "2. Test firewall rules"
log "3. Monitor fail2ban logs: journalctl -u fail2ban"
log "4. Review security reports in /var/log/security-monitor.log"
log "5. Configure email notifications for alerts"

warn "IMPORTANT: Make sure you have SSH key access before disconnecting!"
warn "Password authentication has been disabled."
