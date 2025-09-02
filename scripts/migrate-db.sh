#!/bin/bash

# Database Migration Automation Script
# Handles idempotent database migrations on container startup

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
    logger -t db-migration "$1" 2>/dev/null || true
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
    logger -t db-migration -p user.warning "WARNING: $1" 2>/dev/null || true
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
    logger -t db-migration -p user.err "ERROR: $1" 2>/dev/null || true
    exit 1
}

info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $1${NC}"
    logger -t db-migration -p user.info "INFO: $1" 2>/dev/null || true
}

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
MIGRATIONS_DIR="$PROJECT_ROOT/migrations"
MIGRATION_LOG="/var/log/db-migrations.log"

# Database configuration (from environment)
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-3306}"
DB_USER="${DB_USER:-root}"
DB_PASSWORD="${DB_PASSWORD:-}"
DB_NAME="${DB_NAME:-blogcms}"

# Migration settings
MAX_RETRIES="${MAX_RETRIES:-30}"
RETRY_DELAY="${RETRY_DELAY:-5}"
FORCE_MIGRATION="${FORCE_MIGRATION:-false}"
TIMEOUT="${TIMEOUT:-300}"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
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
        --max-retries)
            MAX_RETRIES="$2"
            shift 2
            ;;
        --retry-delay)
            RETRY_DELAY="$2"
            shift 2
            ;;
        --force)
            FORCE_MIGRATION="true"
            shift
            ;;
        --timeout)
            TIMEOUT="$2"
            shift 2
            ;;
        --migrations-dir)
            MIGRATIONS_DIR="$2"
            shift 2
            ;;
        -h|--help)
            echo "Database Migration Automation Script"
            echo ""
            echo "Handles idempotent database migrations for BlogCMS"
            echo ""
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Database Options:"
            echo "  --db-host HOST        Database host (default: localhost)"
            echo "  --db-port PORT        Database port (default: 3306)"
            echo "  --db-user USER        Database user (default: root)"
            echo "  --db-password PASS    Database password"
            echo "  --db-name DATABASE    Database name (default: blogcms)"
            echo ""
            echo "Migration Options:"
            echo "  --max-retries N       Maximum connection retries (default: 30)"
            echo "  --retry-delay N       Delay between retries in seconds (default: 5)"
            echo "  --timeout N           Migration timeout in seconds (default: 300)"
            echo "  --force              Force migration even if already applied"
            echo "  --migrations-dir DIR  Path to migrations directory"
            echo ""
            echo "Other Options:"
            echo "  -h, --help           Show this help message"
            echo ""
            echo "Environment Variables:"
            echo "  DB_HOST, DB_PORT, DB_USER, DB_PASSWORD, DB_NAME"
            echo "  MAX_RETRIES, RETRY_DELAY, FORCE_MIGRATION, TIMEOUT"
            exit 0
            ;;
        *)
            error "Unknown option: $1. Use -h for help."
            ;;
    esac
done

# Initialize logging
init_logging() {
    mkdir -p "$(dirname "$MIGRATION_LOG")" 2>/dev/null || true
    
    {
        echo "=== Database Migration Log ==="
        echo "Date: $(date -Iseconds)"
        echo "Host: $DB_HOST:$DB_PORT"
        echo "Database: $DB_NAME"
        echo "User: $DB_USER"
        echo "Migrations Dir: $MIGRATIONS_DIR"
        echo "=============================="
    } >> "$MIGRATION_LOG"
}

# Wait for database to be available
wait_for_database() {
    log "Waiting for database to be available..."
    
    local retry_count=0
    local mysql_cmd="mysql -h $DB_HOST -P $DB_PORT -u $DB_USER"
    if [[ -n "$DB_PASSWORD" ]]; then
        mysql_cmd+=" -p$DB_PASSWORD"
    fi
    
    while [[ $retry_count -lt $MAX_RETRIES ]]; do
        if eval "$mysql_cmd -e 'SELECT 1;'" &> /dev/null; then
            log "Database is available"
            return 0
        fi
        
        retry_count=$((retry_count + 1))
        info "Database not available, retrying in ${RETRY_DELAY}s (attempt $retry_count/$MAX_RETRIES)"
        sleep "$RETRY_DELAY"
    done
    
    error "Database is not available after $MAX_RETRIES attempts"
}

# Create database if it doesn't exist
create_database() {
    log "Checking if database exists..."
    
    local mysql_cmd="mysql -h $DB_HOST -P $DB_PORT -u $DB_USER"
    if [[ -n "$DB_PASSWORD" ]]; then
        mysql_cmd+=" -p$DB_PASSWORD"
    fi
    
    # Check if database exists
    local db_exists
    db_exists=$(eval "$mysql_cmd -e \"SELECT SCHEMA_NAME FROM information_schema.SCHEMATA WHERE SCHEMA_NAME='$DB_NAME';\"" | tail -n +2)
    
    if [[ -z "$db_exists" ]]; then
        log "Creating database: $DB_NAME"
        eval "$mysql_cmd -e \"CREATE DATABASE IF NOT EXISTS \\\`$DB_NAME\\\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;\""
        log "Database created successfully"
    else
        log "Database already exists: $DB_NAME"
    fi
}

