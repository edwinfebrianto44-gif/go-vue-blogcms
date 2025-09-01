# 🚀 VPS Deployment Guide

Panduan lengkap untuk deploy Blog CMS Backend (Golang + MySQL) di VPS Linux Ubuntu.

## 📋 Prerequisites

- VPS Ubuntu 20.04/22.04/24.04
- Domain name (contoh: blog-api.mydomain.com)
- Minimal 1GB RAM, 1 CPU Core, 20GB Storage
- SSH access ke VPS

## 🔧 Step 1: Initial VPS Setup

### 1.1 Connect ke VPS
```bash
ssh root@your-vps-ip
# atau
ssh username@your-vps-ip
```

### 1.2 Create User (jika menggunakan root)
```bash
adduser blogcms
usermod -aG sudo blogcms
su - blogcms
```

### 1.3 Run Setup Script
```bash
# Download dan jalankan setup script
curl -fsSL https://raw.githubusercontent.com/your-username/go-vue-blogcms/main/deployment/setup-vps.sh -o setup-vps.sh
chmod +x setup-vps.sh
./setup-vps.sh
```

**Atau manual setup:**
```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
sudo usermod -aG docker $USER

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Install additional tools
sudo apt install -y git nginx certbot python3-certbot-nginx ufw htop

# Configure firewall
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw --force enable
```

## 📁 Step 2: Clone Repository

### 2.1 Create Application Directory
```bash
sudo mkdir -p /opt/blogcms
sudo chown $USER:$USER /opt/blogcms
cd /opt/blogcms
```

### 2.2 Clone Repository
```bash
git clone https://github.com/your-username/go-vue-blogcms.git .
cd deployment
```

## ⚙️ Step 3: Configuration

### 3.1 Environment Configuration
```bash
# Copy environment template
cp .env.production .env

# Edit configuration
nano .env
```

**Konfigurasi penting dalam .env:**
```bash
# Database Configuration
DB_NAME=blogcms_prod
DB_USER=blogcms_user
DB_PASSWORD=your_secure_password_here    # GANTI!
MYSQL_ROOT_PASSWORD=your_root_password   # GANTI!

# JWT Configuration
JWT_SECRET=your_super_secure_jwt_secret_min_32_chars  # GANTI!

# Domain Configuration
DOMAIN=blog-api.mydomain.com             # GANTI dengan domain Anda!
```

### 3.2 DNS Configuration
Pastikan domain menunjuk ke IP VPS Anda:
```
A Record: blog-api.mydomain.com -> YOUR_VPS_IP
A Record: admin.blog-api.mydomain.com -> YOUR_VPS_IP  (optional untuk Adminer)
```

## 🔐 Step 4: SSL Certificate

### 4.1 Let's Encrypt (Production - Recommended)
```bash
# Generate SSL certificate
sudo certbot certonly --standalone -d blog-api.mydomain.com

# Copy certificates
sudo cp /etc/letsencrypt/live/blog-api.mydomain.com/fullchain.pem nginx/ssl/
sudo cp /etc/letsencrypt/live/blog-api.mydomain.com/privkey.pem nginx/ssl/
sudo chown $USER:$USER nginx/ssl/*
```

### 4.2 Self-Signed (Development)
```bash
# Generate self-signed certificate
./generate-ssl.sh blog-api.mydomain.com
```

## 🚢 Step 5: Deploy Application

### 5.1 Run Deployment
```bash
# Jalankan deployment script
./deploy.sh
```

**Atau manual deployment:**
```bash
# Build dan start services
docker-compose up -d --build

# Check status
docker-compose ps
docker-compose logs -f
```

### 5.2 Verify Deployment
```bash
# Check API health
curl -k https://blog-api.mydomain.com/health

# Check container status
docker-compose ps

# View logs
docker-compose logs backend
```

## 📊 Step 6: Monitoring & Maintenance

### 6.1 System Monitoring
```bash
# Run monitoring script
./monitor.sh

# View live logs
docker-compose logs -f

# Check resource usage
docker stats
```

### 6.2 Database Backup
```bash
# Manual backup
./backup.sh

# Setup automated backup (crontab)
crontab -e
# Add line:
0 2 * * * /opt/blogcms/deployment/backup.sh
```

### 6.3 SSL Certificate Renewal
```bash
# Manual renewal
sudo certbot renew

# Auto renewal (crontab)
crontab -e
# Add line:
0 12 * * * /usr/bin/certbot renew --quiet
```

