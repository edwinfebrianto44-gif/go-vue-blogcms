#!/bin/bash

# Blog CMS Deployment Script
# This script deploys the Blog CMS application using Docker Compose

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}$1${NC}"
}

# Check if .env file exists
if [ ! -f .env ]; then
    print_error ".env file not found!"
    print_status "Please copy and configure the environment file:"
    echo "cp .env.production .env"
    echo "nano .env"
    exit 1
fi

# Load environment variables
source .env

print_header "🚀 Deploying Blog CMS Application"
echo "Domain: $DOMAIN"
echo ""

# Create necessary directories
print_status "Creating necessary directories..."
mkdir -p nginx/ssl nginx/logs mysql/logs

# Generate SSL certificates if they don't exist
if [ ! -f "nginx/ssl/fullchain.pem" ] || [ ! -f "nginx/ssl/privkey.pem" ]; then
    print_warning "SSL certificates not found. Please generate them first:"
    echo ""
    echo "Option 1: Using Let's Encrypt (Recommended)"
    echo "sudo certbot certonly --standalone -d $DOMAIN"
    echo "sudo cp /etc/letsencrypt/live/$DOMAIN/fullchain.pem nginx/ssl/"
    echo "sudo cp /etc/letsencrypt/live/$DOMAIN/privkey.pem nginx/ssl/"
    echo "sudo chown \$USER:\$USER nginx/ssl/*"
    echo ""
    echo "Option 2: Using self-signed certificates (Development only)"
    echo "./generate-ssl.sh $DOMAIN"
    echo ""
    read -p "Do you want to continue with self-signed certificates for development? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_status "Generating self-signed certificates..."
        ./generate-ssl.sh $DOMAIN
    else
        print_error "SSL certificates required. Please generate them and run this script again."
        exit 1
    fi
fi

# Create htpasswd file for Adminer if it doesn't exist
if [ ! -f "nginx/.htpasswd" ]; then
    print_status "Creating htpasswd file for Adminer access..."
    read -p "Enter username for database admin access: " admin_user
    read -s -p "Enter password for database admin access: " admin_pass
    echo
    echo "$admin_user:$(openssl passwd -apr1 $admin_pass)" > nginx/.htpasswd
fi

# Pull latest changes
print_status "Pulling latest changes from repository..."
cd ..
git pull origin main
cd deployment

# Stop existing containers
print_status "Stopping existing containers..."
docker-compose down --remove-orphans

# Remove old images (optional)
read -p "Do you want to remove old Docker images to save space? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_status "Removing unused Docker images..."
    docker image prune -f
fi

# Build and start services
print_status "Building and starting services..."
docker-compose up -d --build

# Wait for services to be healthy
print_status "Waiting for services to be healthy..."
sleep 30

# Check service status
print_status "Checking service status..."
docker-compose ps

# Test API endpoint
print_status "Testing API endpoint..."
sleep 10
if curl -f -s https://$DOMAIN/health > /dev/null; then
    print_status "✅ API is responding successfully!"
else
    print_warning "⚠️  API may still be starting up. Check logs if needed."
fi

# Show logs
print_status "Recent logs:"
docker-compose logs --tail=20

print_header "🎉 Deployment completed!"
echo ""
echo "🌐 Application URLs:"
echo "   API: https://$DOMAIN"
echo "   Health Check: https://$DOMAIN/health"
echo "   Database Admin: https://admin.$DOMAIN (if configured)"
echo ""
echo "📊 Useful commands:"
echo "   View logs: docker-compose logs -f"
echo "   Restart services: docker-compose restart"
echo "   Stop services: docker-compose down"
echo "   Update app: git pull && docker-compose up -d --build"
echo ""
echo "🔐 Security reminders:"
echo "   - Change default passwords in .env file"
echo "   - Keep SSL certificates updated"
echo "   - Regular database backups"
echo "   - Monitor application logs"
