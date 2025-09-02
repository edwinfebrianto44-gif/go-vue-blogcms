# Deployment Guide

This guide covers the complete deployment process for the Go-Vue BlogCMS application.

## Architecture Overview

The application uses a modern containerized architecture:

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   GitHub        │    │   VPS/Server     │    │   CDN (Optional)│
│   ├─ Actions    │───▶│   ├─ nginx       │    │   ├─ CloudFront │
│   ├─ Registry   │    │   ├─ Go Backend  │    │   ├─ S3 Bucket  │
│   └─ Repository │    │   ├─ MySQL       │    │   └─ Static     │
└─────────────────┘    │   └─ Redis       │    └─────────────────┘
                       └──────────────────┘
```

## Prerequisites

### Server Requirements
- **OS**: Ubuntu 20.04+ or CentOS 8+
- **CPU**: 2+ cores
- **RAM**: 4GB+ (8GB recommended)
- **Storage**: 20GB+ SSD
- **Network**: Public IP with ports 80, 443, 22 open

### Software Requirements
- Docker 20.10+
- Docker Compose 2.0+
- Git
- Nginx (optional if using Docker nginx)

## Quick Start

### 1. Server Setup

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Create deployment user
sudo useradd -m -s /bin/bash deploy
sudo usermod -aG docker deploy
```

### 2. SSH Key Setup

```bash
# On your local machine, generate SSH key
ssh-keygen -t rsa -b 4096 -f ~/.ssh/blogcms-deploy

# Copy public key to server
ssh-copy-id -i ~/.ssh/blogcms-deploy.pub deploy@your-server-ip

# Test connection
ssh -i ~/.ssh/blogcms-deploy deploy@your-server-ip
```

### 3. GitHub Secrets Configuration

Add these secrets to your GitHub repository (Settings → Secrets → Actions):

```
VPS_HOST=your-server-ip
VPS_USER=deploy
VPS_SSH_KEY=<content of ~/.ssh/blogcms-deploy>
DB_HOST=db
DB_USER=blogcms_user
DB_PASSWORD=your-secure-password
DB_NAME=blogcms_db
JWT_SECRET=your-jwt-secret
```

### 4. Deploy

Push to main branch:
```bash
git push origin main
```

The GitHub Actions workflow will automatically:
1. Run tests
2. Build Docker images
3. Deploy to your server
4. Perform health checks

## Manual Deployment

If you prefer manual deployment:

### 1. Clone Repository

```bash
ssh deploy@your-server
git clone https://github.com/your-username/go-vue-blogcms.git /opt/blogcms
cd /opt/blogcms
```

### 2. Configure Environment

```bash
# Copy environment template
cp .env.example .env.production

# Edit with your values
nano .env.production
```

### 3. Deploy

```bash
# Make deployment script executable
chmod +x scripts/deploy.sh

# Run deployment
./scripts/deploy.sh deploy
```

## Service Management

### Using Docker Compose

```bash
# Start services
docker-compose up -d

# Stop services
docker-compose down

# View logs
docker-compose logs -f

# Check status
docker-compose ps

# Restart a service
docker-compose restart backend
```

### Using Deployment Script

```bash
# Deploy latest version
./scripts/deploy.sh deploy

# Check status
./scripts/deploy.sh status

# View logs
./scripts/deploy.sh logs

# Stop services
./scripts/deploy.sh stop

# Start services
./scripts/deploy.sh start

# Rollback
./scripts/deploy.sh rollback

# Cleanup old resources
./scripts/deploy.sh cleanup
```

## Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `DB_HOST` | Database host | `db` |
| `DB_USER` | Database user | `blogcms_user` |
| `DB_PASSWORD` | Database password | - |
| `DB_NAME` | Database name | `blogcms_db` |
| `JWT_SECRET` | JWT signing secret | - |
| `CORS_ORIGINS` | Allowed CORS origins | `http://localhost:3000` |
| `GIN_MODE` | Gin framework mode | `release` |
| `PORT` | Backend server port | `8080` |
| `UPLOAD_MAX_SIZE` | Max upload size (bytes) | `10485760` |
| `REDIS_HOST` | Redis host | `redis` |

### Nginx Configuration

The nginx configuration is included in the Docker setup. For custom domains:

1. Update `nginx/sites-available/blogcms`
2. Add SSL certificates
3. Configure DNS records

### SSL/HTTPS Setup

#### Using Let's Encrypt (Recommended)

```bash
# Install certbot
sudo apt install certbot python3-certbot-nginx

# Get certificate
sudo certbot --nginx -d yourdomain.com

# Test renewal
sudo certbot renew --dry-run

# Add to crontab for auto-renewal
echo "0 12 * * * /usr/bin/certbot renew --quiet" | sudo crontab -
```

#### Manual Certificate

```bash
# Create SSL directory
sudo mkdir -p /opt/ssl

# Copy your certificates
sudo cp your-cert.pem /opt/ssl/cert.pem
sudo cp your-key.pem /opt/ssl/key.pem

# Update docker-compose.yml to mount SSL directory
```

