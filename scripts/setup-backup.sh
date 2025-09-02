#!/bin/bash

# Backup Setup Script
# Configures automated MySQL backups with S3/MinIO storage

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="/etc/mysql-backup"
CONFIG_FILE="$CONFIG_DIR/backup.conf"
CRON_FILE="/etc/cron.d/mysql-backup"

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    error "This script must be run as root (use sudo)"
fi

log "Setting up MySQL backup automation..."

# Create configuration directory
mkdir -p "$CONFIG_DIR"
mkdir -p "/var/backups/mysql"
mkdir -p "/var/log"

# Install required packages
log "Installing required packages..."
apt-get update
apt-get install -y mysql-client mailutils curl

# Install MinIO client
if ! command -v mc &> /dev/null; then
    log "Installing MinIO client..."
    curl -fsSL https://dl.min.io/client/mc/release/linux-amd64/mc -o /usr/local/bin/mc
    chmod +x /usr/local/bin/mc
fi

# Create configuration file
log "Creating backup configuration..."
cat > "$CONFIG_FILE" << 'EOF'
# MySQL Backup Configuration
# Edit this file to customize your backup settings

# Database Configuration
DB_HOST=localhost
DB_PORT=3306
DB_USER=root
DB_PASSWORD=
DB_NAME=blogcms

# Backup Settings
BACKUP_DIR=/var/backups/mysql
COMPRESSION=gzip
ENCRYPTION=false
ENCRYPTION_PASSWORD=

# Retention Policy
DAILY_RETENTION=7
WEEKLY_RETENTION=30
MONTHLY_RETENTION=365

# S3/MinIO Configuration
S3_ENDPOINT=
S3_BUCKET=
S3_ACCESS_KEY=
S3_SECRET_KEY=

# Notification Settings
NOTIFICATION_EMAIL=
SLACK_WEBHOOK=

# Logging
LOG_FILE=/var/log/mysql-backup.log
EOF

# Create wrapper scripts for different backup types
log "Creating backup wrapper scripts..."

# Daily backup script
cat > /usr/local/bin/mysql-backup-daily << EOF
#!/bin/bash
source $CONFIG_FILE
$SCRIPT_DIR/mysql-backup.sh \\
    --type daily \\
    --retention-days \$DAILY_RETENTION \\
    --compression \$COMPRESSION \\
    --backup-dir \$BACKUP_DIR \\
    --db-host \$DB_HOST \\
    --db-port \$DB_PORT \\
    --db-user \$DB_USER \\
    --db-password \$DB_PASSWORD \\
    --db-name \$DB_NAME \\
    --s3-endpoint \$S3_ENDPOINT \\
    --s3-bucket \$S3_BUCKET \\
    --s3-access-key \$S3_ACCESS_KEY \\
    --s3-secret-key \$S3_SECRET_KEY \\
    --email \$NOTIFICATION_EMAIL \\
    --slack-webhook \$SLACK_WEBHOOK
EOF

# Weekly backup script
cat > /usr/local/bin/mysql-backup-weekly << EOF
#!/bin/bash
source $CONFIG_FILE
$SCRIPT_DIR/mysql-backup.sh \\
    --type weekly \\
    --retention-days \$WEEKLY_RETENTION \\
    --compression \$COMPRESSION \\
    --backup-dir \$BACKUP_DIR \\
    --db-host \$DB_HOST \\
    --db-port \$DB_PORT \\
    --db-user \$DB_USER \\
    --db-password \$DB_PASSWORD \\
    --db-name \$DB_NAME \\
    --s3-endpoint \$S3_ENDPOINT \\
    --s3-bucket \$S3_BUCKET \\
    --s3-access-key \$S3_ACCESS_KEY \\
    --s3-secret-key \$S3_SECRET_KEY \\
    --email \$NOTIFICATION_EMAIL \\
    --slack-webhook \$SLACK_WEBHOOK
EOF

