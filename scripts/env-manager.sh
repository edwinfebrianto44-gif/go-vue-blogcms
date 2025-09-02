#!/bin/bash

# Production Environment Management Script
# Handles secure .env management and JWT secret rotation

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
    logger -t env-manager "$1"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
    logger -t env-manager -p user.warning "WARNING: $1"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
    logger -t env-manager -p user.err "ERROR: $1"
    exit 1
}

info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $1${NC}"
    logger -t env-manager -p user.info "INFO: $1"
}

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$PROJECT_ROOT/.env"
ENV_EXAMPLE="$PROJECT_ROOT/.env.example"
ENV_BACKUP_DIR="/etc/blogcms/env-backups"
JWT_ROTATION_LOG="/var/log/jwt-rotation.log"

# Commands
COMMAND=""
FORCE=false
INTERACTIVE=true

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        init)
            COMMAND="init"
            shift
            ;;
        rotate-jwt)
            COMMAND="rotate-jwt"
            shift
            ;;
        backup)
            COMMAND="backup"
            shift
            ;;
        restore)
            COMMAND="restore"
            shift
            ;;
        validate)
            COMMAND="validate"
            shift
            ;;
        --force)
            FORCE=true
            shift
            ;;
        --non-interactive)
            INTERACTIVE=false
            shift
            ;;
        -h|--help)
            echo "Production Environment Management Script"
            echo ""
            echo "Manages secure .env files and JWT secret rotation for BlogCMS"
            echo ""
            echo "Usage: $0 COMMAND [OPTIONS]"
            echo ""
            echo "Commands:"
            echo "  init              Initialize production environment"
            echo "  rotate-jwt        Rotate JWT secret"
            echo "  backup            Backup current environment"
            echo "  restore           Restore environment from backup"
            echo "  validate          Validate environment configuration"
            echo ""
            echo "Options:"
            echo "  --force           Force operation without confirmation"
            echo "  --non-interactive Non-interactive mode"
            echo "  -h, --help       Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0 init                 Initialize production environment"
            echo "  $0 rotate-jwt           Rotate JWT secret safely"
            echo "  $0 backup               Backup current environment"
            echo "  $0 validate             Validate environment variables"
            exit 0
            ;;
        *)
            error "Unknown option: $1. Use -h for help."
            ;;
    esac
done

if [[ -z "$COMMAND" ]]; then
    error "Command is required. Use -h for help."
fi

# Check if running as root for certain operations
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "This operation must be run as root (use sudo)"
    fi
}

# Generate secure random string
generate_secret() {
    local length=${1:-64}
    openssl rand -base64 48 | tr -d "=+/" | cut -c1-${length}
}

# Generate JWT secret
generate_jwt_secret() {
    generate_secret 64
}

# Create secure backup
create_backup() {
    local backup_name="env_backup_$(date +%Y%m%d_%H%M%S)"
    local backup_file="$ENV_BACKUP_DIR/$backup_name.tar.gz.gpg"
    
    log "Creating environment backup: $backup_name"
    
    # Create backup directory
    mkdir -p "$ENV_BACKUP_DIR"
    
    # Create temporary directory for backup
    local temp_dir
    temp_dir=$(mktemp -d)
    
    # Copy environment files
    if [[ -f "$ENV_FILE" ]]; then
        cp "$ENV_FILE" "$temp_dir/"
    fi
    
    if [[ -f "$ENV_EXAMPLE" ]]; then
        cp "$ENV_EXAMPLE" "$temp_dir/"
    fi
    
    # Add metadata
    cat > "$temp_dir/backup_info.txt" << EOF
Backup Created: $(date -Iseconds)
Hostname: $(hostname)
User: $(whoami)
Project: BlogCMS
Backup Type: Environment Configuration
EOF
    
    # Create encrypted archive
    tar -czf - -C "$temp_dir" . | gpg --symmetric --cipher-algo AES256 --output "$backup_file"
    
    # Cleanup
    rm -rf "$temp_dir"
    
    # Set secure permissions
    chmod 600 "$backup_file"
    chown root:root "$backup_file" 2>/dev/null || true
    
    log "Backup created: $backup_file"
    echo "$backup_file"
}

