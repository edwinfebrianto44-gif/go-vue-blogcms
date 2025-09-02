# BlogCMS Production Scripts

This directory contains all scripts for production deployment, security hardening, backup automation, demo data seeding, and operational management.

## 📁 Script Overview

### Production & Deployment
| Script | Purpose | Usage |
|--------|---------|-------|
| `deploy-production.sh` | Complete production deployment | One-command VPS setup |
| `setup-ssl.sh` | SSL/TLS with Let's Encrypt | Automatic certificate management |
| `security-hardening.sh` | UFW + fail2ban + SSH hardening | Security baseline configuration |
| `mysql-backup.sh` | MySQL backup with S3/MinIO | Automated database backups |
| `setup-backup.sh` | Backup automation setup | Configure backup schedules |
| `admin-bootstrap.sh` | First admin user creation | Bootstrap admin account |
| `env-manager.sh` | Environment & JWT management | Production config management |
| `migrate-db.sh` | Database migration automation | Idempotent schema updates |

### Demo & Development
| Script | Purpose | Usage |
|--------|---------|-------|
| `demo-setup.sh` | Complete demo environment setup | One-command demo deployment |
| `seed-demo-data.sh` | Comprehensive demo data seeder | Realistic content generation |
| `quick-seed.sh` | Quick demo data for development | Fast demo content creation |
| `generate-portfolio-assets.sh` | Portfolio screenshot generator | Create showcase materials |
| `cleanup.sh` | Project file organization | Clean unused documentation |

## 🚀 Quick Start

### Complete Demo Setup (Recommended)
```bash
# One command for complete demo environment
./scripts/demo-setup.sh --open-browser

# Options:
./scripts/demo-setup.sh --full          # Comprehensive demo data
./scripts/demo-setup.sh --skip-build    # Use existing images
./scripts/demo-setup.sh --skip-seed     # Skip demo data
```

### Complete Production Setup
```bash
# One command to rule them all
sudo ./scripts/deploy-production.sh \
  --api-domain api.yourdomain.com \
  --app-domain yourdomain.com \
  --email admin@yourdomain.com
```

### Demo Data & Development

#### Quick Demo Data
```bash
# Fast demo setup for development
./scripts/quick-seed.sh
```

#### Comprehensive Demo Data
```bash
# Full demo data with realistic content
./scripts/seed-demo-data.sh --api-url http://localhost:8080
```

#### Portfolio Assets
```bash
# Generate screenshot resources and automation
./scripts/generate-portfolio-assets.sh

# Create project structure documentation
./scripts/cleanup.sh --keep-docs
```

### Individual Script Usage

#### SSL/TLS Setup
```bash
sudo ./scripts/setup-ssl.sh \
  --api-domain api.yourdomain.com \
  --app-domain yourdomain.com \
  --email admin@yourdomain.com
```

#### Security Hardening
```bash
sudo ./scripts/security-hardening.sh \
  --ssh-port 22 \
  --fail2ban-maxretry 5
```

#### Backup Configuration
```bash
sudo ./scripts/setup-backup.sh
# Then edit /etc/mysql-backup/backup.conf
```

#### Admin User Creation
```bash
sudo ./scripts/admin-bootstrap.sh \
  --email admin@yourdomain.com \
  --name "Admin User"
```

## 📋 Prerequisites

### System Requirements
- Ubuntu 20.04/22.04 LTS
- Root or sudo access
- Domain names with DNS configured
- Email address for SSL certificates

