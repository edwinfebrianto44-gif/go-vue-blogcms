#!/bin/bash

# Blog CMS VPS Setup Script
# Ubuntu 20.04/22.04/24.04

set -e

echo "🚀 Starting Blog CMS VPS Setup..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   print_error "This script should not be run as root. Please run as a regular user with sudo privileges."
   exit 1
fi

# Update system
print_status "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install required packages
print_status "Installing required packages..."
sudo apt install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    software-properties-common \
    git \
    htop \
    nano \
    unzip \
    wget \
    ufw

# Install Docker
print_status "Installing Docker..."
if ! command -v docker &> /dev/null; then
    # Add Docker's official GPG key
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

    # Add Docker repository
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Update package index
    sudo apt update

    # Install Docker Engine
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    # Add user to docker group
    sudo usermod -aG docker $USER

    print_status "Docker installed successfully!"
else
    print_warning "Docker already installed"
fi

# Install Docker Compose (standalone)
print_status "Installing Docker Compose..."
if ! command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep tag_name | cut -d '"' -f 4)
    sudo curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    print_status "Docker Compose installed successfully!"
else
    print_warning "Docker Compose already installed"
fi

# Configure UFW firewall
print_status "Configuring firewall..."
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
echo "y" | sudo ufw enable

# Create application directory
APP_DIR="/opt/blogcms"
print_status "Creating application directory: $APP_DIR"
sudo mkdir -p $APP_DIR
sudo chown $USER:$USER $APP_DIR

# Generate SSL directory
print_status "Creating SSL directory..."
mkdir -p $APP_DIR/ssl

# Create logs directory
print_status "Creating logs directory..."
mkdir -p $APP_DIR/logs

# Install Certbot for SSL certificates
print_status "Installing Certbot..."
sudo apt install -y certbot python3-certbot-nginx

print_status "✅ VPS setup completed successfully!"
print_warning "🔄 Please log out and log back in for Docker group changes to take effect."

echo ""
echo "📋 Next Steps:"
echo "1. Clone your repository to $APP_DIR"
echo "2. Copy and configure environment files"
echo "3. Generate SSL certificates"
echo "4. Run the deployment script"
echo ""
echo "Example commands:"
echo "cd $APP_DIR"
echo "git clone https://github.com/your-username/go-vue-blogcms.git ."
echo "cd deployment"
echo "cp .env.production .env"
echo "# Edit .env with your configuration"
echo "nano .env"
echo "./deploy.sh"
