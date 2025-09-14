# VPS Setup - Fulcrum Public Gateway

This document covers the **VPS-side configuration** for the Fulcrum public gateway running on **vm-374.lnvps.cloud**.

## 🌐 VPS Configuration

**Host**: `vm-374.lnvps.cloud`  
**Domain**: `fulcrum.bittrade.co.in`  
**User**: `ubuntu`  
**OS**: Ubuntu 24.04  
**Public IP**: `185.18.221.146`

## 🏗️ Architecture

```
Bitcoin Wallets → fulcrum.bittrade.co.in:443 (SSL)
    ↓ (Stunnel4 SSL Termination)
VPS localhost:50005
    ↓ (SSH Reverse Tunnel from Home Server)
Home Server Fulcrum:50005
```

## 🔧 Services Configuration

### Stunnel4 (SSL Termination)
- **Port**: 443
- **Purpose**: SSL termination for Electrum clients
- **Config**: `/etc/stunnel/fulcrum.conf`
- **Forwards to**: localhost:50005
- **Status**: ✅ **ACTIVE** - No rate limiting

### Nginx (Web Server)
- **HTTP Port**: 8080 (redirects to HTTPS)
- **HTTPS Port**: 8443 (health checks, proxy)
- **Config**: `/etc/nginx/sites-enabled/fulcrum.bittrade.co.in`
- **Purpose**: Health endpoints and management
- **Status**: ✅ **ACTIVE** - **Rate limiting REMOVED** (Sept 14, 2025)

### SSH Tunnel Endpoint
- **Port**: localhost:50005
- **Purpose**: Receives forwarded connections from home server
- **Managed by**: Home server SSH reverse tunnel

## 🔒 SSL Certificate

- **Domain**: fulcrum.bittrade.co.in
- **Issuer**: Let's Encrypt
- **Valid From**: August 17, 2025
- **Expires**: November 15, 2025
- **Auto-renewal**: Configured via certbot cron

## 🚀 Quick Status Check

```bash
# Check all services
systemctl status nginx stunnel4

# View listening ports
ss -tulpn | grep -E "(443|8080|8443|50005)"

# Test SSL connection
echo '{"method":"server.version","params":["test","1.4"],"id":1}' | \
  openssl s_client -connect fulcrum.bittrade.co.in:443 -quiet 2>/dev/null

# Check health endpoint
curl -k https://fulcrum.bittrade.co.in:8443/health

# Test from external perspective
curl -I https://fulcrum.bittrade.co.in:8443/health
```

## 📋 Service Management

### Start/Stop Services
```bash
# Restart SSL termination
sudo systemctl restart stunnel4

# Reload nginx configuration
sudo systemctl reload nginx

# Check status
systemctl status nginx stunnel4 --no-pager
```

### Check Logs
```bash
# SSL connection logs
sudo tail -f /var/log/stunnel4/stunnel.log

# Nginx error logs
sudo tail -f /var/log/nginx/fulcrum.bittrade.co.in.error.log

# System service logs
sudo journalctl -u stunnel4 -u nginx -f
```

## ⚙️ Configuration Files

### `/etc/stunnel/fulcrum.conf`
```ini
pid = /var/run/stunnel4/stunnel.pid
output = /var/log/stunnel4/stunnel.log

[fulcrum-ssl]
accept = 443
connect = 127.0.0.1:50005
cert = /etc/letsencrypt/live/fulcrum.bittrade.co.in/fullchain.pem
key = /etc/letsencrypt/live/fulcrum.bittrade.co.in/privkey.pem
```

### `/etc/nginx/sites-enabled/fulcrum.bittrade.co.in`
**Key Configuration Changes (September 14, 2025):**
- ✅ **Rate limiting completely removed** for unlimited wallet connections
- ✅ Clean configuration without electrs zones
- ✅ Optimized for persistent Bitcoin wallet connections