# Monthly backup script
cat > /usr/local/bin/mysql-backup-monthly << EOF
#!/bin/bash
source $CONFIG_FILE
$SCRIPT_DIR/mysql-backup.sh \\
    --type monthly \\
    --retention-days \$MONTHLY_RETENTION \\
    --compression \$COMPRESSION \\
    --backup-dir \$BACKUP_DIR \\
    --db-host \$DB_HOST \\
    --db-port \$DB_PORT \\
    --db-user \$DB_USER \\
    --db-password \$DB_PASSWORD \\
    --db-name \$DB_NAME \\
    --s3-endpoint \$S3_ENDPOINT \\
    --s3-bucket \$S3_BUCKET \\
    --s3-access-key \$S3_ACCESS_KEY \\
    --s3-secret-key \$S3_SECRET_KEY \\
    --email \$NOTIFICATION_EMAIL \\
    --slack-webhook \$SLACK_WEBHOOK
EOF

# Make scripts executable
chmod +x /usr/local/bin/mysql-backup-daily
chmod +x /usr/local/bin/mysql-backup-weekly
chmod +x /usr/local/bin/mysql-backup-monthly

# Create backup status script
cat > /usr/local/bin/mysql-backup-status << 'EOF'
#!/bin/bash

# MySQL Backup Status Script
CONFIG_FILE="/etc/mysql-backup/backup.conf"
LOG_FILE="/var/log/mysql-backup.log"

if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
fi

echo "MySQL Backup Status Report"
echo "=========================="
echo "Date: $(date)"
echo ""

echo "Configuration:"
echo "-------------"
echo "Database: ${DB_NAME:-blogcms}@${DB_HOST:-localhost}:${DB_PORT:-3306}"
echo "Backup Directory: ${BACKUP_DIR:-/var/backups/mysql}"
echo "S3/MinIO Bucket: ${S3_BUCKET:-not configured}"
echo "Compression: ${COMPRESSION:-gzip}"
echo "Encryption: ${ENCRYPTION:-false}"
echo ""

echo "Local Backups:"
echo "-------------"
if [[ -d "${BACKUP_DIR:-/var/backups/mysql}" ]]; then
    ls -lah "${BACKUP_DIR:-/var/backups/mysql}"/ | tail -n +2
    echo ""
    echo "Total local backups: $(find "${BACKUP_DIR:-/var/backups/mysql}" -name "*.sql*" | wc -l)"
    echo "Total size: $(du -sh "${BACKUP_DIR:-/var/backups/mysql}" | cut -f1)"
else
    echo "Backup directory not found"
fi
echo ""

echo "Recent Log Entries:"
echo "------------------"
if [[ -f "$LOG_FILE" ]]; then
    tail -n 20 "$LOG_FILE"
else
    echo "Log file not found"
fi
echo ""

echo "Cron Schedule:"
echo "-------------"
if [[ -f "/etc/cron.d/mysql-backup" ]]; then
    cat /etc/cron.d/mysql-backup
else
    echo "Cron schedule not configured"
fi
EOF

chmod +x /usr/local/bin/mysql-backup-status

# Create backup restore script
cat > /usr/local/bin/mysql-backup-restore << 'EOF'
#!/bin/bash

# MySQL Backup Restore Script

set -e

CONFIG_FILE="/etc/mysql-backup/backup.conf"
if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
fi

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"; }
warn() { echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"; }
error() { echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"; exit 1; }

# Parse arguments
BACKUP_FILE=""
DB_NAME_RESTORE="${DB_NAME:-blogcms}"
FORCE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --backup-file)
            BACKUP_FILE="$2"
            shift 2
            ;;
        --database)
            DB_NAME_RESTORE="$2"
            shift 2
            ;;
        --force)
            FORCE=true
            shift
            ;;
        -h|--help)
            echo "MySQL Backup Restore Script"
            echo ""
            echo "Usage: $0 --backup-file FILE [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --backup-file FILE    Path to backup file"
            echo "  --database NAME       Database name to restore to"
            echo "  --force              Skip confirmation prompt"
            echo "  -h, --help           Show this help"
            exit 0
            ;;
        *)
            error "Unknown option: $1"
            ;;
    esac
done

if [[ -z "$BACKUP_FILE" ]]; then
    echo "Available backups:"
    ls -la "${BACKUP_DIR:-/var/backups/mysql}/"
    echo ""
    read -p "Enter backup file path: " BACKUP_FILE
fi

if [[ ! -f "$BACKUP_FILE" ]]; then
    error "Backup file not found: $BACKUP_FILE"
fi

