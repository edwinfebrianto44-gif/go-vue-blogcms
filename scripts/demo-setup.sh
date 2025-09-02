#!/bin/bash

# BlogCMS Complete Demo Setup
# One-stop script for setting up a complete demo environment

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[$(date +'%H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%H:%M:%S')] WARNING: $1${NC}"
}

info() {
    echo -e "${BLUE}[$(date +'%H:%M:%S')] INFO: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%H:%M:%S')] ERROR: $1${NC}"
    exit 1
}

step() {
    echo -e "${PURPLE}[$(date +'%H:%M:%S')] STEP: $1${NC}"
}

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
DEMO_MODE="quick"
SKIP_BUILD=false
SKIP_SEED=false
OPEN_BROWSER=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --full)
            DEMO_MODE="full"
            shift
            ;;
        --skip-build)
            SKIP_BUILD=true
            shift
            ;;
        --skip-seed)
            SKIP_SEED=true
            shift
            ;;
        --open-browser)
            OPEN_BROWSER=true
            shift
            ;;
        -h|--help)
            echo "BlogCMS Complete Demo Setup"
            echo ""
            echo "Sets up a complete demo environment with one command"
            echo ""
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --full         Use comprehensive demo data seeder"
            echo "  --skip-build   Skip Docker build (use existing images)"
            echo "  --skip-seed    Skip demo data seeding"
            echo "  --open-browser Open browser after setup"
            echo "  -h, --help     Show this help message"
            echo ""
            echo "Quick Start:"
            echo "  $0                    # Quick demo setup"
            echo "  $0 --full            # Full demo with comprehensive data"
            echo "  $0 --open-browser    # Setup and open browser"
            exit 0
            ;;
        *)
            error "Unknown option: $1. Use -h for help."
            ;;
    esac
done

# Display banner
display_banner() {
    echo -e "${PURPLE}"
    echo "╔══════════════════════════════════════════════════════════════════════════════╗"
    echo "║                        BlogCMS Complete Demo Setup                          ║"
    echo "║               From Zero to Running Demo in Minutes                          ║"
    echo "╚══════════════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    echo -e "${BLUE}Configuration:${NC}"
    echo "  Demo Mode: $DEMO_MODE"
    echo "  Skip Build: $SKIP_BUILD"
    echo "  Skip Seed: $SKIP_SEED"
    echo "  Project Root: $PROJECT_ROOT"
    echo ""
}

# Check prerequisites
check_prerequisites() {
    step "Checking prerequisites..."
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        error "Docker is not installed. Please install Docker first."
    fi
    
    # Check Docker Compose
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        error "Docker Compose is not installed. Please install Docker Compose first."
    fi
    
    # Check if Docker is running
    if ! docker info &> /dev/null; then
        error "Docker is not running. Please start Docker first."
    fi
    
    log "✅ All prerequisites met"
}

# Cleanup existing containers
cleanup_existing() {
    step "Cleaning up existing containers..."
    
    cd "$PROJECT_ROOT"
    
    # Stop and remove existing containers
    if docker-compose ps -q &> /dev/null; then
        docker-compose down --volumes --remove-orphans 2>/dev/null || true
    fi
    
    # Clean up any orphaned containers
    docker container prune -f &> /dev/null || true
    
    log "✅ Cleanup completed"
}

# Build and start services
start_services() {
    step "Starting BlogCMS services..."
    
    cd "$PROJECT_ROOT"
    
    if [[ "$SKIP_BUILD" == true ]]; then
        info "Skipping build, using existing images"
        docker-compose up -d
    else
        info "Building and starting services (this may take a few minutes)"
        docker-compose up -d --build
    fi
    
    log "✅ Services started"
}

# Wait for services to be ready
wait_for_services() {
    step "Waiting for services to be ready..."
    
    local max_attempts=60
    local attempt=0
    
    # Wait for database
    info "Waiting for database..."
    while [[ $attempt -lt $max_attempts ]]; do
        if docker-compose exec -T db mysqladmin ping -h"localhost" -uroot -p"password" &>/dev/null; then
            break
        fi
        
        attempt=$((attempt + 1))
        if [[ $((attempt % 10)) -eq 0 ]]; then
            info "Still waiting for database... (${attempt}s)"
        fi
        sleep 1
    done
    
    if [[ $attempt -eq $max_attempts ]]; then
        error "Database failed to start within ${max_attempts} seconds"
    fi
    
    log "✅ Database is ready"
    
    # Wait for backend API
    info "Waiting for backend API..."
    attempt=0
    while [[ $attempt -lt $max_attempts ]]; do
        if curl -s http://localhost:8080/health &>/dev/null; then
            break
        fi
        
        attempt=$((attempt + 1))
        if [[ $((attempt % 10)) -eq 0 ]]; then
            info "Still waiting for API... (${attempt}s)"
        fi
        sleep 1
    done
    
    if [[ $attempt -eq $max_attempts ]]; then
        error "API failed to start within ${max_attempts} seconds"
    fi
    
    log "✅ Backend API is ready"
    
    # Wait for frontend
    info "Waiting for frontend..."
    attempt=0
    while [[ $attempt -lt $max_attempts ]]; do
        if curl -s http://localhost:3000 &>/dev/null; then
            break
        fi
        
        attempt=$((attempt + 1))
        if [[ $((attempt % 10)) -eq 0 ]]; then
            info "Still waiting for frontend... (${attempt}s)"
        fi
        sleep 1
    done
    
    if [[ $attempt -eq $max_attempts ]]; then
        error "Frontend failed to start within ${max_attempts} seconds"
    fi
    
    log "✅ Frontend is ready"
}

