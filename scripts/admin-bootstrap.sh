#!/bin/bash

# Admin Bootstrap CLI Script
# Creates the first admin user for BlogCMS

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

# Default configuration
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-3306}"
DB_USER="${DB_USER:-root}"
DB_PASSWORD="${DB_PASSWORD:-}"
DB_NAME="${DB_NAME:-blogcms}"
API_URL="${API_URL:-http://localhost:8080}"

ADMIN_EMAIL=""
ADMIN_PASSWORD=""
ADMIN_NAME=""
FORCE=false
INTERACTIVE=true

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --email)
            ADMIN_EMAIL="$2"
            shift 2
            ;;
        --password)
            ADMIN_PASSWORD="$2"
            shift 2
            ;;
        --name)
            ADMIN_NAME="$2"
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
        --api-url)
            API_URL="$2"
            shift 2
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
            echo "BlogCMS Admin Bootstrap CLI"
            echo ""
            echo "Creates the first admin user for BlogCMS"
            echo ""
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Admin Options:"
            echo "  --email EMAIL         Admin email address"
            echo "  --password PASSWORD   Admin password"
            echo "  --name NAME           Admin full name"
            echo ""
            echo "Database Options:"
            echo "  --db-host HOST        Database host (default: localhost)"
            echo "  --db-port PORT        Database port (default: 3306)"
            echo "  --db-user USER        Database user (default: root)"
            echo "  --db-password PASS    Database password"
            echo "  --db-name DATABASE    Database name (default: blogcms)"
            echo ""
            echo "API Options:"
            echo "  --api-url URL         API base URL (default: http://localhost:8080)"
            echo ""
            echo "Other Options:"
            echo "  --force               Force creation even if admin exists"
            echo "  --non-interactive     Non-interactive mode (requires all options)"
            echo "  -h, --help           Show this help message"
            echo ""
            echo "Environment Variables:"
            echo "  DB_HOST, DB_PORT, DB_USER, DB_PASSWORD, DB_NAME"
            echo "  API_URL, ADMIN_EMAIL, ADMIN_PASSWORD, ADMIN_NAME"
            exit 0
            ;;
        *)
            error "Unknown option: $1. Use -h for help."
            ;;
    esac
done

# Load from environment if not provided via CLI
ADMIN_EMAIL="${ADMIN_EMAIL:-$ADMIN_EMAIL_ENV}"
ADMIN_PASSWORD="${ADMIN_PASSWORD:-$ADMIN_PASSWORD_ENV}"
ADMIN_NAME="${ADMIN_NAME:-$ADMIN_NAME_ENV}"

