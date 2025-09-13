#!/bin/bash

# Blog CMS Auto Setup Script
echo "🚀 Starting Blog CMS Project Setup..."

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_info() {
    echo -e "${YELLOW}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Change to project directory
cd /home/edwin/applikasi/go-vue-blogcms

# Step 1: Clean up any existing containers
print_info "Cleaning up existing containers..."
docker-compose down -v 2>/dev/null || true

# Step 2: Start infrastructure services
print_info "Starting MySQL, Redis, and MinIO..."
docker-compose up -d mysql redis minio

# Wait for services to be ready
print_info "Waiting for services to initialize..."
sleep 30

# Step 3: Check MySQL is ready and import data
print_info "Checking MySQL status..."
while ! docker exec blogcms-mysql mysqladmin ping -h localhost -u root -pblogcms_root_2024 2>/dev/null; do
    echo "Waiting for MySQL to be ready..."
    sleep 10
done

print_status "MySQL is ready!"

# Step 4: Verify database and tables
print_info "Checking database schema..."
docker exec blogcms-mysql mysql -u root -pblogcms_root_2024 -e "USE blogcms; SHOW TABLES;" 2>/dev/null

# Count records
USER_COUNT=$(docker exec blogcms-mysql mysql -u root -pblogcms_root_2024 -e "USE blogcms; SELECT COUNT(*) FROM users;" -s -N 2>/dev/null || echo "0")
POST_COUNT=$(docker exec blogcms-mysql mysql -u root -pblogcms_root_2024 -e "USE blogcms; SELECT COUNT(*) FROM posts;" -s -N 2>/dev/null || echo "0")
CATEGORY_COUNT=$(docker exec blogcms-mysql mysql -u root -pblogcms_root_2024 -e "USE blogcms; SELECT COUNT(*) FROM categories;" -s -N 2>/dev/null || echo "0")

print_status "Database statistics:"
echo "  - Users: $USER_COUNT"
echo "  - Posts: $POST_COUNT"
echo "  - Categories: $CATEGORY_COUNT"

# Step 5: Setup MinIO bucket
print_info "Setting up MinIO bucket..."
sleep 5

# Install mc client if not exists
if ! command -v mc &> /dev/null; then
    print_info "Installing MinIO client..."
    curl -s https://dl.min.io/client/mc/release/linux-amd64/mc -o /tmp/mc
    chmod +x /tmp/mc
    sudo mv /tmp/mc /usr/local/bin/ 2>/dev/null || mv /tmp/mc ~/mc
    export PATH="$HOME:$PATH"
fi

# Configure MinIO
print_info "Configuring MinIO..."
mc alias set local http://localhost:9001 blogcms_minio blogcms_minio_2024 2>/dev/null || true
mc mb local/blogcms-uploads --ignore-existing 2>/dev/null || true
mc anonymous set public local/blogcms-uploads 2>/dev/null || true

# Step 6: Start backend
print_info "Building and starting backend..."
docker-compose up -d --build backend

# Wait for backend
print_info "Waiting for backend to be ready..."
sleep 45

# Step 7: Start frontend
print_info "Building and starting frontend..."
docker-compose up -d --build frontend

# Wait for frontend
sleep 30

# Step 8: Start nginx
print_info "Starting Nginx reverse proxy..."
docker-compose up -d nginx

# Final status check
print_info "Final status check..."
docker-compose ps

echo ""
print_status "🎉 Blog CMS Setup Complete!"
echo ""
echo "📊 Access Points:"
echo "  🌐 Frontend: http://localhost:3001"
echo "  🔌 Backend API: http://localhost:8081"
echo "  🗄️ MySQL: localhost:3307"
echo "  🚀 Redis: localhost:6380"
echo "  📁 MinIO Console: http://localhost:9002"
echo "  🌍 Production (Nginx): http://localhost"
echo ""
echo "🔐 Database Credentials:"
echo "  User: blogcms_user"
echo "  Password: blogcms_password_2024"
echo "  Database: blogcms"
echo ""
echo "📁 MinIO Credentials:"
echo "  Access Key: blogcms_minio"
echo "  Secret Key: blogcms_minio_2024"
echo ""

# Test API endpoint
print_info "Testing API health..."
if curl -f -s http://localhost:8081/api/v1/health > /dev/null 2>&1; then
    print_status "✅ Backend API is responding!"
else
    print_error "⚠️ Backend API not responding yet. Check logs: docker-compose logs backend"
fi

# Test frontend
print_info "Testing frontend..."
if curl -f -s http://localhost:3001 > /dev/null 2>&1; then
    print_status "✅ Frontend is responding!"
else
    print_error "⚠️ Frontend not responding yet. Check logs: docker-compose logs frontend"
fi

echo ""
print_status "Setup completed! Your Blog CMS is ready to use! 🚀"