# Initialize production environment
init_environment() {
    log "Initializing production environment..."
    
    # Check if .env already exists
    if [[ -f "$ENV_FILE" && "$FORCE" != true ]]; then
        if [[ "$INTERACTIVE" == true ]]; then
            warn ".env file already exists"
            read -p "Do you want to reinitialize? This will backup the current file. (y/n): " confirm
            if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
                log "Initialization cancelled"
                return 0
            fi
        else
            warn ".env file already exists. Use --force to overwrite."
            return 1
        fi
    fi
    
    # Create backup if .env exists
    if [[ -f "$ENV_FILE" ]]; then
        create_backup
    fi
    
    # Generate secure values
    local jwt_secret
    jwt_secret=$(generate_jwt_secret)
    
    local db_password
    db_password=$(generate_secret 32)
    
    local session_secret
    session_secret=$(generate_secret 64)
    
    # Create .env file from example
    if [[ ! -f "$ENV_EXAMPLE" ]]; then
        error ".env.example file not found. Please ensure it exists in the project root."
    fi
    
    log "Creating production .env file..."
    
    # Copy example and replace placeholders
    cp "$ENV_EXAMPLE" "$ENV_FILE"
    
    # Replace sensitive values with generated ones
    sed -i "s/JWT_SECRET=.*/JWT_SECRET=$jwt_secret/" "$ENV_FILE"
    sed -i "s/DB_PASSWORD=.*/DB_PASSWORD=$db_password/" "$ENV_FILE"
    sed -i "s/SESSION_SECRET=.*/SESSION_SECRET=$session_secret/" "$ENV_FILE"
    
    # Set environment to production
    sed -i "s/APP_ENV=.*/APP_ENV=production/" "$ENV_FILE"
    sed -i "s/DEBUG=.*/DEBUG=false/" "$ENV_FILE"
    
    # Set secure permissions
    chmod 600 "$ENV_FILE"
    chown root:root "$ENV_FILE" 2>/dev/null || true
    
    log "Production environment initialized successfully"
    
    # Display important information
    info "Generated credentials:"
    info "JWT Secret: $jwt_secret"
    info "DB Password: $db_password"
    info "Session Secret: $session_secret"
    
    warn "Please save these credentials securely and update your database configuration!"
    warn "The .env file is now secured with root-only access (600 permissions)"
}

# Rotate JWT secret
rotate_jwt_secret() {
    log "Starting JWT secret rotation..."
    
    if [[ ! -f "$ENV_FILE" ]]; then
        error ".env file not found. Please initialize the environment first."
    fi
    
    # Create backup before rotation
    local backup_file
    backup_file=$(create_backup)
    
    # Get current JWT secret
    local old_jwt_secret
    old_jwt_secret=$(grep "^JWT_SECRET=" "$ENV_FILE" | cut -d'=' -f2-)
    
    if [[ -z "$old_jwt_secret" ]]; then
        error "JWT_SECRET not found in .env file"
    fi
    
    # Generate new JWT secret
    local new_jwt_secret
    new_jwt_secret=$(generate_jwt_secret)
    
    log "Rotating JWT secret..."
    
    # Update .env file
    sed -i "s/JWT_SECRET=.*/JWT_SECRET=$new_jwt_secret/" "$ENV_FILE"
    
    # Log rotation
    {
        echo "=== JWT Secret Rotation ==="
        echo "Date: $(date -Iseconds)"
        echo "Hostname: $(hostname)"
        echo "Old Secret: ${old_jwt_secret:0:10}... (truncated)"
        echo "New Secret: ${new_jwt_secret:0:10}... (truncated)"
        echo "Backup File: $backup_file"
        echo "=========================="
        echo ""
    } >> "$JWT_ROTATION_LOG"
    
    log "JWT secret rotated successfully"
    
    # Display important information
    warn "JWT secret has been rotated!"
    warn "Old tokens will be invalid. Users will need to log in again."
    warn "New JWT secret: ${new_jwt_secret:0:20}... (truncated for security)"
    warn "Backup created: $backup_file"
    
    # Restart application if running in Docker
    if command -v docker-compose &> /dev/null; then
        if [[ "$INTERACTIVE" == true ]]; then
            read -p "Restart the application to apply changes? (y/n): " restart_confirm
            if [[ "$restart_confirm" == "y" || "$restart_confirm" == "Y" ]]; then
                log "Restarting application..."
                cd "$PROJECT_ROOT"
                docker-compose restart api
            fi
        fi
    fi
}

