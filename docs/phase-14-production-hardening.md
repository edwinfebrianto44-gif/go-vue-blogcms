# Phase 14 — Hardening & Production Checklist (VPS)

Complete production deployment setup for BlogCMS with SSL/TLS, security hardening, backup automation, and operational procedures.

## 🎯 Acceptance Criteria

- ✅ SSL A grade (SSL Labs) with auto-renewal
- ✅ Daily backup files visible in S3/MinIO bucket
- ✅ UFW firewall configured (ports 22, 80, 443 only)
- ✅ Fail2ban protection active
- ✅ JWT secret rotation procedures
- ✅ Admin bootstrap CLI functional
- ✅ Automatic database migrations on startup

## 🚀 Quick Start

### One-Command Production Deployment

```bash
# Complete production setup
sudo ./scripts/deploy-production.sh \
  --api-domain api.yourdomain.com \
  --app-domain yourdomain.com \
  --email admin@yourdomain.com
```

### Manual Step-by-Step Setup

```bash
# 1. Security hardening
sudo ./scripts/security-hardening.sh

# 2. SSL/TLS setup
sudo ./scripts/setup-ssl.sh \
  --api-domain api.yourdomain.com \
  --app-domain yourdomain.com \
  --email admin@yourdomain.com

# 3. Environment initialization
sudo ./scripts/env-manager.sh init

# 4. Database migrations
./scripts/migrate-db.sh

# 5. Backup automation
sudo ./scripts/setup-backup.sh

# 6. Admin user creation
sudo ./scripts/admin-bootstrap.sh \
  --email admin@yourdomain.com
```

## 📁 Script Directory

```
scripts/
├── deploy-production.sh     # Complete production deployment
├── setup-ssl.sh            # SSL/TLS automation with Let's Encrypt
├── security-hardening.sh   # UFW firewall + fail2ban + SSH hardening
├── mysql-backup.sh          # MySQL backup with S3/MinIO support
├── setup-backup.sh          # Backup automation configuration
├── admin-bootstrap.sh       # First admin user creation
├── env-manager.sh           # Production .env management & JWT rotation
└── migrate-db.sh            # Automatic database migrations
```

## 🔒 SSL/TLS with Let's Encrypt

### Features
- **Automatic Certificate Provisioning**: Uses Certbot for Let's Encrypt certificates
- **Auto-Renewal**: Cron job checks and renews certificates automatically
- **SSL Grade A+**: Strong ciphers, HSTS, OCSP stapling, security headers
- **Monitoring**: Certificate expiry notifications and health checks
- **Multi-Domain Support**: Handles both API and app domains

### Configuration

```bash
# Setup SSL certificates
sudo ./scripts/setup-ssl.sh \
  --api-domain api.yourdomain.com \
  --app-domain yourdomain.com \
  --email admin@yourdomain.com \
  --staging  # Use for testing

# Check SSL status
sudo /usr/local/bin/check-ssl-expiry.sh

# Manual certificate renewal
sudo certbot renew --dry-run
```

### SSL Grade A+ Features
- TLS 1.2+ only
- Strong cipher suites (ChaCha20-Poly1305, AES-GCM)
- HSTS with preload
- OCSP stapling
- Security headers (CSP, X-Frame-Options, etc.)
- Perfect Forward Secrecy

## 🛡️ Security Hardening

### UFW Firewall
```bash
# View firewall status
sudo ufw status verbose

# Allow specific IP
sudo ufw allow from 1.2.3.4 to any port 22

# Deny specific IP
sudo ufw deny from 1.2.3.4
```

### Fail2ban Protection
```bash
# Check fail2ban status
sudo fail2ban-client status

# Check SSH jail
sudo fail2ban-client status sshd

# Unban IP address
sudo fail2ban-client set sshd unbanip 1.2.3.4
```

### SSH Hardening Features
- Root login disabled
- Password authentication disabled
- Key-based authentication only
- Strong ciphers and algorithms
- Connection rate limiting
- SSH banner with legal notice

### Security Monitoring
```bash
# Run security checks
sudo /usr/local/bin/security-monitor.sh

# Daily security report
sudo /usr/local/bin/daily-security-report.sh

# View security logs
sudo tail -f /var/log/security-monitor.log
```