## 🔧 Useful Commands

### Application Management
```bash
# Start services
docker-compose up -d

# Stop services
docker-compose down

# Restart services
docker-compose restart

# Update application
git pull origin main
docker-compose up -d --build

# View logs
docker-compose logs -f [service_name]

# Execute commands in container
docker-compose exec backend sh
docker-compose exec mysql mysql -u root -p
```

### Database Management
```bash
# Connect to MySQL
docker-compose exec mysql mysql -u root -p

# Create backup
./backup.sh

# Restore backup
gunzip -c backups/blogcms_backup_YYYYMMDD_HHMMSS.sql.gz | docker-compose exec -T mysql mysql -u root -p blogcms_prod
```

### System Maintenance
```bash
# Check disk usage
df -h

# Clean Docker images
docker system prune -a

# Update system
sudo apt update && sudo apt upgrade -y

# Check logs
sudo journalctl -u docker
```

## 🌐 Accessing Services

- **API**: https://blog-api.mydomain.com
- **Health Check**: https://blog-api.mydomain.com/health
- **API Documentation**: https://blog-api.mydomain.com/api/v1/
- **Database Admin** (optional): https://admin.blog-api.mydomain.com

## 🔒 Security Best Practices

### 1. Environment Security
```bash
# Set proper file permissions
chmod 600 .env
chmod 700 nginx/ssl/

# Use strong passwords
# JWT secret minimum 32 characters
# Database passwords minimum 16 characters
```

### 2. Firewall Configuration
```bash
sudo ufw status
sudo ufw allow from trusted-ip to any port 3306  # MySQL (optional)
```

### 3. Regular Updates
```bash
# Update system monthly
sudo apt update && sudo apt upgrade -y

# Update Docker images
docker-compose pull
docker-compose up -d --build
```

### 4. Monitoring
```bash
# Setup log rotation
sudo nano /etc/logrotate.d/docker

# Monitor failed login attempts
sudo fail2ban-client status
```

## 📝 API Endpoints

### Authentication
```bash
# Register user
curl -X POST https://blog-api.mydomain.com/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"name":"Test User","email":"test@example.com","password":"password123","role":"author"}'

# Login
curl -X POST https://blog-api.mydomain.com/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}'
```

### Posts
```bash
# List posts
curl https://blog-api.mydomain.com/api/v1/posts

# Create post (requires auth)
curl -X POST https://blog-api.mydomain.com/api/v1/posts \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -d '{"title":"Test Post","content":"Content here","category_id":1}'
```

## 🆘 Troubleshooting

### Common Issues

**1. Container won't start**
```bash
# Check logs
docker-compose logs [service_name]

# Check resource usage
docker stats
free -h
df -h
```

**2. Database connection error**
```bash
# Check MySQL container
docker-compose logs mysql

# Test connection
docker-compose exec mysql mysql -u root -p

# Reset database
docker-compose down -v
docker-compose up -d
```

**3. SSL certificate issues**
```bash
# Check certificate
openssl x509 -in nginx/ssl/fullchain.pem -text -noout

# Regenerate certificate
./generate-ssl.sh your-domain.com
```

**4. API not responding**
```bash
# Check backend logs
docker-compose logs backend

# Check nginx configuration
docker-compose exec nginx nginx -t

# Restart services
docker-compose restart
```

**5. Out of disk space**
```bash
# Clean Docker
docker system prune -a

# Clean logs
sudo journalctl --vacuum-time=7d

# Clean old backups
find backups/ -name "*.gz" -mtime +7 -delete
```

## 📞 Support

Jika mengalami masalah:

1. Check logs: `docker-compose logs -f`
2. Run monitor: `./monitor.sh`
3. Check troubleshooting section
4. Create issue di repository GitHub

## 🔄 Updates

Untuk update aplikasi:
```bash
cd /opt/blogcms
git pull origin main
cd deployment
docker-compose up -d --build
```

## 📈 Performance Tuning

### Database Optimization
```bash
# Edit MySQL configuration
nano mysql/conf.d/mysql.cnf

# Restart MySQL
docker-compose restart mysql
```

### Nginx Optimization
```bash
# Edit Nginx configuration
nano nginx/nginx.conf

# Test configuration
docker-compose exec nginx nginx -t

# Reload configuration
docker-compose exec nginx nginx -s reload
```

Deployment sukses! 🎉
