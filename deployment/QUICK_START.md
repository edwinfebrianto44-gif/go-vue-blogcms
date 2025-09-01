# 🚀 Quick Start - Deploy in 5 Minutes

## One-Line Deployment

```bash
curl -fsSL https://raw.githubusercontent.com/your-username/go-vue-blogcms/main/deployment/quick-deploy.sh | bash -s your-domain.com
```

## Manual Steps

### 1. Setup VPS
```bash
# On your Ubuntu VPS
wget https://raw.githubusercontent.com/your-username/go-vue-blogcms/main/deployment/setup-vps.sh
chmod +x setup-vps.sh
./setup-vps.sh
```

### 2. Clone & Deploy
```bash
# Create app directory
sudo mkdir -p /opt/blogcms
sudo chown $USER:$USER /opt/blogcms
cd /opt/blogcms

# Clone repository
git clone https://github.com/your-username/go-vue-blogcms.git .
cd deployment

# Configure environment
cp .env.production .env
nano .env  # Edit DOMAIN and passwords

# Deploy
./deploy.sh
```

### 3. Configure Domain
Point your domain to VPS IP:
```
A Record: blog-api.mydomain.com -> YOUR_VPS_IP
```

### 4. Setup SSL (Production)
```bash
# Let's Encrypt SSL
sudo certbot certonly --standalone -d blog-api.mydomain.com
sudo cp /etc/letsencrypt/live/blog-api.mydomain.com/*.pem nginx/ssl/
docker-compose restart nginx
```

## 🎯 Result

- **API**: https://blog-api.mydomain.com
- **Health**: https://blog-api.mydomain.com/health
- **Admin**: https://admin.blog-api.mydomain.com

## 📋 What's Included

✅ **Backend Golang** dengan Gin framework
✅ **MySQL 8.0** dengan persistent storage  
✅ **Nginx** reverse proxy dengan SSL
✅ **Adminer** untuk database management
✅ **Auto backup** script
✅ **Monitoring** tools
✅ **Security** best practices

## 🔧 Management Commands

```bash
cd /opt/blogcms/deployment

./monitor.sh     # Check system status
./backup.sh      # Create database backup
./deploy.sh      # Update deployment
docker-compose logs -f  # View logs
```

## ⚡ Quick API Test

```bash
# Health check
curl https://blog-api.mydomain.com/health

# Register user
curl -X POST https://blog-api.mydomain.com/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"name":"Admin","email":"admin@example.com","password":"password123","role":"admin"}'

# Login
curl -X POST https://blog-api.mydomain.com/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@example.com","password":"password123"}'
```

Ready to go! 🎉