## 💾 Backup Automation

### Backup Types & Retention
- **Daily**: 7-day retention
- **Weekly**: 30-day retention  
- **Monthly**: 365-day retention

### Features
- MySQL dumps with compression (gzip/xz)
- Optional AES-256 encryption
- S3/MinIO remote storage
- Email/Slack notifications
- Automatic cleanup of old backups
- Backup verification and restore testing

### Configuration

```bash
# Setup backup automation
sudo ./scripts/setup-backup.sh

# Configure S3/MinIO settings
sudo nano /etc/mysql-backup/backup.conf

# Run manual backup
sudo mysql-backup-daily

# Check backup status
mysql-backup-status

# Restore from backup
sudo mysql-backup-restore --backup-file /path/to/backup.sql.gz
```

### S3/MinIO Configuration

Edit `/etc/mysql-backup/backup.conf`:

```bash
# S3/MinIO Configuration
S3_ENDPOINT=https://s3.amazonaws.com  # or MinIO endpoint
S3_BUCKET=blogcms-backups
S3_ACCESS_KEY=your-access-key
S3_SECRET_KEY=your-secret-key

# Notification Settings
NOTIFICATION_EMAIL=admin@yourdomain.com
SLACK_WEBHOOK=https://hooks.slack.com/...
```

### Backup Commands
```bash
# Manual backups
sudo mysql-backup-daily
sudo mysql-backup-weekly
sudo mysql-backup-monthly

# Status and monitoring
mysql-backup-status
tail -f /var/log/mysql-backup.log

# Restore operations
sudo mysql-backup-restore --backup-file /var/backups/mysql/backup.sql.gz
```

## 👤 Admin User Management

### Bootstrap First Admin

```bash
# Interactive mode
sudo ./scripts/admin-bootstrap.sh

# Non-interactive mode
sudo ./scripts/admin-bootstrap.sh \
  --email admin@yourdomain.com \
  --name "Admin User" \
  --password "SecurePassword123!" \
  --non-interactive

# Auto-generate secure password
sudo ./scripts/admin-bootstrap.sh \
  --email admin@yourdomain.com \
  --name "Admin User"
# Will prompt to generate secure password
```

### Features
- Email validation
- Strong password requirements
- API and database creation methods
- Login testing
- Configuration file generation

## 🔐 Environment & JWT Management

### Initialize Production Environment

```bash
# Initialize production .env
sudo ./scripts/env-manager.sh init

# Validate configuration
sudo ./scripts/env-manager.sh validate

# Create backup
sudo ./scripts/env-manager.sh backup
```

### JWT Secret Rotation

```bash
# Rotate JWT secret safely
sudo ./scripts/env-manager.sh rotate-jwt

# View rotation history
sudo tail -f /var/log/jwt-rotation.log
```

### Environment Features
- Secure .env file generation
- Strong JWT secrets (64 characters)
- Database password generation
- Session secret management
- Encrypted backups with GPG
- Automatic permission management (600)

## 🗄️ Database Migration Automation

### Automatic Migrations on Startup

```bash
# Run migrations manually
./scripts/migrate-db.sh

# Check migration status
./scripts/migrate-db.sh --help

# Force migration re-run
./scripts/migrate-db.sh --force
```

### Migration Features
- Idempotent operations (safe to run multiple times)
- Database connection retry logic
- Migration tracking table
- Checksum verification
- Execution time monitoring
- Transaction safety
- Dangerous statement detection

### Migration File Format
```sql
-- migrations/20231201120000_create_users_table.sql
CREATE TABLE IF NOT EXISTS users (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    role ENUM('admin', 'editor', 'author') DEFAULT 'author',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

## 🔧 Production Configuration

### Nginx Configuration
- SSL termination
- Rate limiting
- Security headers
- Gzip compression
- Static file caching
- API proxy with timeouts
- Health check endpoints

### Docker Configuration
```yaml
# docker-compose.prod.yml
version: '3.8'
services:
  api:
    restart: unless-stopped
    environment:
      - APP_ENV=production
      - DEBUG=false
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 3
```

### Environment Variables
```bash
# Production .env configuration
APP_ENV=production
DEBUG=false
APP_PORT=8080