```nginx
# Fulcrum Public Gateway Configuration
server {
    listen 8080;
    server_name fulcrum.bittrade.co.in;
    
    # Redirect HTTP to HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 8443 ssl http2;
    server_name fulcrum.bittrade.co.in;
    
    # SSL configuration (managed by certbot)
    ssl_certificate /etc/letsencrypt/live/fulcrum.bittrade.co.in/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/fulcrum.bittrade.co.in/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;
    
    # Security headers
    add_header Strict-Transport-Security "max-age=63072000" always;
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    
    # Logging
    access_log /var/log/nginx/fulcrum.bittrade.co.in.access.log;
    error_log /var/log/nginx/fulcrum.bittrade.co.in.error.log;
    
    # Allow certbot to access .well-known for SSL certificate renewal
    location /.well-known/acme-challenge/ {
        root /var/www/html;
        allow all;
    }
    
    # Proxy configuration for fulcrum - NO RATE LIMITING
    location / {
        proxy_pass http://127.0.0.1:50005;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # WebSocket support (if needed)
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
        
        # Buffer settings
        proxy_buffering off;
        proxy_request_buffering off;
    }
    
    # Health check endpoint
    location /health {
        access_log off;
        return 200 "Fulcrum Gateway OK\n";
        add_header Content-Type text/plain;
    }
}
```

## 🛡️ Security Configuration

### Firewall (UFW)
```bash
# View current rules
sudo ufw status

# Current allowed ports
sudo ufw allow 22/tcp     # SSH
sudo ufw allow 80/tcp     # HTTP (for certbot)
sudo ufw allow 443/tcp    # HTTPS (stunnel)
sudo ufw allow 8080/tcp   # HTTP redirect
sudo ufw allow 8443/tcp   # HTTPS proxy
```

### Rate Limiting Status
- **Status**: ✅ **COMPLETELY DISABLED** (September 14, 2025)
- **Reason**: Bitcoin wallets require persistent connections without limits
- **Previous Issue**: 10 requests/second limit was causing connection drops
- **Solution**: All rate limiting zones and rules removed from nginx

## 🔍 Troubleshooting

### Connection Issues

**1. Check SSH Tunnel Status**
```bash
# Should show SSH process listening on 50005
ss -tulpn | grep 50005
ps aux | grep ssh
```

**2. Test Local Connection**
```bash
# Test tunnel endpoint
telnet 127.0.0.1 50005
echo '{"method":"server.version","params":["test","1.4"],"id":1}' | nc 127.0.0.1 50005
```

**3. Check SSL Certificate**
```bash
sudo certbot certificates
openssl s_client -connect fulcrum.bittrade.co.in:443 -servername fulcrum.bittrade.co.in
```

### Common Problems

**"Connection refused on port 443"**
- Stunnel4 not running: `sudo systemctl restart stunnel4`
- Certificate issues: `sudo certbot renew`

**"No response from server"**
- SSH tunnel down: Check home server connection
- Home server Fulcrum not responding

**"SSL handshake failed"**
- Certificate expired: `sudo certbot renew && sudo systemctl reload stunnel4`
- Wrong certificate path in stunnel config

**"Wallet connection drops after initial connection"** ✅ **FIXED**
- ~~Previous cause: nginx rate limiting~~ → **RESOLVED**
- Solution: All rate limiting removed (Sept 14, 2025)

### Log Analysis
```bash
# Recent stunnel connections
sudo tail -20 /var/log/stunnel4/stunnel.log

# Look for SSL errors
sudo journalctl -u stunnel4 --since "1 hour ago" | grep -E "(ERROR|WARN)"

# Check nginx errors (should be minimal now)
sudo tail -20 /var/log/nginx/fulcrum.bittrade.co.in.error.log
```

## 🔄 Maintenance

### SSL Certificate Renewal
```bash
# Manual renewal (auto-renews via cron)
sudo certbot renew
sudo systemctl reload stunnel4 nginx
```

### System Updates
```bash
# Update packages
sudo apt update && sudo apt upgrade

# Restart services after updates
sudo systemctl restart stunnel4 nginx
```

### Configuration Backup
```bash
# Backup important configs
sudo cp /etc/stunnel/fulcrum.conf ~/stunnel.conf.backup
sudo cp /etc/nginx/sites-available/fulcrum.bittrade.co.in ~/nginx.conf.backup
```

## 📊 Monitoring Commands

```bash
# Service status overview
./vps-status-check.sh

# Real-time connection monitoring
sudo tail -f /var/log/stunnel4/stunnel.log

# Port usage
ss -tulpn | grep -E "(443|8080|8443|50005)"

# Certificate expiry
sudo certbot certificates | grep -A3 fulcrum

# Test full chain
echo '{"method":"server.features","params":[],"id":1}' | \
  openssl s_client -connect fulcrum.bittrade.co.in:443 -quiet 2>/dev/null

# Test multiple connections (should all work now)
for i in {1..5}; do
  echo "Connection $i:"
  echo '{"method":"server.version","params":["test","1.4"],"id":1}' | \
    timeout 3 openssl s_client -connect fulcrum.bittrade.co.in:443 -quiet 2>/dev/null
done
```

