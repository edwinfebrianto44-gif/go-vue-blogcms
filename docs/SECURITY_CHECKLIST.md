# Production Security Checklist

## 🔒 Phase 14: Hardening & Production Security

### ✅ SSL/TLS Configuration
- [ ] Let's Encrypt certificates for api.domain.com
- [ ] Let's Encrypt certificates for app.domain.com  
- [ ] Auto-renewal cron job configured
- [ ] SSL Labs A+ rating achieved
- [ ] HSTS headers enabled (31536000 seconds)
- [ ] OCSP stapling enabled
- [ ] Modern cipher suite configured
- [ ] TLS 1.2 and 1.3 only

### ✅ Firewall & Network Security
- [ ] UFW firewall enabled and configured
- [ ] Only ports 22, 80, 443 allowed
- [ ] SSH rate limiting enabled
- [ ] Fail2ban installed and configured
- [ ] Custom Fail2ban rules for nginx
- [ ] DDoS protection via rate limiting
- [ ] Network intrusion detection

### ✅ Authentication & Authorization
- [ ] Strong JWT secret (64+ characters)
- [ ] JWT rotation procedures documented
- [ ] JWT expiry set to 24 hours
- [ ] Refresh token expiry set to 7 days
- [ ] Admin bootstrap script created
- [ ] Role-based access control verified
- [ ] Password complexity requirements

### ✅ Environment & Configuration Security
- [ ] .env.production not in git repository
- [ ] .env.example template created
- [ ] Secure database passwords generated
- [ ] Redis authentication enabled
- [ ] CORS properly configured
- [ ] Debug mode disabled in production
- [ ] Error messages sanitized

### ✅ Database Security
- [ ] MySQL root password secured
- [ ] Application database user with limited privileges
- [ ] Database connection encryption
- [ ] SQL injection protection verified
- [ ] Database backup encryption
- [ ] Connection pooling configured
- [ ] Query logging disabled in production

### ✅ Backup & Recovery
- [ ] Daily automated backups configured
- [ ] S3/MinIO backup storage setup
- [ ] 30-day retention policy implemented
- [ ] Backup verification process
- [ ] Point-in-time recovery tested
- [ ] Backup restoration documented
- [ ] Offsite backup storage

### ✅ Monitoring & Logging
- [ ] Structured logging implemented (JSON)
- [ ] Log rotation configured
- [ ] Health check endpoints (/healthz, /readyz, /health)
- [ ] Prometheus metrics enabled
- [ ] Correlation ID tracking
- [ ] Error rate monitoring
- [ ] Performance monitoring
- [ ] Security event logging

### ✅ System Hardening
- [ ] Automatic security updates enabled
- [ ] Non-root container execution
- [ ] File system permissions secured
- [ ] System packages updated
- [ ] Unnecessary services disabled
- [ ] SSH key-based authentication
- [ ] Sudo access restricted

### ✅ Application Security
- [ ] Security headers implemented
- [ ] Input validation and sanitization
- [ ] File upload restrictions
- [ ] Cross-site scripting (XSS) protection
- [ ] Cross-site request forgery (CSRF) protection
- [ ] Content Security Policy (CSP)
- [ ] Secure session management

### ✅ Container Security
- [ ] Docker containers run as non-root
- [ ] Base images regularly updated
- [ ] Secrets managed via environment variables
- [ ] Container resource limits set
- [ ] Health checks configured
- [ ] Container image scanning
- [ ] Network isolation between services

### ✅ Compliance & Documentation
- [ ] Security documentation complete
- [ ] Incident response procedures
- [ ] Backup and recovery procedures
- [ ] Security contact information
- [ ] Vulnerability disclosure policy
- [ ] Privacy policy compliance
- [ ] Data retention policies

## 🔧 Verification Commands

### SSL/TLS Verification
```bash
# Test SSL configuration
curl -I https://api.yourdomain.com
curl -I https://app.yourdomain.com

# Check SSL Labs rating
# Visit: https://www.ssllabs.com/ssltest/

# Verify certificate expiration
openssl x509 -in /etc/letsencrypt/live/api.yourdomain.com/cert.pem -noout -dates
```

### Security Verification
```bash
# Check firewall status
sudo ufw status verbose

# Verify fail2ban
sudo fail2ban-client status

# Test rate limiting
for i in {1..15}; do curl -I https://api.yourdomain.com/health; done

# Check security headers
curl -I https://api.yourdomain.com | grep -E "(Strict-Transport|X-Frame|X-Content|X-XSS)"
```

### Backup Verification
```bash
# Check backup files
ls -la /opt/blogcms/backups/

# Verify S3 backups
aws s3 ls s3://your-bucket/backups/

# Test backup restoration (in staging)
# gunzip -c backup.sql.gz | mysql -u user -p database
```

### Health Verification
```bash
# Application health
curl https://api.yourdomain.com/healthz
curl https://api.yourdomain.com/readyz
curl https://api.yourdomain.com/health

# Container health
docker-compose -f /opt/blogcms/docker-compose.production.yml ps
```

## 🚨 Security Incident Response

### Immediate Actions
1. **Identify the threat**
   - Check application logs
   - Review fail2ban logs
   - Monitor unusual traffic patterns

2. **Contain the incident**
   - Block malicious IPs via fail2ban
   - Scale down affected services if needed
   - Preserve evidence for analysis

3. **Assess the damage**
   - Check for unauthorized access
   - Verify data integrity
   - Review audit logs

4. **Recovery procedures**
   - Restore from clean backups if needed
   - Rotate all secrets and passwords
   - Update and patch systems

5. **Post-incident review**
   - Document the incident
   - Update security procedures
   - Implement additional safeguards

### Emergency Contacts
```bash
# System administrator
ADMIN_EMAIL="admin@yourdomain.com"

# Security team
SECURITY_EMAIL="security@yourdomain.com"

# Emergency procedure
echo "Security incident detected at $(date)" | mail -s "URGENT: Security Alert" $SECURITY_EMAIL
```

## 📅 Maintenance Schedule

### Daily (Automated)
- [ ] Security updates via unattended-upgrades
- [ ] Database backups at 2:00 AM
- [ ] Health monitoring every 5 minutes
- [ ] Log rotation

### Weekly
- [ ] Review fail2ban logs
- [ ] Check SSL certificate expiration
- [ ] Verify backup integrity
- [ ] Monitor system performance

### Monthly  
- [ ] Rotate JWT secrets
- [ ] Security patch review
- [ ] Vulnerability scanning
- [ ] Incident response drill

### Quarterly
- [ ] Security audit
- [ ] Penetration testing
- [ ] Compliance review
- [ ] Disaster recovery testing

## 🏆 Production Readiness Criteria

### Performance
- [ ] API response time < 200ms (95th percentile)
- [ ] Database query time < 50ms average
- [ ] SSL handshake time < 100ms
- [ ] Page load time < 2 seconds

### Reliability
- [ ] 99.9% uptime SLA
- [ ] Zero data loss guarantee
- [ ] < 1 minute recovery time
- [ ] Automated failover tested

### Security
- [ ] SSL Labs A+ rating
- [ ] Zero critical vulnerabilities
- [ ] All security headers present
- [ ] Intrusion detection active

### Compliance
- [ ] Backup retention policies
- [ ] Data protection measures
- [ ] Audit trail complete
- [ ] Incident response ready

## ✅ Sign-off

**Security Review Completed By**: ________________  
**Date**: ________________  
**Security Level**: Production Ready  
**Next Review Date**: ________________  

**Approved for Production Deployment**: ✅

---

**Note**: This checklist should be completed before deploying to production and reviewed regularly to maintain security posture.
