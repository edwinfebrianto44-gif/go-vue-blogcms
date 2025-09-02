# Production Deployment Guide

This guide covers the complete production deployment of BlogCMS with enterprise-grade security, SSL automation, and monitoring.

## 📋 Prerequisites

- Ubuntu 20.04+ VPS
- Domain name with DNS access
- Non-root user with sudo privileges
- Docker and Docker Compose installed

## 🔒 Phase 14: Production Hardening Checklist

### 1. SSL & Domain Configuration
- ✅ Let's Encrypt SSL certificates with auto-renewal
- ✅ A-grade SSL rating configuration
- ✅ HSTS headers for security
- ✅ Dual domain setup (api.domain.com & app.domain.com)

### 2. Security Hardening
- ✅ UFW firewall (ports 22, 80, 443 only)
- ✅ Fail2ban intrusion prevention
- ✅ Rate limiting and DDoS protection
- ✅ Security headers implementation
- ✅ Automatic security updates

### 3. Production Environment Management
- ✅ Secure .env.production (not in git)
- ✅ JWT secret rotation procedures
- ✅ Database password management
- ✅ Redis authentication

### 4. Backup & Recovery
- ✅ Daily MySQL backups to S3/MinIO
- ✅ 7-30 day retention policies
- ✅ Backup verification and monitoring
- ✅ Point-in-time recovery capability

### 5. Operations & Monitoring
- ✅ Admin bootstrap CLI script
- ✅ Idempotent auto-migrations
- ✅ Health check endpoints
- ✅ Production monitoring
- ✅ Log rotation and management

## 🚀 Quick Deployment

### Step 1: Run Production Hardening
```bash
# Download and run hardening script
chmod +x scripts/production-hardening.sh
./scripts/production-hardening.sh
```

This script will:
- Install and configure UFW firewall
- Setup Fail2ban intrusion prevention
- Generate Let's Encrypt SSL certificates
- Configure automatic security updates
- Setup log rotation

### Step 2: Deploy Application
```bash
# Deploy with SSL and production configuration
chmod +x scripts/production-setup.sh
./scripts/production-setup.sh
```

This script will:
- Create production environment configuration
- Generate secure passwords and JWT secrets
- Deploy with Docker Compose
- Configure nginx with SSL
- Setup backup and monitoring

### Step 3: Bootstrap Admin User
```bash
# Create first admin user
/opt/blogcms/scripts/bootstrap-admin.sh
```

## 📁 Directory Structure

```
/opt/blogcms/
├── .env.production          # Production environment (secure)
├── docker-compose.production.yml
├── nginx/
│   └── nginx.conf          # SSL-enabled nginx config
├── logs/                   # Application logs
├── uploads/                # User uploads
├── backups/               # Local backups
└── scripts/
    ├── production-backup.sh    # Daily backup script
    ├── bootstrap-admin.sh      # Admin user creation
    ├── rotate-jwt-secret.sh    # JWT rotation
    ├── auto-migrate.sh         # Database migrations
    └── monitor-production.sh   # Health monitoring
```

## 🔑 Security Features

### SSL Configuration
- **Protocols**: TLS 1.2, TLS 1.3
- **Ciphers**: Modern cipher suite for A+ rating
- **HSTS**: 1-year max-age with includeSubDomains
- **OCSP Stapling**: Enabled for performance

### Firewall Rules
```bash
# Only allow essential ports
ufw allow 22/tcp    # SSH
ufw allow 80/tcp    # HTTP (redirects to HTTPS)
ufw allow 443/tcp   # HTTPS
ufw enable
```

### Rate Limiting
- **API**: 10 requests/second per IP
- **App**: 20 requests/second per IP
- **Burst**: Configurable burst allowance

### Security Headers
```nginx
X-Frame-Options: DENY
X-Content-Type-Options: nosniff
X-XSS-Protection: 1; mode=block
Referrer-Policy: strict-origin-when-cross-origin
Content-Security-Policy: default-src 'self'; ...
Strict-Transport-Security: max-age=31536000; includeSubDomains
```

## 💾 Backup Strategy

### Automated Daily Backups
- **Schedule**: 2:00 AM daily via cron
- **Method**: mysqldump with compression
- **Storage**: Local + S3/MinIO
- **Retention**: 30 days (configurable)

### Backup Verification
```bash
# Check backup status
tail -f /opt/blogcms/logs/backup.log

# List recent backups
ls -la /opt/blogcms/backups/

# Verify S3 uploads
aws s3 ls s3://your-bucket/backups/
```

### Restore Procedure
```bash
# Restore from local backup
gunzip -c /opt/blogcms/backups/blogcms_backup_YYYYMMDD_HHMMSS.sql.gz | \
docker-compose -f /opt/blogcms/docker-compose.production.yml exec -T db \
mysql -u$DB_USER -p$DB_PASSWORD $DB_NAME

# Restore from S3
aws s3 cp s3://your-bucket/backups/blogcms_backup_YYYYMMDD_HHMMSS.sql.gz - | \
gunzip -c | docker-compose -f /opt/blogcms/docker-compose.production.yml exec -T db \
mysql -u$DB_USER -p$DB_PASSWORD $DB_NAME
```