# Validate environment configuration
validate_environment() {
    log "Validating environment configuration..."
    
    if [[ ! -f "$ENV_FILE" ]]; then
        error ".env file not found"
    fi
    
    local errors=0
    local warnings=0
    
    # Check file permissions
    local file_perms
    file_perms=$(stat -c "%a" "$ENV_FILE")
    if [[ "$file_perms" != "600" ]]; then
        warn "File permissions should be 600, current: $file_perms"
        ((warnings++))
    fi
    
    # Required variables
    local required_vars=(
        "APP_ENV"
        "APP_PORT"
        "DB_HOST"
        "DB_PORT"
        "DB_USER"
        "DB_PASSWORD"
        "DB_NAME"
        "JWT_SECRET"
        "CORS_ORIGINS"
    )
    
    # Check required variables
    for var in "${required_vars[@]}"; do
        if ! grep -q "^${var}=" "$ENV_FILE"; then
            error "Missing required variable: $var"
            ((errors++))
        fi
    done
    
    # Check JWT secret strength
    local jwt_secret
    jwt_secret=$(grep "^JWT_SECRET=" "$ENV_FILE" | cut -d'=' -f2-)
    if [[ ${#jwt_secret} -lt 32 ]]; then
        warn "JWT_SECRET should be at least 32 characters long"
        ((warnings++))
    fi
    
    # Check database password strength
    local db_password
    db_password=$(grep "^DB_PASSWORD=" "$ENV_FILE" | cut -d'=' -f2-)
    if [[ ${#db_password} -lt 16 ]]; then
        warn "DB_PASSWORD should be at least 16 characters long"
        ((warnings++))
    fi
    
    # Check environment setting
    local app_env
    app_env=$(grep "^APP_ENV=" "$ENV_FILE" | cut -d'=' -f2-)
    if [[ "$app_env" != "production" ]]; then
        warn "APP_ENV should be set to 'production' for production deployment"
        ((warnings++))
    fi
    
    # Check debug setting
    local debug
    debug=$(grep "^DEBUG=" "$ENV_FILE" | cut -d'=' -f2-)
    if [[ "$debug" == "true" ]]; then
        warn "DEBUG should be set to 'false' for production deployment"
        ((warnings++))
    fi
    
    # Summary
    if [[ $errors -eq 0 && $warnings -eq 0 ]]; then
        log "Environment validation passed without issues"
    elif [[ $errors -eq 0 ]]; then
        warn "Environment validation passed with $warnings warning(s)"
    else
        error "Environment validation failed with $errors error(s) and $warnings warning(s)"
    fi
    
    return $errors
}

# Restore environment from backup
restore_environment() {
    log "Restoring environment from backup..."
    
    # List available backups
    if [[ ! -d "$ENV_BACKUP_DIR" ]]; then
        error "No backup directory found: $ENV_BACKUP_DIR"
    fi
    
    local backups
    backups=($(ls -1 "$ENV_BACKUP_DIR"/*.tar.gz.gpg 2>/dev/null || true))
    
    if [[ ${#backups[@]} -eq 0 ]]; then
        error "No backups found in $ENV_BACKUP_DIR"
    fi
    
    # Select backup
    local backup_file=""
    if [[ "$INTERACTIVE" == true ]]; then
        echo "Available backups:"
        for i in "${!backups[@]}"; do
            local backup_name
            backup_name=$(basename "${backups[$i]}")
            echo "$((i+1)). $backup_name"
        done
        
        read -p "Select backup to restore (1-${#backups[@]}): " selection
        if [[ "$selection" -ge 1 && "$selection" -le ${#backups[@]} ]]; then
            backup_file="${backups[$((selection-1))]}"
        else
            error "Invalid selection"
        fi
    else
        # Use latest backup in non-interactive mode
        backup_file="${backups[-1]}"
    fi
    
    log "Restoring from: $(basename "$backup_file")"
    
    # Create current backup before restore
    if [[ -f "$ENV_FILE" ]]; then
        create_backup
    fi
    
    # Create temporary directory for restore
    local temp_dir
    temp_dir=$(mktemp -d)
    
    # Decrypt and extract backup
    gpg --decrypt --quiet "$backup_file" | tar -xzf - -C "$temp_dir"
    
    # Restore .env file
    if [[ -f "$temp_dir/.env" ]]; then
        cp "$temp_dir/.env" "$ENV_FILE"
        chmod 600 "$ENV_FILE"
        chown root:root "$ENV_FILE" 2>/dev/null || true
        log "Environment restored successfully"
    else
        error "No .env file found in backup"
    fi
    
    # Cleanup
    rm -rf "$temp_dir"
}

# Main function
main() {
    case "$COMMAND" in
        init)
            check_root
            init_environment
            ;;
        rotate-jwt)
            check_root
            rotate_jwt_secret
            ;;
        backup)
            check_root
            create_backup
            ;;
        restore)
            check_root
            restore_environment
            ;;
        validate)
            validate_environment
            ;;
        *)
            error "Unknown command: $COMMAND"
            ;;
    esac
}

# Error handling
trap 'error "Script failed with exit code $?"' ERR

# Create required directories
mkdir -p "$ENV_BACKUP_DIR" 2>/dev/null || true
mkdir -p "$(dirname "$JWT_ROTATION_LOG")" 2>/dev/null || true

# Run main function
main "$@"
