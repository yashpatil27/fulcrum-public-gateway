# VPS Setup - Fulcrum Public Gateway

This document covers the **VPS-side configuration** for the Fulcrum public gateway running on **vm-374.lnvps.cloud**.

## 🌐 VPS Configuration

**Host**: `vm-374.lnvps.cloud`  
**Domain**: `fulcrum.bittrade.co.in`  
**User**: `ubuntu`  
**OS**: Ubuntu 24.04

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

### Nginx (Web Server)
- **HTTP Port**: 8080 (redirects to HTTPS)
- **HTTPS Port**: 8443 (health checks, proxy)
- **Config**: `/etc/nginx/sites-enabled/fulcrum.bittrade.co.in`
- **Purpose**: Health endpoints and management

### SSH Tunnel Endpoint
- **Port**: localhost:50005
- **Purpose**: Receives forwarded connections from home server
- **Managed by**: Home server SSH reverse tunnel

## 🔒 SSL Certificate

- **Domain**: fulcrum.bittrade.co.in
- **Issuer**: Let's Encrypt
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
Key features:
- HTTP (8080) → HTTPS redirect
- HTTPS (8443) with SSL certificates
- Health endpoint at `/health`
- Rate limiting (electrs zone)
- Proxy to localhost:50005

## 🛡️ Security Configuration

### Firewall (UFW)
```bash
# View current rules
sudo ufw status

# Allow necessary ports
sudo ufw allow 22/tcp     # SSH
sudo ufw allow 80/tcp     # HTTP (for certbot)
sudo ufw allow 443/tcp    # HTTPS (stunnel)
sudo ufw allow 8080/tcp   # HTTP redirect
sudo ufw allow 8443/tcp   # HTTPS proxy
```

### Rate Limiting
- **Zone**: electrs (defined in nginx.conf)
- **Rate**: 10 requests per second
- **Burst**: 20 requests

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
- Stunnel4 not running: `sudo systemctl start stunnel4`
- Certificate issues: `sudo certbot renew`

**"No response from server"**
- SSH tunnel down: Check home server connection
- Home server Fulcrum not responding

**"SSL handshake failed"**
- Certificate expired: `sudo certbot renew && sudo systemctl reload stunnel4`
- Wrong certificate path in stunnel config

### Log Analysis
```bash
# Recent stunnel connections
sudo tail -20 /var/log/stunnel4/stunnel.log

# Look for SSL errors
sudo journalctl -u stunnel4 --since "1 hour ago" | grep -E "(ERROR|WARN)"

# Check nginx errors
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
```

### DNS Issues
```bash
# Check DNS resolution
dig fulcrum.bittrade.co.in
nslookup fulcrum.bittrade.co.in

# Test from external perspective
curl -I https://fulcrum.bittrade.co.in
```

---
**VPS Role**: SSL termination, tunnel endpoint, health monitoring  
**Dependencies**: Home server SSH tunnel, Fulcrum server  
**Wallet Connection**: `fulcrum.bittrade.co.in:443:s`

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

#### Why This Was Added
On September 13, 2025, the VPS experienced connection issues where:
- All services appeared healthy but wallets couldn't connect
- SSL handshake errors accumulated in stunnel logs
- A manual VPS restart completely resolved the issue
- Daily restarts prevent this type of service state corruption

