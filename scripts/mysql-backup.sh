#!/bin/bash

# MySQL Backup Script with S3/MinIO Support
# Performs automated backups with compression, encryption, and retention management

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
    logger -t mysql-backup "$1"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
    logger -t mysql-backup -p user.warning "WARNING: $1"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
    logger -t mysql-backup -p user.err "ERROR: $1"
    exit 1
}

info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $1${NC}"
    logger -t mysql-backup -p user.info "INFO: $1"
}

# Default configuration
BACKUP_TYPE="daily"
RETENTION_DAYS=7
COMPRESSION="gzip"
ENCRYPTION=false
ENCRYPTION_PASSWORD=""
S3_ENDPOINT=""
S3_BUCKET=""
S3_ACCESS_KEY=""
S3_SECRET_KEY=""
NOTIFICATION_EMAIL=""
SLACK_WEBHOOK=""
BACKUP_DIR="/var/backups/mysql"
LOG_FILE="/var/log/mysql-backup.log"

# Database configuration (from environment or config)
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-3306}"
DB_USER="${DB_USER:-root}"
DB_PASSWORD="${DB_PASSWORD:-}"
DB_NAME="${DB_NAME:-blogcms}"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --type)
            BACKUP_TYPE="$2"
            shift 2
            ;;
        --retention-days)
            RETENTION_DAYS="$2"
            shift 2
            ;;
        --compression)
            COMPRESSION="$2"
            shift 2
            ;;
        --encryption)
            ENCRYPTION=true
            ENCRYPTION_PASSWORD="$2"
            shift 2
            ;;
        --s3-endpoint)
            S3_ENDPOINT="$2"
            shift 2
            ;;
        --s3-bucket)
            S3_BUCKET="$2"
            shift 2
            ;;
        --s3-access-key)
            S3_ACCESS_KEY="$2"
            shift 2
            ;;
        --s3-secret-key)
            S3_SECRET_KEY="$2"
            shift 2
            ;;
        --email)
            NOTIFICATION_EMAIL="$2"
            shift 2
            ;;
        --slack-webhook)
            SLACK_WEBHOOK="$2"
            shift 2
            ;;
        --backup-dir)
            BACKUP_DIR="$2"
            shift 2
            ;;
        --db-host)
            DB_HOST="$2"
            shift 2
            ;;
        --db-port)
            DB_PORT="$2"
            shift 2
            ;;
        --db-user)
            DB_USER="$2"
            shift 2
            ;;
        --db-password)
            DB_PASSWORD="$2"
            shift 2
            ;;
        --db-name)
            DB_NAME="$2"
            shift 2
            ;;
        --config)
            CONFIG_FILE="$2"
            if [[ -f "$CONFIG_FILE" ]]; then
                source "$CONFIG_FILE"
            else
                error "Configuration file not found: $CONFIG_FILE"
            fi
            shift 2
            ;;
        -h|--help)
            echo "MySQL Backup Script with S3/MinIO Support"
            echo ""
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Backup Options:"
            echo "  --type TYPE               Backup type: daily, weekly, monthly (default: daily)"
            echo "  --retention-days DAYS     Retention period in days (default: 7)"
            echo "  --compression TYPE        Compression: gzip, xz, none (default: gzip)"
            echo "  --encryption PASSWORD     Enable encryption with password"
            echo "  --backup-dir DIR          Local backup directory (default: /var/backups/mysql)"
            echo ""
            echo "S3/MinIO Options:"
            echo "  --s3-endpoint URL         S3/MinIO endpoint URL"
            echo "  --s3-bucket BUCKET        S3/MinIO bucket name"
            echo "  --s3-access-key KEY       S3/MinIO access key"
            echo "  --s3-secret-key SECRET    S3/MinIO secret key"
            echo ""
            echo "Database Options:"
            echo "  --db-host HOST            Database host (default: localhost)"
            echo "  --db-port PORT            Database port (default: 3306)"
            echo "  --db-user USER            Database user (default: root)"
            echo "  --db-password PASSWORD    Database password"
            echo "  --db-name DATABASE        Database name (default: blogcms)"
            echo ""
            echo "Notification Options:"
            echo "  --email EMAIL             Email for notifications"
            echo "  --slack-webhook URL       Slack webhook for notifications"
            echo ""
            echo "Other Options:"
            echo "  --config FILE             Load configuration from file"
            echo "  -h, --help               Show this help message"
            echo ""
            echo "Environment Variables:"
            echo "  DB_HOST, DB_PORT, DB_USER, DB_PASSWORD, DB_NAME"
            echo "  S3_ENDPOINT, S3_BUCKET, S3_ACCESS_KEY, S3_SECRET_KEY"
            echo "  NOTIFICATION_EMAIL, SLACK_WEBHOOK"
            exit 0
            ;;
        *)
            error "Unknown option: $1. Use -h for help."
            ;;
    esac
