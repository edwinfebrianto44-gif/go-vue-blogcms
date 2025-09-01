#!/bin/bash

# Database Backup Script
# Creates backups of MySQL database

set -e

# Load environment variables
if [ -f .env ]; then
    source .env
else
    echo "Error: .env file not found"
    exit 1
fi

# Configuration
BACKUP_DIR="backups"
DATE=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="blogcms_backup_$DATE.sql"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Create backup directory
mkdir -p $BACKUP_DIR

print_status "Creating database backup..."

# Create database backup
docker-compose exec -T mysql mysqldump \
    -u root \
    -p$MYSQL_ROOT_PASSWORD \
    --single-transaction \
    --routines \
    --triggers \
    $DB_NAME > $BACKUP_DIR/$BACKUP_FILE

# Compress backup
print_status "Compressing backup..."
gzip $BACKUP_DIR/$BACKUP_FILE

BACKUP_FILE_GZ="$BACKUP_FILE.gz"

print_status "Backup created: $BACKUP_DIR/$BACKUP_FILE_GZ"

# Keep only last 7 backups
print_status "Cleaning old backups (keeping last 7)..."
cd $BACKUP_DIR
ls -t blogcms_backup_*.sql.gz | tail -n +8 | xargs -r rm --

# Optional: Upload to S3 (if configured)
if [ ! -z "$BACKUP_S3_BUCKET" ] && [ ! -z "$BACKUP_S3_ACCESS_KEY" ]; then
    print_status "Uploading to S3..."
    # Install aws-cli if not present
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI not installed. Skipping S3 upload."
    else
        aws s3 cp $BACKUP_FILE_GZ s3://$BACKUP_S3_BUCKET/database-backups/
        print_status "Backup uploaded to S3"
    fi
fi

print_status "✅ Backup completed successfully!"
echo "Backup file: $BACKUP_DIR/$BACKUP_FILE_GZ"
echo "Size: $(du -h $BACKUP_DIR/$BACKUP_FILE_GZ | cut -f1)"