## 🚨 Emergency Procedures

### Service Recovery
```bash
# If stunnel fails
sudo systemctl stop stunnel4
sudo systemctl start stunnel4
sudo systemctl status stunnel4

# If nginx fails
sudo nginx -t  # Test config
sudo systemctl restart nginx

# If tunnel connection lost
# Check home server SSH tunnel status
# Restart tunnel from home server

# If wallets can't connect (post-Sept 14 fix)
# Check service status - rate limiting no longer an issue
sudo systemctl status stunnel4 nginx
```

### DNS Issues
```bash
# Check DNS resolution
dig fulcrum.bittrade.co.in
nslookup fulcrum.bittrade.co.in

# Current IP should be: 185.18.221.146

# Test from external perspective
curl -I https://fulcrum.bittrade.co.in:8443/health
```

## 🔄 Automated Daily Maintenance

### Daily Service Restarts
**Status**: ✅ **ACTIVE** - Configured on September 13, 2025

The VPS is configured with automated daily service restarts to prevent connection issues and maintain optimal performance.

#### Configuration
```bash
# Cron job (runs as root)
0 3 * * * systemctl restart stunnel4 nginx && echo "$(date): Fulcrum services restarted" >> /var/log/fulcrum-maintenance.log
```

#### Schedule Details
- **Time**: 3:00 AM UTC daily
- **Services**: stunnel4 + nginx
- **Duration**: ~2-3 seconds downtime
- **Log File**: `/var/log/fulcrum-maintenance.log`
- **Impact**: Minimal - wallets auto-reconnect

#### Monitoring Commands
```bash
# Check if restarts are happening
cat /var/log/fulcrum-maintenance.log

# View current cron schedule
sudo crontab -l

# Check last restart time
systemctl show stunnel4 --property=ActiveEnterTimestamp

# Check service uptime
systemctl status stunnel4 nginx --no-pager
```

#### Management Commands
```bash
# Edit restart schedule
sudo crontab -e

# Disable automated restarts
sudo crontab -r

# Manual restart (for testing)
sudo systemctl restart stunnel4 nginx

# Test cron job without waiting
sudo systemctl restart stunnel4 nginx && echo "$(date): Manual test restart" >> /var/log/fulcrum-maintenance.log
```

#### Benefits
- **Prevents SSL state corruption** that can build up over time
- **Clears accumulated network socket issues**
- **Refreshes SSL/TLS certificate loading**
- **Maintains wallet connection reliability**
- **Proactive maintenance** - fixes issues before they occur

#### Troubleshooting
```bash
# If automated restarts aren't working:
systemctl status cron                    # Check cron service
sudo tail -f /var/log/syslog | grep cron # Watch cron execution
sudo tail -20 /var/log/fulcrum-maintenance.log # Check restart history

# If you need to change the time (example: 2:30 AM):
sudo crontab -e
# Change: 0 3 * * * to: 30 2 * * *
```

---

## 📝 **Change Log**

### September 14, 2025 - **MAJOR PERFORMANCE FIX** 🚀
- ✅ **FIXED: Rate limiting issue causing wallet connection drops**
- ✅ **REMOVED: All nginx rate limiting** (`limit_req zone=electrs`)  
- ✅ **REMOVED: electrs rate limiting zone** (10r/s limit)
- ✅ **OPTIMIZED: Configuration for unlimited Bitcoin wallet connections**
- ✅ **VERIFIED: External connectivity working perfectly**
- ✅ **STATUS: Multiple persistent wallet connections now supported**

### September 13, 2025 - Initial Setup
- ✅ **Automated daily maintenance** configured
- ✅ **SSL certificates** configured and working
- ✅ **SSH tunnel** established to home server
- ✅ **Basic rate limiting** implemented (later removed)

---

**VPS Role**: SSL termination, tunnel endpoint, health monitoring  
**Dependencies**: Home server SSH tunnel, Fulcrum server  
**Wallet Connection**: `fulcrum.bittrade.co.in:443:s`  
**Status**: ✅ **FULLY OPERATIONAL** - No connection limitations