# Database
DB_HOST=localhost
DB_PORT=3306
DB_USER=blogcms
DB_PASSWORD=generated-secure-password
DB_NAME=blogcms

# Security
JWT_SECRET=generated-64-character-secret
SESSION_SECRET=generated-64-character-secret
CORS_ORIGINS=https://yourdomain.com

# Email (optional)
SMTP_HOST=smtp.example.com
SMTP_PORT=587
SMTP_USER=noreply@yourdomain.com
SMTP_PASSWORD=smtp-password
```

## 📊 Monitoring & Maintenance

### Health Checks
```bash
# API health
curl https://api.yourdomain.com/health

# Database connection
curl https://api.yourdomain.com/healthz

# Application readiness
curl https://api.yourdomain.com/readyz
```

### Log Management
```bash
# Application logs
docker-compose logs -f api

# Nginx logs
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log

# Security logs
sudo tail -f /var/log/security-monitor.log
sudo tail -f /var/log/auth.log

# Backup logs
sudo tail -f /var/log/mysql-backup.log
```

### System Monitoring
```bash
# Service status
sudo systemctl status nginx mysql docker fail2ban

# Resource usage
htop
df -h
free -h

# Security status
sudo ufw status
sudo fail2ban-client status
```

## 🚨 Troubleshooting

### SSL Issues
```bash
# Check certificate status
sudo certbot certificates

# Test renewal
sudo certbot renew --dry-run

# Manual renewal
sudo certbot renew --force-renewal

# Check SSL configuration
sudo nginx -t
openssl s_client -connect yourdomain.com:443
```

### Backup Issues
```bash
# Test database connection
mysql -h localhost -u root -p -e "SELECT 1;"

# Check backup configuration
mysql-backup-status

# Test S3/MinIO connection
mc alias set test https://your-endpoint access-key secret-key
mc ls test/bucket-name
```

### Migration Issues
```bash
# Check database connection
./scripts/migrate-db.sh --db-host localhost --db-user root

# View migration table
mysql -u root -p blogcms -e "SELECT * FROM schema_migrations ORDER BY applied_at DESC LIMIT 10;"

# Reset migration (caution!)
mysql -u root -p blogcms -e "DROP TABLE schema_migrations;"
```

### Security Issues
```bash
# Check fail2ban logs
sudo journalctl -u fail2ban -f

# View banned IPs
sudo fail2ban-client status sshd

# Check firewall rules
sudo ufw status numbered

# SSH connection issues
sudo tail -f /var/log/auth.log
```

## 📚 Additional Resources

### SSL Testing
- [SSL Labs Test](https://www.ssllabs.com/ssltest/)
- [Mozilla SSL Configuration Generator](https://ssl-config.mozilla.org/)

### Security Benchmarks
- [CIS Ubuntu Benchmarks](https://www.cisecurity.org/benchmark/ubuntu_linux)
- [NIST Cybersecurity Framework](https://www.nist.gov/cyberframework)

### Backup Best Practices
- [MySQL Backup Best Practices](https://dev.mysql.com/doc/refman/8.0/en/backup-and-recovery.html)
- [3-2-1 Backup Strategy](https://www.acronis.com/en-us/articles/3-2-1-backup-rule/)

## ✅ Production Checklist

### Pre-Deployment
- [ ] Domain DNS configured
- [ ] VPS with Ubuntu 20.04/22.04
- [ ] Root/sudo access
- [ ] Email for SSL certificates

### Deployment
- [ ] Run production deployment script
- [ ] Configure S3/MinIO backup storage
- [ ] Test SSL grade (A+ target)
- [ ] Verify firewall rules
- [ ] Test fail2ban protection
- [ ] Create admin user
- [ ] Test backup restoration

### Post-Deployment
- [ ] Monitor application logs
- [ ] Set up external monitoring
- [ ] Configure alerting
- [ ] Document admin credentials
- [ ] Schedule security reviews
- [ ] Test disaster recovery

---

🎉 **Phase 14 Complete!** Your BlogCMS is now production-ready with enterprise-grade security, SSL/TLS, automated backups, and comprehensive monitoring.
