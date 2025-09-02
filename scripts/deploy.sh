#!/bin/bash

# deploy.sh - Deployment script for VPS

set -e

# Configuration
REPO_URL="https://github.com/YOUR_USERNAME/go-vue-blogcms.git"
DEPLOY_DIR="/opt/blogcms"
COMPOSE_FILE="$DEPLOY_DIR/docker-compose.yml"
BACKUP_DIR="/opt/backups/blogcms"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

# Check if running as root or with sudo
check_permissions() {
    if [[ $EUID -eq 0 ]]; then
        error "This script should not be run as root for security reasons"
    fi
    
    # Check if user can run docker
    if ! docker info >/dev/null 2>&1; then
        error "Docker is not accessible. Make sure Docker is installed and user is in docker group"
    fi
}

# Create backup of current database
backup_database() {
    log "Creating database backup..."
    
    mkdir -p "$BACKUP_DIR"
    
    # Only backup if containers are running
    if docker-compose -f "$COMPOSE_FILE" ps db | grep -q "Up"; then
        BACKUP_FILE="$BACKUP_DIR/backup_$(date +%Y%m%d_%H%M%S).sql"
        
        docker-compose -f "$COMPOSE_FILE" exec -T db mysqldump \
            -u blogcms_user \
            -p"${DB_PASSWORD}" \
            blogcms_db > "$BACKUP_FILE" || warn "Database backup failed"
        
        # Keep only last 10 backups
        ls -t "$BACKUP_DIR"/backup_*.sql | tail -n +11 | xargs -r rm
        
        log "Database backup created: $BACKUP_FILE"
    else
        warn "Database container not running, skipping backup"
    fi
}

# Health check function
health_check() {
    local max_attempts=30
    local attempt=1
    
    log "Performing health check..."
    
    while [ $attempt -le $max_attempts ]; do
        if curl -f http://localhost/health >/dev/null 2>&1; then
            log "Health check passed!"
            return 0
        fi
        
        log "Health check attempt $attempt/$max_attempts failed, waiting..."
        sleep 10
        ((attempt++))
    done
    
    error "Health check failed after $max_attempts attempts"
}

# Rollback function
rollback() {
    log "Rolling back to previous deployment..."
    
    if [ -f "$DEPLOY_DIR/docker-compose.yml.backup" ]; then
        mv "$DEPLOY_DIR/docker-compose.yml.backup" "$DEPLOY_DIR/docker-compose.yml"
        docker-compose -f "$COMPOSE_FILE" up -d
        log "Rollback completed"
    else
        error "No backup found for rollback"
    fi
}

# Main deployment function
deploy() {
    log "Starting deployment to VPS..."
    
    # Check permissions
    check_permissions
    
    # Create deploy directory if it doesn't exist
    sudo mkdir -p "$DEPLOY_DIR"
    sudo chown $(whoami):$(whoami) "$DEPLOY_DIR"
    
    # Navigate to deploy directory
    cd "$DEPLOY_DIR"
    
    # Create backup of current docker-compose.yml
    if [ -f "$COMPOSE_FILE" ]; then
        cp "$COMPOSE_FILE" "$COMPOSE_FILE.backup"
        backup_database
    fi
    
    # Pull latest changes
    if [ -d ".git" ]; then
        log "Updating existing repository..."
        git fetch origin
        git reset --hard origin/main
    else
        log "Cloning repository..."
        git clone "$REPO_URL" .
    fi
    
    # Login to GitHub Container Registry
    if [ -n "$GITHUB_TOKEN" ]; then
        echo "$GITHUB_TOKEN" | docker login ghcr.io -u "${GITHUB_USERNAME}" --password-stdin
    else
        warn "GITHUB_TOKEN not set, assuming public images"
    fi
    
    # Pull latest images
    log "Pulling latest Docker images..."
    docker-compose pull
    
    # Stop current services (gracefully)
    if docker-compose ps | grep -q "Up"; then
        log "Stopping current services..."
        docker-compose down --timeout 30
    fi
    
    # Start services
    log "Starting services..."
    docker-compose up -d
    
    # Wait for services to be ready
    sleep 15
    
    # Perform health check
    if health_check; then
        log "Deployment successful!"
        
        # Clean up old images
        docker image prune -f
        
        # Remove backup
        rm -f "$COMPOSE_FILE.backup"
        
    else
        error "Deployment failed health check"
        rollback
    fi
}

# Cleanup function
cleanup() {
    log "Performing cleanup..."
    
    # Remove old containers
    docker container prune -f
    
    # Remove old images
    docker image prune -f
    
    # Remove old volumes (be careful with this)
    # docker volume prune -f
    
    log "Cleanup completed"
}

# Show logs function
show_logs() {
    cd "$DEPLOY_DIR"
    docker-compose logs -f --tail=50
}

# Stop services function
stop_services() {
    cd "$DEPLOY_DIR"
    docker-compose down
    log "Services stopped"
}

# Start services function
start_services() {
    cd "$DEPLOY_DIR"
    docker-compose up -d
    log "Services started"
}

# Status function
status() {
    cd "$DEPLOY_DIR"
    docker-compose ps
}

# Main script logic
case "${1:-deploy}" in
    deploy)
        deploy
        ;;
    rollback)
        rollback
        ;;
    cleanup)
        cleanup
        ;;
    logs)
        show_logs
        ;;
    stop)
        stop_services
        ;;
    start)
        start_services
        ;;
    status)
        status
        ;;
    health)
        health_check
        ;;
    *)
        echo "Usage: $0 {deploy|rollback|cleanup|logs|stop|start|status|health}"
        echo ""
        echo "Commands:"
        echo "  deploy   - Deploy latest version (default)"
        echo "  rollback - Rollback to previous version"
        echo "  cleanup  - Clean up old Docker resources"
        echo "  logs     - Show service logs"
        echo "  stop     - Stop all services"
        echo "  start    - Start all services"
        echo "  status   - Show service status"
        echo "  health   - Perform health check"
        exit 1
        ;;
esac