# Seed demo data
seed_demo_data() {
    if [[ "$SKIP_SEED" == true ]]; then
        info "Skipping demo data seeding as requested"
        return 0
    fi
    
    step "Seeding demo data..."
    
    cd "$PROJECT_ROOT"
    
    if [[ "$DEMO_MODE" == "full" ]]; then
        info "Using comprehensive demo data seeder"
        if [[ -f "scripts/seed-demo-data.sh" ]]; then
            bash scripts/seed-demo-data.sh --api-url http://localhost:8080
        else
            warn "Full demo seeder not found, using quick seeder"
            bash scripts/quick-seed.sh
        fi
    else
        info "Using quick demo data seeder"
        bash scripts/quick-seed.sh
    fi
    
    log "✅ Demo data seeded"
}

# Display service status
show_service_status() {
    step "Checking service status..."
    
    cd "$PROJECT_ROOT"
    
    echo ""
    echo -e "${BLUE}Docker Containers:${NC}"
    docker-compose ps
    
    echo ""
    echo -e "${BLUE}Service Health:${NC}"
    
    # Check database
    if docker-compose exec -T db mysqladmin ping -h"localhost" -uroot -p"password" &>/dev/null; then
        echo "  📊 Database: ${GREEN}✅ Running${NC}"
    else
        echo "  📊 Database: ${RED}❌ Not responding${NC}"
    fi
    
    # Check backend
    if curl -s http://localhost:8080/health &>/dev/null; then
        echo "  🔧 Backend API: ${GREEN}✅ Running${NC}"
    else
        echo "  🔧 Backend API: ${RED}❌ Not responding${NC}"
    fi
    
    # Check frontend
    if curl -s http://localhost:3000 &>/dev/null; then
        echo "  🌐 Frontend: ${GREEN}✅ Running${NC}"
    else
        echo "  🌐 Frontend: ${RED}❌ Not responding${NC}"
    fi
}

# Display access information
show_access_info() {
    echo ""
    echo -e "${GREEN}🎉 BlogCMS Demo is Ready!${NC}"
    echo ""
    echo -e "${BLUE}Access Your Demo:${NC}"
    echo "  🌐 Frontend Application: http://localhost:3000"
    echo "  🔌 Backend API: http://localhost:8080"
    echo "  📚 API Documentation: http://localhost:8080/swagger/index.html"
    echo "  🗄️  Database: localhost:3306"
    echo ""
    echo -e "${BLUE}Demo Accounts:${NC}"
    echo "  👑 Admin:  admin@demo.com  / Admin123!"
    echo "  ✏️  Editor: editor@demo.com / Editor123!"
    echo "  📝 Author: author@demo.com / Author123!"
    echo ""
    echo -e "${BLUE}Quick Actions:${NC}"
    echo "  📊 View Logs:    docker-compose logs -f"
    echo "  🔄 Restart:      docker-compose restart"
    echo "  🛑 Stop:         docker-compose down"
    echo "  🗑️  Clean Reset:  docker-compose down -v && $0"
    echo ""
    echo -e "${YELLOW}Pro Tips:${NC}"
    echo "  • Login as admin to access all features"
    echo "  • Try creating new posts and categories"
    echo "  • Test the comment system"
    echo "  • Explore the responsive design on mobile"
    echo "  • Check out the API documentation"
    echo ""
}

# Open browser if requested
open_browser() {
    if [[ "$OPEN_BROWSER" == true ]]; then
        step "Opening browser..."
        
        # Try different browser commands based on OS
        if command -v open &> /dev/null; then
            # macOS
            open http://localhost:3000
        elif command -v xdg-open &> /dev/null; then
            # Linux
            xdg-open http://localhost:3000
        elif command -v start &> /dev/null; then
            # Windows
            start http://localhost:3000
        else
            info "Please open http://localhost:3000 in your browser"
        fi
        
        log "✅ Browser opened"
    fi
}

# Main execution function
main() {
    display_banner
    
    # Execute setup steps
    check_prerequisites
    cleanup_existing
    start_services
    wait_for_services
    seed_demo_data
    
    # Show results
    show_service_status
    show_access_info
    open_browser
    
    echo -e "${GREEN}✨ Setup complete! Happy blogging! ✨${NC}"
}

# Error handling
trap 'error "Demo setup failed at line $LINENO"' ERR

# Check if script is being run from the correct directory
if [[ ! -f "$PROJECT_ROOT/docker-compose.yml" ]]; then
    error "docker-compose.yml not found. Please run this script from the project root or ensure the project structure is correct."
fi

# Run main function
main "$@"