done

# Load configuration from environment if not provided
S3_ENDPOINT="${S3_ENDPOINT:-$S3_ENDPOINT_ENV}"
S3_BUCKET="${S3_BUCKET:-$S3_BUCKET_ENV}"
S3_ACCESS_KEY="${S3_ACCESS_KEY:-$S3_ACCESS_KEY_ENV}"
S3_SECRET_KEY="${S3_SECRET_KEY:-$S3_SECRET_KEY_ENV}"
NOTIFICATION_EMAIL="${NOTIFICATION_EMAIL:-$NOTIFICATION_EMAIL_ENV}"
SLACK_WEBHOOK="${SLACK_WEBHOOK:-$SLACK_WEBHOOK_ENV}"

# Validate requirements
check_requirements() {
    log "Checking requirements..."
    
    # Check if mysqldump is available
    if ! command -v mysqldump &> /dev/null; then
        error "mysqldump is not installed. Please install MySQL client tools."
    fi
    
    # Check compression tools
    case $COMPRESSION in
        gzip)
            if ! command -v gzip &> /dev/null; then
                error "gzip is not available"
            fi
            ;;
        xz)
            if ! command -v xz &> /dev/null; then
                error "xz is not available"
            fi
            ;;
        none)
            # No compression tool needed
            ;;
        *)
            error "Unsupported compression type: $COMPRESSION"
            ;;
    esac
    
    # Check encryption tools
    if [[ "$ENCRYPTION" == true ]]; then
        if ! command -v openssl &> /dev/null; then
            error "openssl is not available for encryption"
        fi
        if [[ -z "$ENCRYPTION_PASSWORD" ]]; then
            error "Encryption password is required when encryption is enabled"
        fi
    fi
    
    # Check S3 tools if S3 is configured
    if [[ -n "$S3_ENDPOINT" ]]; then
        if ! command -v aws &> /dev/null; then
            warn "AWS CLI not found. Installing MinIO client (mc) for S3 operations..."
            if ! command -v mc &> /dev/null; then
                error "Neither AWS CLI nor MinIO client is available. Please install one of them."
            fi
        fi
    fi
    
    # Create backup directory
    mkdir -p "$BACKUP_DIR"
    mkdir -p "$(dirname "$LOG_FILE")"
    
    log "Requirements check passed"
}

# Test database connection
test_db_connection() {
    log "Testing database connection..."
    
    if [[ -n "$DB_PASSWORD" ]]; then
        mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASSWORD" -e "SELECT 1;" > /dev/null 2>&1
    else
        mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -e "SELECT 1;" > /dev/null 2>&1
    fi
    
    if [[ $? -eq 0 ]]; then
        log "Database connection successful"
    else
        error "Failed to connect to database"
    fi
}

# Create backup
create_backup() {
    local timestamp=$(date '+%Y%m%d_%H%M%S')
    local backup_name="${DB_NAME}_${BACKUP_TYPE}_${timestamp}"
    local backup_file="${BACKUP_DIR}/${backup_name}.sql"
    
    log "Creating backup: $backup_name"
    
    # Create mysqldump command
    local dump_cmd="mysqldump"
    dump_cmd+=" -h $DB_HOST"
    dump_cmd+=" -P $DB_PORT"
    dump_cmd+=" -u $DB_USER"
    if [[ -n "$DB_PASSWORD" ]]; then
        dump_cmd+=" -p$DB_PASSWORD"
    fi
    dump_cmd+=" --single-transaction"
    dump_cmd+=" --routines"
    dump_cmd+=" --triggers"
    dump_cmd+=" --events"
    dump_cmd+=" --add-drop-database"
    dump_cmd+=" --databases $DB_NAME"
    
    # Execute backup
    eval "$dump_cmd" > "$backup_file"
    
    if [[ $? -eq 0 ]]; then
        local backup_size=$(stat -c%s "$backup_file")
        log "Backup created successfully: $backup_file ($(numfmt --to=iec $backup_size))"
    else
        error "Failed to create backup"
    fi
    
    # Apply compression
    if [[ "$COMPRESSION" != "none" ]]; then
        log "Compressing backup with $COMPRESSION..."
        
        case $COMPRESSION in
            gzip)
                gzip "$backup_file"
                backup_file="${backup_file}.gz"
                ;;
            xz)
                xz "$backup_file"
                backup_file="${backup_file}.xz"
                ;;
        esac
        
        local compressed_size=$(stat -c%s "$backup_file")
        log "Backup compressed: $(numfmt --to=iec $compressed_size)"
    fi
    
    # Apply encryption
    if [[ "$ENCRYPTION" == true ]]; then
        log "Encrypting backup..."
        
        openssl enc -aes-256-cbc -salt -in "$backup_file" -out "${backup_file}.enc" -pass pass:"$ENCRYPTION_PASSWORD"
        
        if [[ $? -eq 0 ]]; then
            rm "$backup_file"
            backup_file="${backup_file}.enc"
            log "Backup encrypted successfully"
        else
            error "Failed to encrypt backup"
        fi
    fi
    
    echo "$backup_file"
}