## Monitoring & Maintenance

### Health Checks

The application provides several health check endpoints:

- `http://your-domain/health` - Application health
- `http://your-domain/api/v1/health` - API health
- Database connection check included

### Logging

Logs are available through Docker:

```bash
# Application logs
docker-compose logs -f backend

# Nginx logs
docker-compose logs -f nginx

# Database logs
docker-compose logs -f db

# All logs
docker-compose logs -f
```

### Backups

#### Database Backup

```bash
# Manual backup
docker-compose exec db mysqldump -u blogcms_user -p blogcms_db > backup.sql

# Using deployment script (includes automated backups)
./scripts/deploy.sh deploy
```

#### Automated Backups

Add to crontab:

```bash
# Daily backup at 2 AM
0 2 * * * cd /opt/blogcms && docker-compose exec -T db mysqldump -u blogcms_user -p'your-password' blogcms_db > /opt/backups/backup_$(date +\%Y\%m\%d).sql
```

### Updates

#### Automatic Updates (GitHub Actions)

Updates happen automatically when you push to the main branch.

#### Manual Updates

```bash
cd /opt/blogcms
git pull origin main
./scripts/deploy.sh deploy
```

## Performance Optimization

### Resource Limits

Update `docker-compose.yml` with resource limits:

```yaml
services:
  backend:
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 1G
        reservations:
          cpus: '0.5'
          memory: 512M
```

### Database Optimization

```sql
-- Add indexes for better performance
CREATE INDEX idx_posts_created_at ON posts(created_at);
CREATE INDEX idx_posts_status ON posts(status);
CREATE INDEX idx_users_email ON users(email);
```

### Redis Caching

Enable Redis caching in your application:

```bash
# Redis is included in docker-compose.yml
# Configure your application to use redis:6379
```

## Troubleshooting

### Common Issues

#### 1. Service Won't Start

```bash
# Check logs
docker-compose logs service-name

# Check container status
docker-compose ps

# Restart service
docker-compose restart service-name
```

#### 2. Database Connection Issues

```bash
# Test database connection
docker-compose exec backend ping db

# Check database logs
docker-compose logs db

# Access database directly
docker-compose exec db mysql -u blogcms_user -p
```

#### 3. Permission Issues

```bash
# Fix file permissions
sudo chown -R deploy:deploy /opt/blogcms

# Fix Docker permissions
sudo usermod -aG docker deploy
```

#### 4. Port Already in Use

```bash
# Check what's using the port
sudo netstat -tulpn | grep :80

# Stop conflicting service
sudo systemctl stop apache2  # or nginx
```

### Performance Issues

#### High Memory Usage

```bash
# Check container resource usage
docker stats

# Limit container memory
# Add memory limits to docker-compose.yml
```

#### Slow Database Queries

```bash
# Enable slow query log
# Add to docker-compose.yml mysql environment:
MYSQL_SLOW_QUERY_LOG: 1
MYSQL_LONG_QUERY_TIME: 2

# Check slow queries
docker-compose exec db mysql -u root -p -e "SELECT * FROM mysql.slow_log;"
```

### Recovery Procedures

#### Database Recovery

```bash
# Restore from backup
docker-compose exec -T db mysql -u blogcms_user -p blogcms_db < backup.sql

# Check data integrity
docker-compose exec db mysql -u blogcms_user -p -e "CHECK TABLE posts, users, categories;"
```

#### Application Rollback

```bash
# Using deployment script
./scripts/deploy.sh rollback

# Manual rollback
git checkout previous-commit
docker-compose down
docker-compose up -d
```

## Security Considerations

### Server Security

```bash
# Update system regularly
sudo apt update && sudo apt upgrade -y

# Configure firewall
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 80
sudo ufw allow 443
sudo ufw enable

# Disable root login
sudo sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
sudo systemctl restart ssh
```

### Application Security

1. **Use HTTPS in production**
2. **Set strong JWT secrets**
3. **Configure CORS properly**
4. **Validate all inputs**
5. **Use rate limiting**
6. **Keep dependencies updated**

### Docker Security

```bash
# Run containers as non-root user
# Add to Dockerfile:
# USER 1001

# Use read-only filesystems where possible
# Add to docker-compose.yml:
# read_only: true

# Scan images for vulnerabilities
docker scan your-image:tag
```

## Production Checklist

Before going live:

- [ ] SSL certificate configured
- [ ] Domain DNS configured
- [ ] All secrets properly set
- [ ] Database backups configured
- [ ] Monitoring set up
- [ ] Log rotation configured
- [ ] Firewall configured
- [ ] Rate limiting enabled
- [ ] Security headers configured
- [ ] Error pages customized
- [ ] Health checks working
- [ ] Performance testing completed
- [ ] Recovery procedures tested

## Support

For issues and questions:

1. Check the logs first
2. Review this documentation
3. Check GitHub Issues
4. Test individual components
5. Verify configuration

Remember to never commit secrets to the repository and always use environment variables for sensitive data.