# Create migration tracking table
create_migration_table() {
    log "Setting up migration tracking table..."
    
    local mysql_cmd="mysql -h $DB_HOST -P $DB_PORT -u $DB_USER"
    if [[ -n "$DB_PASSWORD" ]]; then
        mysql_cmd+=" -p$DB_PASSWORD"
    fi
    mysql_cmd+=" $DB_NAME"
    
    local migration_table_sql="
    CREATE TABLE IF NOT EXISTS schema_migrations (
        id BIGINT AUTO_INCREMENT PRIMARY KEY,
        version VARCHAR(255) NOT NULL UNIQUE,
        filename VARCHAR(255) NOT NULL,
        checksum VARCHAR(64) NOT NULL,
        applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        execution_time_ms INT DEFAULT 0,
        INDEX idx_version (version),
        INDEX idx_applied_at (applied_at)
    ) ENGINE=InnoDB CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
    "
    
    eval "$mysql_cmd -e \"$migration_table_sql\""
    log "Migration tracking table ready"
}

# Calculate file checksum
calculate_checksum() {
    local file="$1"
    sha256sum "$file" | cut -d' ' -f1
}

# Get applied migrations
get_applied_migrations() {
    local mysql_cmd="mysql -h $DB_HOST -P $DB_PORT -u $DB_USER"
    if [[ -n "$DB_PASSWORD" ]]; then
        mysql_cmd+=" -p$DB_PASSWORD"
    fi
    mysql_cmd+=" $DB_NAME"
    
    eval "$mysql_cmd -N -e \"SELECT version FROM schema_migrations ORDER BY version;\""
}

# Check if migration is applied
is_migration_applied() {
    local version="$1"
    local applied_migrations
    applied_migrations=$(get_applied_migrations)
    
    echo "$applied_migrations" | grep -q "^$version$"
}

# Validate migration file
validate_migration() {
    local file="$1"
    local filename
    filename=$(basename "$file")
    
    # Check filename format (YYYYMMDDHHMMSS_description.sql)
    if [[ ! "$filename" =~ ^[0-9]{14}_[a-zA-Z0-9_]+\.sql$ ]]; then
        error "Invalid migration filename format: $filename (expected: YYYYMMDDHHMMSS_description.sql)"
    fi
    
    # Check if file is readable
    if [[ ! -r "$file" ]]; then
        error "Migration file is not readable: $file"
    fi
    
    # Check for dangerous SQL statements in production
    if [[ "${APP_ENV:-production}" == "production" ]]; then
        local dangerous_statements=(
            "DROP DATABASE"
            "DROP SCHEMA"
            "TRUNCATE"
            "DELETE FROM.*WHERE.*1.*=.*1"
        )
        
        for stmt in "${dangerous_statements[@]}"; do
            if grep -i "$stmt" "$file" &> /dev/null; then
                warn "Potentially dangerous SQL statement found in $filename: $stmt"
                if [[ "$FORCE_MIGRATION" != "true" ]]; then
                    error "Migration contains dangerous statements. Use --force to override."
                fi
            fi
        done
    fi
}