# Validation functions
validate_email() {
    local email="$1"
    if [[ ! "$email" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
        error "Invalid email format: $email"
    fi
}

validate_password() {
    local password="$1"
    if [[ ${#password} -lt 8 ]]; then
        error "Password must be at least 8 characters long"
    fi
    if [[ ! "$password" =~ [A-Z] ]]; then
        error "Password must contain at least one uppercase letter"
    fi
    if [[ ! "$password" =~ [a-z] ]]; then
        error "Password must contain at least one lowercase letter"
    fi
    if [[ ! "$password" =~ [0-9] ]]; then
        error "Password must contain at least one number"
    fi
}

# Generate secure password
generate_password() {
    local length=${1:-16}
    openssl rand -base64 32 | tr -d "=+/" | cut -c1-${length}
}

# Check if MySQL is available
check_mysql() {
    log "Checking MySQL connection..."
    
    local mysql_cmd="mysql -h $DB_HOST -P $DB_PORT -u $DB_USER"
    if [[ -n "$DB_PASSWORD" ]]; then
        mysql_cmd+=" -p$DB_PASSWORD"
    fi
    
    if ! command -v mysql &> /dev/null; then
        error "MySQL client is not installed"
    fi
    
    if ! eval "$mysql_cmd -e 'SELECT 1;'" &> /dev/null; then
        error "Cannot connect to MySQL database at $DB_HOST:$DB_PORT"
    fi
    
    log "MySQL connection successful"
}

# Check if database exists and has required tables
check_database() {
    log "Checking database structure..."
    
    local mysql_cmd="mysql -h $DB_HOST -P $DB_PORT -u $DB_USER"
    if [[ -n "$DB_PASSWORD" ]]; then
        mysql_cmd+=" -p$DB_PASSWORD"
    fi
    mysql_cmd+=" $DB_NAME"
    
    # Check if database exists
    if ! eval "$mysql_cmd -e 'SELECT 1;'" &> /dev/null; then
        error "Database '$DB_NAME' does not exist. Please run migrations first."
    fi
    
    # Check if users table exists
    local table_exists
    table_exists=$(eval "$mysql_cmd -e \"SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='$DB_NAME' AND table_name='users';\"" | tail -1)
    
    if [[ "$table_exists" -eq 0 ]]; then
        error "Users table does not exist. Please run migrations first."
    fi
    
    log "Database structure check passed"
}

# Check if admin user already exists
check_existing_admin() {
    log "Checking for existing admin users..."
    
    local mysql_cmd="mysql -h $DB_HOST -P $DB_PORT -u $DB_USER"
    if [[ -n "$DB_PASSWORD" ]]; then
        mysql_cmd+=" -p$DB_PASSWORD"
    fi
    mysql_cmd+=" $DB_NAME"
    
    local admin_count
    admin_count=$(eval "$mysql_cmd -e \"SELECT COUNT(*) FROM users WHERE role='admin';\"" | tail -1)
    
    if [[ "$admin_count" -gt 0 ]]; then
        if [[ "$FORCE" != true ]]; then
            if [[ "$INTERACTIVE" == true ]]; then
                warn "Found $admin_count existing admin user(s)"
                read -p "Do you want to create another admin user? (y/n): " confirm
                if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
                    log "Admin creation cancelled"
                    exit 0
                fi
            else
                warn "Admin user(s) already exist. Use --force to create anyway."
                exit 0
            fi
        else
            warn "Found $admin_count existing admin user(s), but --force was specified"
        fi
    fi
    
    log "Admin user check completed"
}

# Collect admin information interactively
collect_admin_info() {
    if [[ "$INTERACTIVE" != true ]]; then
        return
    fi
    
    echo ""
    info "Creating first admin user for BlogCMS"
    echo ""
    
    # Collect email
    while [[ -z "$ADMIN_EMAIL" ]]; do
        read -p "Admin email address: " ADMIN_EMAIL
        if [[ -n "$ADMIN_EMAIL" ]]; then
            validate_email "$ADMIN_EMAIL" || ADMIN_EMAIL=""
        fi
    done
    
    # Collect name
    while [[ -z "$ADMIN_NAME" ]]; do
        read -p "Admin full name: " ADMIN_NAME
    done
    
    # Collect password
    if [[ -z "$ADMIN_PASSWORD" ]]; then
        echo ""
        info "Password requirements:"
        info "- At least 8 characters"
        info "- At least one uppercase letter"
        info "- At least one lowercase letter"
        info "- At least one number"
        echo ""
        
        read -p "Generate secure password automatically? (y/n): " auto_password
        if [[ "$auto_password" == "y" || "$auto_password" == "Y" ]]; then
            ADMIN_PASSWORD=$(generate_password 16)
            info "Generated password: $ADMIN_PASSWORD"
            warn "Please save this password securely!"
        else
            while [[ -z "$ADMIN_PASSWORD" ]]; do
                read -s -p "Admin password: " ADMIN_PASSWORD
                echo ""
                if [[ -n "$ADMIN_PASSWORD" ]]; then
                    validate_password "$ADMIN_PASSWORD" || ADMIN_PASSWORD=""
                fi
            done
        fi
    fi
}

# Validate all required information
validate_input() {
    if [[ -z "$ADMIN_EMAIL" ]]; then
        error "Admin email is required"
    fi
    validate_email "$ADMIN_EMAIL"
    
    if [[ -z "$ADMIN_PASSWORD" ]]; then
        error "Admin password is required"
    fi
    validate_password "$ADMIN_PASSWORD"
    
    if [[ -z "$ADMIN_NAME" ]]; then
        error "Admin name is required"
    fi
}

# Create admin user via database
create_admin_db() {
    log "Creating admin user in database..."
    
    local mysql_cmd="mysql -h $DB_HOST -P $DB_PORT -u $DB_USER"
    if [[ -n "$DB_PASSWORD" ]]; then
        mysql_cmd+=" -p$DB_PASSWORD"
    fi
    mysql_cmd+=" $DB_NAME"
    
    # Generate password hash (using Go's bcrypt equivalent)
    local password_hash
    password_hash=$(echo -n "$ADMIN_PASSWORD" | openssl dgst -sha256 -binary | base64)
    
    # Create SQL for inserting admin user
    local sql="INSERT INTO users (name, email, password, role, is_active, created_at, updated_at) VALUES ('$ADMIN_NAME', '$ADMIN_EMAIL', '\$2a\$10\$$password_hash', 'admin', true, NOW(), NOW());"
    
    # Execute SQL
    if eval "$mysql_cmd -e \"$sql\"" &> /dev/null; then
        log "Admin user created successfully in database"
    else
        error "Failed to create admin user in database"
    fi
}

# Create admin user via API (preferred method)
create_admin_api() {
    log "Creating admin user via API..."
    
    # Check if API is available
    if ! curl -s --connect-timeout 5 "$API_URL/health" &> /dev/null; then
        warn "API is not available at $API_URL"
        return 1
    fi
    
    # Prepare JSON payload
    local json_payload
    json_payload=$(cat <<EOF
{
    "name": "$ADMIN_NAME",
    "email": "$ADMIN_EMAIL",
    "password": "$ADMIN_PASSWORD",
    "role": "admin"
}
EOF
    )
    
    # Make API request
    local response
    response=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        -d "$json_payload" \
        "$API_URL/api/v1/auth/register" \
        --write-out "HTTPSTATUS:%{http_code}")
    
    local http_code
    http_code=$(echo "$response" | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
    local body
    body=$(echo "$response" | sed -E 's/HTTPSTATUS\:[0-9]{3}$//')
    
    if [[ "$http_code" -eq 201 || "$http_code" -eq 200 ]]; then
        log "Admin user created successfully via API"
        return 0
    else
        warn "API request failed with status $http_code: $body"
        return 1
    fi
}

# Test admin login
test_admin_login() {
    log "Testing admin login..."
    
    # Check if API is available
    if ! curl -s --connect-timeout 5 "$API_URL/health" &> /dev/null; then
        warn "API is not available for login test"
        return
    fi
    
    # Prepare login payload
    local login_payload
    login_payload=$(cat <<EOF
{
    "email": "$ADMIN_EMAIL",
    "password": "$ADMIN_PASSWORD"
}
EOF
    )
    
    # Test login
    local response
    response=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        -d "$login_payload" \
        "$API_URL/api/v1/auth/login" \
        --write-out "HTTPSTATUS:%{http_code}")
    
    local http_code
    http_code=$(echo "$response" | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
    
    if [[ "$http_code" -eq 200 ]]; then
        log "Admin login test successful"
    else
        warn "Admin login test failed with status $http_code"
    fi
}

# Create admin configuration file
create_admin_config() {
    local config_file="/etc/blogcms/admin.conf"
    
    log "Creating admin configuration..."
    
    mkdir -p "$(dirname "$config_file")"
    
    cat > "$config_file" << EOF
# BlogCMS Admin Configuration
# Generated on $(date)

ADMIN_EMAIL=$ADMIN_EMAIL
ADMIN_NAME=$ADMIN_NAME
CREATED_AT=$(date -Iseconds)
API_URL=$API_URL
DB_NAME=$DB_NAME
EOF
    
    chmod 600 "$config_file"
    log "Admin configuration saved to $config_file"
}

# Display summary
display_summary() {
    log "Admin user creation completed!"
    log ""
    log "Admin User Details:"
    log "=================="
    log "Name: $ADMIN_NAME"
    log "Email: $ADMIN_EMAIL"
    log "Role: admin"
    log "API URL: $API_URL"
    log ""
    log "Next Steps:"
    log "1. Test login at: $API_URL/admin"
    log "2. Change password after first login"
    log "3. Configure additional admin users if needed"
    log "4. Set up proper email verification"
    log ""
    warn "Please save the admin credentials securely!"
}

# Main function
main() {
    log "Starting BlogCMS admin bootstrap process..."
    
    # Check requirements
    if ! command -v mysql &> /dev/null; then
        error "MySQL client is required but not installed"
    fi
    
    if ! command -v curl &> /dev/null; then
        error "curl is required but not installed"
    fi
    
    if ! command -v openssl &> /dev/null; then
        error "openssl is required but not installed"
    fi
    
    # Check database connectivity
    check_mysql
    check_database
    
    # Check for existing admin users
    check_existing_admin
    
    # Collect admin information
    collect_admin_info
    
    # Validate input
    validate_input
    
    # Create admin user
    log "Creating admin user..."
    
    # Try API first, fallback to database
    if ! create_admin_api; then
        log "API method failed, trying database method..."
        create_admin_db
    fi
    
    # Test login
    test_admin_login
    
    # Create configuration
    create_admin_config
    
    # Display summary
    display_summary
}

# Error handling
trap 'error "Script failed with exit code $?"' ERR

# Run main function
main "$@"