# Upload to S3/MinIO
upload_to_s3() {
    local backup_file="$1"
    local filename=$(basename "$backup_file")
    local s3_path="mysql-backups/$BACKUP_TYPE/$filename"
    
    if [[ -z "$S3_ENDPOINT" || -z "$S3_BUCKET" ]]; then
        info "S3/MinIO not configured, skipping upload"
        return 0
    fi
    
    log "Uploading backup to S3/MinIO: $s3_path"
    
    if command -v aws &> /dev/null; then
        # Use AWS CLI
        AWS_ACCESS_KEY_ID="$S3_ACCESS_KEY" \
        AWS_SECRET_ACCESS_KEY="$S3_SECRET_KEY" \
        aws s3 cp "$backup_file" "s3://$S3_BUCKET/$s3_path" \
            --endpoint-url "$S3_ENDPOINT"
    elif command -v mc &> /dev/null; then
        # Use MinIO client
        local alias_name="backup-storage"
        mc alias set "$alias_name" "$S3_ENDPOINT" "$S3_ACCESS_KEY" "$S3_SECRET_KEY"
        mc cp "$backup_file" "$alias_name/$S3_BUCKET/$s3_path"
    else
        error "No S3 client available"
    fi
    
    if [[ $? -eq 0 ]]; then
        log "Backup uploaded successfully to S3/MinIO"
    else
        error "Failed to upload backup to S3/MinIO"
    fi
}

# Clean up old backups
cleanup_old_backups() {
    log "Cleaning up backups older than $RETENTION_DAYS days..."
    
    # Clean local backups
    find "$BACKUP_DIR" -name "*.sql*" -mtime +$RETENTION_DAYS -delete
    local deleted_local=$(find "$BACKUP_DIR" -name "*.sql*" -mtime +$RETENTION_DAYS | wc -l)
    
    if [[ $deleted_local -gt 0 ]]; then
        log "Deleted $deleted_local old local backups"
    fi
    
    # Clean S3/MinIO backups
    if [[ -n "$S3_ENDPOINT" && -n "$S3_BUCKET" ]]; then
        log "Cleaning up old S3/MinIO backups..."
        
        local cutoff_date=$(date -d "$RETENTION_DAYS days ago" '+%Y-%m-%d')
        
        if command -v aws &> /dev/null; then
            # Use AWS CLI
            AWS_ACCESS_KEY_ID="$S3_ACCESS_KEY" \
            AWS_SECRET_ACCESS_KEY="$S3_SECRET_KEY" \
            aws s3 ls "s3://$S3_BUCKET/mysql-backups/$BACKUP_TYPE/" \
                --endpoint-url "$S3_ENDPOINT" \
                --recursive | \
            while read -r line; do
                local file_date=$(echo "$line" | awk '{print $1}')
                local file_name=$(echo "$line" | awk '{print $4}')
                
                if [[ "$file_date" < "$cutoff_date" ]]; then
                    AWS_ACCESS_KEY_ID="$S3_ACCESS_KEY" \
                    AWS_SECRET_ACCESS_KEY="$S3_SECRET_KEY" \
                    aws s3 rm "s3://$S3_BUCKET/$file_name" \
                        --endpoint-url "$S3_ENDPOINT"
                    log "Deleted old S3 backup: $file_name"
                fi
            done
        elif command -v mc &> /dev/null; then
            # Use MinIO client
            local alias_name="backup-storage"
            mc alias set "$alias_name" "$S3_ENDPOINT" "$S3_ACCESS_KEY" "$S3_SECRET_KEY"
            
            # MinIO client doesn't have built-in date filtering, so we'll use a simple approach
            mc ls "$alias_name/$S3_BUCKET/mysql-backups/$BACKUP_TYPE/" | \
            while read -r line; do
                local file_name=$(echo "$line" | awk '{print $6}')
                local file_path="$alias_name/$S3_BUCKET/mysql-backups/$BACKUP_TYPE/$file_name"
                
                # Simple date-based cleanup (files older than retention period)
                local file_timestamp=$(echo "$file_name" | grep -o '[0-9]\{8\}_[0-9]\{6\}')
                if [[ -n "$file_timestamp" ]]; then
                    local file_date=$(echo "$file_timestamp" | cut -d_ -f1)
                    local formatted_date=$(date -d "$file_date" '+%Y-%m-%d' 2>/dev/null || echo "")
                    
                    if [[ -n "$formatted_date" && "$formatted_date" < "$cutoff_date" ]]; then
                        mc rm "$file_path"
                        log "Deleted old MinIO backup: $file_name"
                    fi
                fi
            done
        fi
    fi
}

