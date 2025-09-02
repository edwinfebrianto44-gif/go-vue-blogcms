# GitHub Secrets Configuration Guide

This document outlines all the required GitHub secrets for the CI/CD pipeline to work properly.

## Required Secrets

Go to your GitHub repository → Settings → Secrets and variables → Actions → New repository secret

### Database Configuration
```
DB_HOST=your-database-host
DB_USER=blogcms_user
DB_PASSWORD=your-secure-password
DB_NAME=blogcms_db
```

### Application Secrets
```
JWT_SECRET=your-very-secure-jwt-secret-key-at-least-32-characters
```

### VPS Deployment
```
VPS_HOST=your-vps-ip-or-domain
VPS_USER=your-vps-username
VPS_SSH_KEY=your-private-ssh-key-content
```

### GitHub Container Registry
```
# These are automatically available in GitHub Actions
GITHUB_TOKEN=${{ secrets.GITHUB_TOKEN }}
GITHUB_USERNAME=${{ github.actor }}
```

### CDN/S3 Deployment (Optional)
```
AWS_ACCESS_KEY_ID=your-aws-access-key
AWS_SECRET_ACCESS_KEY=your-aws-secret-key
AWS_REGION=us-east-1
S3_BUCKET=your-s3-bucket-name
CLOUDFRONT_DISTRIBUTION_ID=your-cloudfront-distribution-id
```

## Secret Setup Instructions

### 1. Database Secrets
Set up your production database credentials. For MySQL:
- Use a secure password for `DB_PASSWORD`
- Ensure the database user has appropriate permissions

### 2. JWT Secret
Generate a secure JWT secret:
```bash
openssl rand -base64 32
```

### 3. VPS SSH Key
Generate an SSH key pair for deployment:
```bash
ssh-keygen -t rsa -b 4096 -C "github-actions@yourrepo"
```
- Add the public key to your VPS `~/.ssh/authorized_keys`
- Add the private key content to `VPS_SSH_KEY` secret

### 4. VPS User Setup
On your VPS, create a deployment user:
```bash
sudo useradd -m -s /bin/bash deploy
sudo usermod -aG docker deploy
sudo mkdir -p /home/deploy/.ssh
sudo chown deploy:deploy /home/deploy/.ssh
sudo chmod 700 /home/deploy/.ssh
```

Add the public key:
```bash
sudo nano /home/deploy/.ssh/authorized_keys
sudo chown deploy:deploy /home/deploy/.ssh/authorized_keys
sudo chmod 600 /home/deploy/.ssh/authorized_keys
```

### 5. AWS/CDN Setup (if using)
For S3 + CloudFront deployment:
1. Create an S3 bucket for static files
2. Set up CloudFront distribution
3. Create IAM user with S3 and CloudFront permissions
4. Add credentials to GitHub secrets

## Environment Variables Template

Create a `.env.production` file template:
```env
# Database
DB_HOST=${DB_HOST}
DB_USER=${DB_USER}
DB_PASSWORD=${DB_PASSWORD}
DB_NAME=${DB_NAME}

# Application
JWT_SECRET=${JWT_SECRET}
GIN_MODE=release
PORT=8080

# CORS
CORS_ORIGINS=http://localhost:3000,https://yourdomain.com

# File uploads
UPLOAD_MAX_SIZE=10485760
UPLOAD_PATH=/app/uploads

# Redis (if using)
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_PASSWORD=

# Logging
LOG_LEVEL=info
LOG_FORMAT=json
```

## Security Best Practices

1. **Use Strong Passwords**: Generate secure passwords for all services
2. **Rotate Secrets**: Regularly rotate JWT secrets and database passwords
3. **Limit SSH Access**: Use dedicated SSH keys for deployment only
4. **VPS Security**: Keep your VPS updated and configure firewall rules
5. **Monitor Access**: Enable logging and monitoring for all services

## Verification Steps

1. **Test SSH Access**:
   ```bash
   ssh -i private_key deploy@your-vps-host
   ```

2. **Test Database Connection**:
   ```bash
   mysql -h $DB_HOST -u $DB_USER -p$DB_PASSWORD $DB_NAME
   ```

3. **Test Docker Access**:
   ```bash
   docker ps
   ```

4. **Verify GitHub Container Registry Access**:
   The pipeline will test this automatically on first run.

## Troubleshooting

### Common Issues

1. **SSH Connection Failed**:
   - Check SSH key format (should start with `-----BEGIN...`)
   - Verify public key is in VPS authorized_keys
   - Check VPS firewall allows SSH (port 22)

2. **Database Connection Failed**:
   - Verify database is running and accessible
   - Check username/password combination
   - Ensure database exists

3. **Docker Permission Denied**:
   - Add deployment user to docker group
   - Restart SSH session after group changes

4. **GitHub Actions Failing**:
   - Check all required secrets are set
   - Verify secret names match exactly
   - Check workflow syntax

### Support

If you encounter issues:
1. Check GitHub Actions logs for detailed error messages
2. SSH into VPS and check deployment logs
3. Verify all secrets are properly configured
4. Test each component individually

## Production Checklist

Before going live:
- [ ] All secrets configured
- [ ] SSH access working
- [ ] Database accessible
- [ ] VPS has sufficient resources
- [ ] Backup strategy in place
- [ ] Monitoring configured
- [ ] SSL certificates set up
- [ ] Domain DNS configured
- [ ] Firewall rules configured
- [ ] Log rotation configured