## 🔄 JWT Secret Rotation

### Manual Rotation
```bash
/opt/blogcms/scripts/rotate-jwt-secret.sh
```

### Scheduled Rotation (Monthly)
```bash
# Add to crontab for monthly rotation
0 2 1 * * /opt/blogcms/scripts/rotate-jwt-secret.sh
```

**Note**: JWT rotation invalidates all existing tokens, requiring users to re-authenticate.

## 📊 Monitoring & Health Checks

### Health Endpoints
- **API Health**: `https://api.domain.com/healthz`
- **API Ready**: `https://api.domain.com/readyz`
- **Detailed Health**: `https://api.domain.com/health`

### Monitoring Script
```bash
# Run manual health check
/opt/blogcms/scripts/monitor-production.sh

# View monitoring logs
tail -f /opt/blogcms/logs/monitor.log
```

### Automated Monitoring
- **Frequency**: Every 5 minutes via cron
- **Checks**: Disk, memory, containers, SSL, endpoints
- **Alerts**: Logged to monitoring log

## 🛠 Operational Commands

### Container Management
```bash
cd /opt/blogcms

# View service status
docker-compose -f docker-compose.production.yml ps

# View logs
docker-compose -f docker-compose.production.yml logs -f

# Restart services
docker-compose -f docker-compose.production.yml restart

# Update application
docker-compose -f docker-compose.production.yml pull
docker-compose -f docker-compose.production.yml up -d
```

### SSL Certificate Management
```bash
# Check certificate expiration
openssl x509 -in /etc/letsencrypt/live/api.domain.com/cert.pem -noout -dates

# Test auto-renewal
sudo certbot renew --dry-run

# Force renewal
sudo certbot renew --force-renewal
```

### Firewall Management
```bash
# Check firewall status
sudo ufw status verbose

# View blocked attempts
sudo fail2ban-client status

# Unban IP address
sudo fail2ban-client set sshd unbanip IP_ADDRESS
```

## 🚨 Troubleshooting

### Common Issues

#### SSL Certificate Issues
```bash
# Check certificate validity
curl -I https://api.domain.com
curl -I https://app.domain.com

# Regenerate certificates
sudo certbot delete --cert-name api.domain.com
sudo certbot certonly --nginx -d api.domain.com
```

#### Container Health Issues
```bash
# Check container logs
docker-compose -f /opt/blogcms/docker-compose.production.yml logs app

# Restart unhealthy containers
docker-compose -f /opt/blogcms/docker-compose.production.yml restart app
```

#### Database Connection Issues
```bash
# Test database connectivity
docker-compose -f /opt/blogcms/docker-compose.production.yml exec db \
mysql -u$DB_USER -p$DB_PASSWORD -e "SELECT 1"
```

### Log Locations
- **Application**: `/opt/blogcms/logs/app.log`
- **Nginx**: `/opt/blogcms/logs/nginx/`
- **Backup**: `/opt/blogcms/logs/backup.log`
- **Monitoring**: `/opt/blogcms/logs/monitor.log`
- **Migration**: `/opt/blogcms/logs/migration.log`

## 🔧 Maintenance

### Daily Tasks (Automated)
- ✅ Security updates via unattended-upgrades
- ✅ Database backups at 2:00 AM
- ✅ Health monitoring every 5 minutes
- ✅ Log rotation for size management

### Weekly Tasks
- Review backup integrity
- Check SSL certificate expiration
- Review fail2ban logs for patterns
- Monitor disk space usage

### Monthly Tasks
- Rotate JWT secrets
- Review and update security patches
- Performance optimization review
- Backup restore testing

## 🎯 Performance Optimization

### Nginx Optimizations
- **Gzip compression**: Enabled for text assets
- **Static file caching**: 1-year expiration
- **Keep-alive connections**: Enabled
- **Worker processes**: Auto-detected

### Database Optimizations
- **Connection pooling**: Configured in application
- **Query optimization**: Indexed frequently used fields
- **Backup optimization**: Single transaction dumps

### Security Optimizations
- **Rate limiting**: Per-IP request limits
- **Connection limits**: Prevent resource exhaustion
- **Header security**: Comprehensive security headers

## 📞 Support

For production issues:
1. Check monitoring logs first
2. Review container health status
3. Verify SSL certificate validity
4. Check firewall and fail2ban logs
5. Review backup status

**Emergency Procedures**:
- Database corruption: Restore from latest backup
- SSL expiration: Force certificate renewal
- Security breach: Rotate all secrets immediately
- Performance issues: Scale resources or optimize queries

This production setup provides enterprise-grade security, monitoring, and reliability for your BlogCMS deployment.