# Send notifications
send_notification() {
    local status="$1"
    local message="$2"
    local backup_file="$3"
    
    local subject="MySQL Backup $status - $(hostname)"
    local body="$message"
    
    if [[ -n "$backup_file" ]]; then
        local backup_size=$(stat -c%s "$backup_file" 2>/dev/null || echo "unknown")
        body+="\n\nBackup Details:"
        body+="\nFile: $backup_file"
        body+="\nSize: $(numfmt --to=iec $backup_size 2>/dev/null || echo "unknown")"
        body+="\nType: $BACKUP_TYPE"
        body+="\nDatabase: $DB_NAME"
        body+="\nTimestamp: $(date)"
    fi
    
    # Email notification
    if [[ -n "$NOTIFICATION_EMAIL" ]] && command -v mail &> /dev/null; then
        echo -e "$body" | mail -s "$subject" "$NOTIFICATION_EMAIL"
        log "Email notification sent to $NOTIFICATION_EMAIL"
    fi
    
    # Slack notification
    if [[ -n "$SLACK_WEBHOOK" ]] && command -v curl &> /dev/null; then
        local color="good"
        if [[ "$status" == "FAILED" ]]; then
            color="danger"
        elif [[ "$status" == "WARNING" ]]; then
            color="warning"
        fi
        
        local slack_payload=$(cat <<EOF
{
    "attachments": [
        {
            "color": "$color",
            "title": "$subject",
            "text": "$message",
            "fields": [
                {
                    "title": "Database",
                    "value": "$DB_NAME",
                    "short": true
                },
                {
                    "title": "Type",
                    "value": "$BACKUP_TYPE",
                    "short": true
                },
                {
                    "title": "Hostname",
                    "value": "$(hostname)",
                    "short": true
                },
                {
                    "title": "Timestamp",
                    "value": "$(date)",
                    "short": true
                }
            ]
        }
    ]
}
EOF
        )
        
        curl -X POST -H 'Content-type: application/json' \
            --data "$slack_payload" \
            "$SLACK_WEBHOOK" \
            --silent --output /dev/null
        
        log "Slack notification sent"
    fi
}

# Main backup process
main() {
    local start_time=$(date +%s)
    
    log "Starting MySQL backup process..."
    log "Backup type: $BACKUP_TYPE"
    log "Database: $DB_NAME"
    log "Retention: $RETENTION_DAYS days"
    log "Compression: $COMPRESSION"
    log "Encryption: $ENCRYPTION"
    
    {
        echo "=== MySQL Backup Log ==="
        echo "Date: $(date)"
        echo "Type: $BACKUP_TYPE"
        echo "Database: $DB_NAME"
        echo "Host: $DB_HOST:$DB_PORT"
        echo "User: $DB_USER"
        echo "========================="
    } >> "$LOG_FILE"
    
    # Check requirements
    check_requirements
    
    # Test database connection
    test_db_connection
    
    # Create backup
    local backup_file
    backup_file=$(create_backup)
    
    # Upload to S3/MinIO
    if [[ -n "$backup_file" ]]; then
        upload_to_s3 "$backup_file"
    fi
    
    # Clean up old backups
    cleanup_old_backups
    
    # Calculate execution time
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    log "Backup process completed successfully in ${duration}s"
    
    # Send success notification
    send_notification "SUCCESS" "MySQL backup completed successfully in ${duration}s" "$backup_file"
    
    # Log to file
    {
        echo "Status: SUCCESS"
        echo "Duration: ${duration}s"
        echo "Backup file: $backup_file"
        echo "========================="
        echo ""
    } >> "$LOG_FILE"
}

# Error handling
trap 'send_notification "FAILED" "MySQL backup failed with error: $?" ""' ERR

# Run main function
main "$@"