# Apply single migration
apply_migration() {
    local file="$1"
    local filename
    filename=$(basename "$file")
    local version
    version=$(echo "$filename" | cut -d'_' -f1)
    
    log "Applying migration: $filename"
    
    # Validate migration
    validate_migration "$file"
    
    # Check if already applied
    if is_migration_applied "$version" && [[ "$FORCE_MIGRATION" != "true" ]]; then
        info "Migration already applied: $filename"
        return 0
    fi
    
    # Calculate checksum
    local checksum
    checksum=$(calculate_checksum "$file")
    
    # Check for checksum mismatch
    local mysql_cmd="mysql -h $DB_HOST -P $DB_PORT -u $DB_USER"
    if [[ -n "$DB_PASSWORD" ]]; then
        mysql_cmd+=" -p$DB_PASSWORD"
    fi
    mysql_cmd+=" $DB_NAME"
    
    local existing_checksum
    existing_checksum=$(eval "$mysql_cmd -N -e \"SELECT checksum FROM schema_migrations WHERE version='$version';\"" 2>/dev/null || echo "")
    
    if [[ -n "$existing_checksum" && "$existing_checksum" != "$checksum" ]]; then
        error "Migration checksum mismatch for $filename. Migration may have been modified after application."
    fi
    
    # Apply migration with timeout
    local start_time
    start_time=$(date +%s%3N)
    
    log "Executing migration: $filename"
    
    # Use timeout command if available
    local timeout_cmd=""
    if command -v timeout &> /dev/null; then
        timeout_cmd="timeout $TIMEOUT"
    fi
    
    # Execute migration in transaction
    local migration_sql
    migration_sql=$(cat << EOF
START TRANSACTION;

-- Execute migration
$(cat "$file")

-- Record migration
INSERT INTO schema_migrations (version, filename, checksum, execution_time_ms, applied_at)
VALUES ('$version', '$filename', '$checksum', 0, NOW())
ON DUPLICATE KEY UPDATE
    filename = VALUES(filename),
    checksum = VALUES(checksum),
    applied_at = NOW(),
    execution_time_ms = VALUES(execution_time_ms);

COMMIT;
EOF
    )
    
    if eval "$timeout_cmd $mysql_cmd" <<< "$migration_sql"; then
        local end_time
        end_time=$(date +%s%3N)
        local execution_time
        execution_time=$((end_time - start_time))
        
        # Update execution time
        eval "$mysql_cmd -e \"UPDATE schema_migrations SET execution_time_ms = $execution_time WHERE version = '$version';\""
        
        log "Migration applied successfully: $filename (${execution_time}ms)"
        
        # Log to file
        {
            echo "Applied: $filename"
            echo "Version: $version"
            echo "Checksum: $checksum"
            echo "Execution Time: ${execution_time}ms"
            echo "Applied At: $(date -Iseconds)"
            echo "---"
        } >> "$MIGRATION_LOG"
        
    else
        error "Failed to apply migration: $filename"
    fi
}

# Run all pending migrations
run_migrations() {
    log "Starting database migrations..."
    
    if [[ ! -d "$MIGRATIONS_DIR" ]]; then
        warn "Migrations directory not found: $MIGRATIONS_DIR"
        log "Skipping migrations"
        return 0
    fi
    
    # Get list of migration files
    local migration_files
    migration_files=($(find "$MIGRATIONS_DIR" -name "*.sql" -type f | sort))
    
    if [[ ${#migration_files[@]} -eq 0 ]]; then
        info "No migration files found in $MIGRATIONS_DIR"
        return 0
    fi
    
    log "Found ${#migration_files[@]} migration file(s)"
    
    local applied_count=0
    local skipped_count=0
    
    # Apply each migration
    for file in "${migration_files[@]}"; do
        local filename
        filename=$(basename "$file")
        local version
        version=$(echo "$filename" | cut -d'_' -f1)
        
        if is_migration_applied "$version" && [[ "$FORCE_MIGRATION" != "true" ]]; then
            info "Skipping already applied migration: $filename"
            ((skipped_count++))
        else
            apply_migration "$file"
            ((applied_count++))
        fi
    done
    
    log "Migration completed: $applied_count applied, $skipped_count skipped"
    
    # Log summary
    {
        echo "Migration Summary:"
        echo "Applied: $applied_count"
        echo "Skipped: $skipped_count"
        echo "Total Files: ${#migration_files[@]}"
        echo "Completed At: $(date -Iseconds)"
        echo "==============================="
        echo ""
    } >> "$MIGRATION_LOG"
}

# Health check for migrations
migration_health_check() {
    log "Running migration health check..."
    
    local mysql_cmd="mysql -h $DB_HOST -P $DB_PORT -u $DB_USER"
    if [[ -n "$DB_PASSWORD" ]]; then
        mysql_cmd+=" -p$DB_PASSWORD"
    fi
    mysql_cmd+=" $DB_NAME"
    
    # Check migration table exists
    local table_exists
    table_exists=$(eval "$mysql_cmd -N -e \"SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='$DB_NAME' AND table_name='schema_migrations';\"")
    
    if [[ "$table_exists" -eq 0 ]]; then
        warn "Migration tracking table does not exist"
        return 1
    fi
    
    # Get migration statistics
    local total_migrations
    total_migrations=$(eval "$mysql_cmd -N -e \"SELECT COUNT(*) FROM schema_migrations;\"")
    
    local latest_migration
    latest_migration=$(eval "$mysql_cmd -N -e \"SELECT version FROM schema_migrations ORDER BY applied_at DESC LIMIT 1;\"" 2>/dev/null || echo "none")
    
    log "Migration health check passed"
    log "Total applied migrations: $total_migrations"
    log "Latest migration: $latest_migration"
    
    return 0
}

# Main function
main() {
    log "Starting database migration automation..."
    
    # Initialize logging
    init_logging
    
    # Wait for database
    wait_for_database
    
    # Create database if needed
    create_database
    
    # Create migration tracking table
    create_migration_table
    
    # Run migrations
    run_migrations
    
    # Health check
    migration_health_check
    
    log "Database migration automation completed successfully"
}

# Error handling
trap 'error "Migration script failed with exit code $?"' ERR

# Signal handling for graceful shutdown
trap 'log "Migration interrupted, cleaning up..."; exit 130' INT TERM

# Run main function
main "$@"