if [[ "$FORCE" != true ]]; then
    warn "This will restore database '$DB_NAME_RESTORE' from backup: $BACKUP_FILE"
    warn "This operation will OVERWRITE the existing database!"
    read -p "Are you sure? (yes/no): " confirm
    if [[ "$confirm" != "yes" ]]; then
        echo "Restore cancelled"
        exit 0
    fi
fi

log "Starting restore process..."

# Determine file type and prepare restore command
if [[ "$BACKUP_FILE" == *.gz ]]; then
    RESTORE_CMD="gunzip -c '$BACKUP_FILE'"
elif [[ "$BACKUP_FILE" == *.xz ]]; then
    RESTORE_CMD="xz -dc '$BACKUP_FILE'"
elif [[ "$BACKUP_FILE" == *.enc ]]; then
    if [[ -z "$ENCRYPTION_PASSWORD" ]]; then
        read -s -p "Enter encryption password: " ENCRYPTION_PASSWORD
        echo
    fi
    RESTORE_CMD="openssl enc -aes-256-cbc -d -salt -in '$BACKUP_FILE' -pass pass:'$ENCRYPTION_PASSWORD'"
else
    RESTORE_CMD="cat '$BACKUP_FILE'"
fi

# Build MySQL command
MYSQL_CMD="mysql -h ${DB_HOST:-localhost} -P ${DB_PORT:-3306} -u ${DB_USER:-root}"
if [[ -n "$DB_PASSWORD" ]]; then
    MYSQL_CMD+=" -p$DB_PASSWORD"
fi

log "Restoring database: $DB_NAME_RESTORE"
eval "$RESTORE_CMD" | eval "$MYSQL_CMD"

if [[ $? -eq 0 ]]; then
    log "Database restored successfully"
else
    error "Restore failed"
fi
EOF

chmod +x /usr/local/bin/mysql-backup-restore

# Set up cron jobs
log "Setting up cron schedule..."
cat > "$CRON_FILE" << 'EOF'
# MySQL Backup Cron Jobs
# Daily backup at 2 AM
0 2 * * * root /usr/local/bin/mysql-backup-daily >/dev/null 2>&1

# Weekly backup on Sunday at 3 AM
0 3 * * 0 root /usr/local/bin/mysql-backup-weekly >/dev/null 2>&1

# Monthly backup on 1st of month at 4 AM
0 4 1 * * root /usr/local/bin/mysql-backup-monthly >/dev/null 2>&1
EOF

# Set proper permissions
chmod 644 "$CONFIG_FILE"
chmod 644 "$CRON_FILE"

# Create logrotate configuration
cat > /etc/logrotate.d/mysql-backup << 'EOF'
/var/log/mysql-backup.log {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    create 0644 root root
}
EOF

# Test configuration
log "Testing backup configuration..."
if ! mysql -h "${DB_HOST:-localhost}" -P "${DB_PORT:-3306}" -u "${DB_USER:-root}" -e "SELECT 1;" >/dev/null 2>&1; then
    warn "Database connection test failed. Please update configuration in $CONFIG_FILE"
else
    log "Database connection test passed"
fi

# Display summary
log "MySQL backup automation setup completed!"
log ""
log "Setup Summary:"
log "=============="
log "✅ Backup scripts installed in /usr/local/bin/"
log "✅ Configuration file: $CONFIG_FILE"
log "✅ Cron schedule: $CRON_FILE"
log "✅ Log rotation configured"
log "✅ MinIO client installed"
log ""
log "Available Commands:"
log "- mysql-backup-daily     (run daily backup)"
log "- mysql-backup-weekly    (run weekly backup)"
log "- mysql-backup-monthly   (run monthly backup)"
log "- mysql-backup-status    (show backup status)"
log "- mysql-backup-restore   (restore from backup)"
log ""
log "Cron Schedule:"
log "- Daily backups: 2:00 AM (7-day retention)"
log "- Weekly backups: Sunday 3:00 AM (30-day retention)"
log "- Monthly backups: 1st of month 4:00 AM (365-day retention)"
log ""
log "Next Steps:"
log "1. Edit configuration: sudo nano $CONFIG_FILE"
log "2. Configure S3/MinIO settings for remote storage"
log "3. Set up email notifications"
log "4. Test backup: sudo mysql-backup-daily"
log "5. Check status: mysql-backup-status"

warn "IMPORTANT: Please edit $CONFIG_FILE to configure your database and S3/MinIO settings!"
