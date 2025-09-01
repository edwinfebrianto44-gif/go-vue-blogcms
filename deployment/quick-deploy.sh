#!/bin/bash

# Quick Deploy Script - One command deployment
# Usage: ./quick-deploy.sh domain.com

set -e

DOMAIN=${1:-blog-api.mydomain.com}
APP_DIR="/opt/blogcms"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo -e "${BLUE}
╔══════════════════════════════════════════════════════════════╗
║                    Blog CMS Quick Deploy                     ║
║                      Ubuntu VPS Setup                       ║
╚══════════════════════════════════════════════════════════════╝${NC}"
}

print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   print_error "This script should not be run as root"
   exit 1
fi

print_header

echo "Domain: $DOMAIN"
echo "Installation directory: $APP_DIR"
echo ""

read -p "Continue with deployment? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
fi

# Step 1: System Setup
print_step "1/8 Setting up system dependencies..."
sudo apt update -y
sudo apt install -y curl git wget

# Step 2: Install Docker
print_step "2/8 Installing Docker..."
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    sudo usermod -aG docker $USER
    rm get-docker.sh
    print_status "Docker installed"
else
    print_status "Docker already installed"
fi

# Step 3: Install Docker Compose
print_step "3/8 Installing Docker Compose..."
if ! command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep tag_name | cut -d '"' -f 4)
    sudo curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    print_status "Docker Compose installed"
else
    print_status "Docker Compose already installed"
fi

# Step 4: Setup Firewall
print_step "4/8 Configuring firewall..."
sudo ufw --force enable
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
print_status "Firewall configured"

# Step 5: Create application directory
print_step "5/8 Setting up application directory..."
sudo mkdir -p $APP_DIR
sudo chown $USER:$USER $APP_DIR

# Step 6: Clone repository
print_step "6/8 Cloning repository..."
cd $APP_DIR
if [ -d ".git" ]; then
    git pull origin main
else
    git clone https://github.com/your-username/go-vue-blogcms.git .
fi
cd deployment

# Step 7: Configure environment
print_step "7/8 Configuring environment..."
if [ ! -f .env ]; then
    cp .env.production .env
    
    # Generate secure passwords
    DB_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
    ROOT_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
    JWT_SECRET=$(openssl rand -base64 48 | tr -d "=+/" | cut -c1-32)
    
    # Update .env file
    sed -i "s/your_secure_db_password_here/$DB_PASSWORD/g" .env
    sed -i "s/your_secure_root_password/$ROOT_PASSWORD/g" .env
    sed -i "s/your_super_secure_jwt_secret_min_32_chars/$JWT_SECRET/g" .env
    sed -i "s/blog-api.mydomain.com/$DOMAIN/g" .env
    
    print_status "Environment configured with secure passwords"
fi

# Step 8: Generate SSL and Deploy
print_step "8/8 Generating SSL and deploying..."

# Create SSL directory
mkdir -p nginx/ssl

# Generate self-signed certificate for immediate deployment
./generate-ssl.sh $DOMAIN

# Deploy application
docker-compose up -d --build

# Wait for services
print_status "Waiting for services to start..."
sleep 30

# Check status
print_status "Checking deployment status..."
docker-compose ps

echo ""
print_header
print_status "🎉 Deployment completed successfully!"
echo ""
echo "📝 Deployment Summary:"
echo "   Domain: https://$DOMAIN"
echo "   API Health: https://$DOMAIN/health"
echo "   Installation: $APP_DIR"
echo ""
echo "🔐 Security Information:"
echo "   Database password: $(grep DB_PASSWORD .env | cut -d'=' -f2)"
echo "   Root password: $(grep MYSQL_ROOT_PASSWORD .env | cut -d'=' -f2)"
echo "   JWT secret: $(grep JWT_SECRET .env | cut -d'=' -f2)"
echo ""
echo "⚠️  Important Next Steps:"
echo "   1. Point your domain $DOMAIN to this server IP"
echo "   2. Replace self-signed SSL with Let's Encrypt:"
echo "      sudo certbot certonly --standalone -d $DOMAIN"
echo "      sudo cp /etc/letsencrypt/live/$DOMAIN/fullchain.pem nginx/ssl/"
echo "      sudo cp /etc/letsencrypt/live/$DOMAIN/privkey.pem nginx/ssl/"
echo "      docker-compose restart nginx"
echo "   3. Save the passwords shown above in a secure location"
echo "   4. Test the API: curl -k https://$DOMAIN/health"
echo ""
echo "📚 Available commands:"
echo "   ./monitor.sh    - System monitoring"
echo "   ./backup.sh     - Database backup"
echo "   ./deploy.sh     - Re-deploy application"
echo ""
echo "📧 Setup automatic backups:"
echo "   crontab -e"
echo "   Add: 0 2 * * * $APP_DIR/deployment/backup.sh"
echo ""

# Test API
if curl -f -s -k https://$DOMAIN/health > /dev/null; then
    print_status "✅ API is responding!"
else
    print_warning "⚠️  API may still be starting. Check logs: docker-compose logs -f"
fi

print_status "Deployment log saved to: $APP_DIR/deployment/deploy.log"