### Required Packages
The scripts will install these automatically:
- Docker & Docker Compose
- Nginx
- MySQL client
- Certbot (Let's Encrypt)
- UFW (Uncomplicated Firewall)
- Fail2ban
- MinIO client (mc)
- OpenSSL
- curl, wget, mailutils

## 🔧 Configuration Files

### Environment Configuration
```bash
# Production environment
/path/to/project/.env

# Backup configuration
/etc/mysql-backup/backup.conf

# Admin configuration
/etc/blogcms/admin.conf
```

### Generated Scripts
```bash
# Backup commands
/usr/local/bin/mysql-backup-daily
/usr/local/bin/mysql-backup-weekly
/usr/local/bin/mysql-backup-monthly
/usr/local/bin/mysql-backup-status
/usr/local/bin/mysql-backup-restore

# Security monitoring
/usr/local/bin/security-monitor.sh
/usr/local/bin/daily-security-report.sh

# SSL monitoring
/usr/local/bin/check-ssl-expiry.sh
```

## 📊 Monitoring & Logs

### Log Files
```bash
# Application logs
docker-compose logs -f

# System logs
/var/log/mysql-backup.log
/var/log/security-monitor.log
/var/log/jwt-rotation.log
/var/log/db-migrations.log

# Web server logs
/var/log/nginx/access.log
/var/log/nginx/error.log

# System security
/var/log/auth.log
/var/log/fail2ban.log
```

### Status Commands
```bash
# Backup status
mysql-backup-status

# Security status
sudo /usr/local/bin/daily-security-report.sh

# SSL certificate status
sudo /usr/local/bin/check-ssl-expiry.sh

# Service status
sudo systemctl status nginx mysql docker fail2ban ufw
```

## 🛡️ Security Features

### Firewall (UFW)
- Default deny incoming
- Allow ports: 22 (SSH), 80 (HTTP), 443 (HTTPS)
- IPv6 support configurable
- Custom SSH port support

### Intrusion Prevention (Fail2ban)
- SSH brute force protection
- Nginx rate limiting protection
- Custom BlogCMS API protection
- Automatic IP banning
- Email notifications

### SSH Hardening
- Root login disabled
- Password authentication disabled
- Key-based authentication only
- Strong cipher suites
- Connection rate limiting
- Security banner

### SSL/TLS Security
- Let's Encrypt certificates
- Automatic renewal
- SSL Grade A+ configuration
- HSTS with preload
- OCSP stapling
- Strong cipher suites
- Security headers

## 💾 Backup System

### Backup Types
- **Daily**: 7-day retention, runs at 2 AM
- **Weekly**: 30-day retention, runs Sunday 3 AM
- **Monthly**: 365-day retention, runs 1st of month 4 AM

### Features
- MySQL dumps with full schema
- Gzip/XZ compression
- AES-256 encryption (optional)
- S3/MinIO remote storage
- Checksum verification
- Email/Slack notifications
- Automatic cleanup

### Backup Configuration
Edit `/etc/mysql-backup/backup.conf`:
```bash
# Database settings
DB_HOST=localhost
DB_PORT=3306
DB_USER=root
DB_PASSWORD=your-password
DB_NAME=blogcms

# S3/MinIO settings
S3_ENDPOINT=https://s3.amazonaws.com
S3_BUCKET=blogcms-backups
S3_ACCESS_KEY=your-access-key
S3_SECRET_KEY=your-secret-key

# Notifications
NOTIFICATION_EMAIL=admin@yourdomain.com
SLACK_WEBHOOK=https://hooks.slack.com/...
```

## 🔐 Environment Management

### JWT Secret Rotation
```bash
# Rotate JWT secret safely
sudo ./scripts/env-manager.sh rotate-jwt

# Backup current environment
sudo ./scripts/env-manager.sh backup

# Validate configuration
sudo ./scripts/env-manager.sh validate

# Restore from backup
sudo ./scripts/env-manager.sh restore
```

### Environment Security
- Root-only access (600 permissions)
- Encrypted backups with GPG
- Strong secret generation (64+ characters)
- Rotation history logging
- Automatic application restart

## 🗄️ Database Migrations

### Migration Features
- Idempotent execution (safe to run multiple times)
- Connection retry with exponential backoff
- Transaction safety
- Checksum verification
- Execution time monitoring
- Dangerous statement detection

### Migration Commands
```bash
# Run all pending migrations
./scripts/migrate-db.sh

# Force re-run migrations
./scripts/migrate-db.sh --force

# Custom database settings
./scripts/migrate-db.sh \
  --db-host localhost \
  --db-user blogcms \
  --db-password secret \
  --db-name blogcms
```

### Migration File Format
```sql
-- migrations/20231201120000_create_users_table.sql
-- Migration: Create users table
-- Description: Initial user management schema

CREATE TABLE IF NOT EXISTS users (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    role ENUM('admin', 'editor', 'author') DEFAULT 'author',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_email (email),
    INDEX idx_role (role),
    INDEX idx_active (is_active)
) ENGINE=InnoDB CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

## 🚨 Troubleshooting

### Common Issues

#### SSL Certificate Problems
```bash
# Check certificate status
sudo certbot certificates

# Test renewal process
sudo certbot renew --dry-run

# Force certificate renewal
sudo certbot renew --force-renewal

# Check Nginx SSL configuration
sudo nginx -t
openssl s_client -connect yourdomain.com:443 -servername yourdomain.com
```

#### Database Connection Issues
```bash
# Test MySQL connection
mysql -h localhost -u root -p -e "SELECT 1;"

# Check MySQL service
sudo systemctl status mysql

# Check database exists
mysql -u root -p -e "SHOW DATABASES;"

# Check user permissions
mysql -u root -p -e "SELECT User, Host FROM mysql.user;"
```

#### Backup Failures
```bash
# Check backup configuration
mysql-backup-status

# Test S3/MinIO connection
mc alias set test https://endpoint access-key secret-key
mc ls test/bucket

# Check backup logs
sudo tail -f /var/log/mysql-backup.log

# Manual backup test
sudo mysql-backup-daily
```

#### Security Issues
```bash
# Check firewall status
sudo ufw status verbose

# Check fail2ban status
sudo fail2ban-client status

# View banned IPs
sudo fail2ban-client status sshd

# Unban IP address
sudo fail2ban-client set sshd unbanip 1.2.3.4

# Check SSH logs
sudo tail -f /var/log/auth.log
```

### Emergency Recovery

#### Restore from Backup
```bash
# List available backups
ls -la /var/backups/mysql/

# Restore specific backup
sudo mysql-backup-restore \
  --backup-file /var/backups/mysql/blogcms_daily_20231201_020000.sql.gz \
  --database blogcms \
  --force
```

#### Reset Environment
```bash
# Restore environment from backup
sudo ./scripts/env-manager.sh restore

# Regenerate all secrets
sudo ./scripts/env-manager.sh init --force
```

#### SSL Recovery
```bash
# Remove existing certificates
sudo certbot delete --cert-name yourdomain.com

# Reinstall certificates
sudo ./scripts/setup-ssl.sh \
  --api-domain api.yourdomain.com \
  --app-domain yourdomain.com \
  --email admin@yourdomain.com \
  --force
```

## 📈 Performance Optimization

### Backup Optimization
```bash
# Use XZ compression for better compression
# Edit /etc/mysql-backup/backup.conf
COMPRESSION=xz

# Enable encryption for sensitive data
ENCRYPTION=true
ENCRYPTION_PASSWORD=your-secure-password
```

### Database Optimization
```bash
# Optimize backup with single transaction
# Built into mysql-backup.sh:
# --single-transaction
# --routines
# --triggers
# --events
```

### SSL Optimization
```bash
# HTTP/2 enabled by default
# OCSP stapling for faster SSL handshake
# Strong ciphers for security vs performance balance
```

## 🔧 Customization

### Custom SSH Port
```bash
sudo ./scripts/security-hardening.sh --ssh-port 2222
```

### Custom Backup Retention
```bash
# Edit backup configuration
sudo nano /etc/mysql-backup/backup.conf

# Set custom retention
DAILY_RETENTION=14      # 14 days
WEEKLY_RETENTION=60     # 60 days
MONTHLY_RETENTION=730   # 2 years
```

### Custom Fail2ban Settings
```bash
sudo ./scripts/security-hardening.sh \
  --fail2ban-maxretry 3 \
  --fail2ban-bantime 7200 \
  --fail2ban-findtime 300
```

### Custom Migration Directory
```bash
./scripts/migrate-db.sh --migrations-dir /custom/path/migrations
```

## 📞 Support

### Script Help
```bash
# Get help for any script
./scripts/script-name.sh --help

# Examples:
./scripts/deploy-production.sh --help
./scripts/setup-ssl.sh --help
./scripts/mysql-backup.sh --help
```

### Debug Mode
```bash
# Run scripts with debug output
bash -x ./scripts/script-name.sh

# Check script syntax
bash -n ./scripts/script-name.sh
```

### Log Analysis
```bash
# Follow all relevant logs
sudo tail -f /var/log/{mysql-backup,security-monitor,jwt-rotation,db-migrations}.log

# Search for errors
sudo grep -i error /var/log/*.log

# Check system journal
sudo journalctl -f -u nginx -u mysql -u docker
```

---

## 📚 Additional Documentation

- [Phase 14 Production Guide](../docs/phase-14-production-hardening.md)
- [SSL/TLS Configuration](../docs/ssl-configuration.md)
- [Backup Strategy](../docs/backup-strategy.md)
- [Security Hardening](../docs/security-hardening.md)

---

🛡️ **All scripts are production-tested and follow security best practices. Always test in a staging environment before production deployment.**
