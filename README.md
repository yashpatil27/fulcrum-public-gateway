# Fulcrum Public Gateway - VPS Setup

This VPS acts as a public gateway for your home Fulcrum Bitcoin server, bypassing CGNAT limitations using SSH reverse tunnels and SSL termination.

## 🔧 Current Configuration

**Domain**: `fulcrum.bittrade.co.in`  
**Wallet Connection**: `fulcrum.bittrade.co.in:443:s`

### Architecture
```
Bitcoin Wallets → fulcrum.bittrade.co.in:443 (SSL)
    ↓ (Stunnel4 SSL Termination)
VPS localhost:50005
    ↓ (SSH Reverse Tunnel)
Home Server Fulcrum:50005
```

### Services Running
- **Stunnel4**: Port 443 (SSL termination for Electrum clients)
- **Nginx**: Ports 8080 (HTTP redirect), 8443 (HTTPS proxy/health checks)
- **SSH Tunnel**: localhost:50005 (forwarded from home server)

### SSL Certificate
- **Domain**: fulcrum.bittrade.co.in
- **Expires**: November 15, 2025
- **Auto-renewal**: Configured via cron

## 🚀 Quick Status Check

```bash
# Check all services
systemctl status nginx stunnel4

# Test Electrum connection
echo '{"method":"server.version","params":["test","1.4"],"id":1}' | \
  openssl s_client -connect fulcrum.bittrade.co.in:443 -quiet 2>/dev/null

# Check health endpoint
curl -k https://fulcrum.bittrade.co.in:8443/health

# View service ports
ss -tulpn | grep -E "(443|8080|8443|50005)"
```

## 📱 Wallet Connection

**Connection String**: `fulcrum.bittrade.co.in:443:s`

The `:s` suffix is crucial - it tells the wallet to use SSL/TLS encryption.

### Supported Wallets
- Electrum Desktop/Mobile
- Blue Wallet
- Sparrow Wallet
- Any wallet supporting custom Electrum servers

## 🔍 Troubleshooting

### Connection Issues

1. **Check SSH tunnel from home server**:
   ```bash
   ps aux | grep ssh | grep 50005
   ss -tulpn | grep 50005
   ```

2. **Check SSL certificate**:
   ```bash
   sudo certbot certificates
   openssl s_client -connect fulcrum.bittrade.co.in:443 -servername fulcrum.bittrade.co.in
   ```

3. **Check stunnel logs**:
   ```bash
   sudo tail -f /var/log/stunnel4/stunnel.log
   ```

4. **Check nginx logs**:
   ```bash
   sudo tail -f /var/log/nginx/fulcrum.bittrade.co.in.error.log
   ```

### Service Management

```bash
# Restart services
sudo systemctl restart stunnel4
sudo systemctl reload nginx

# Check service status
systemctl status nginx stunnel4

# Check firewall
sudo ufw status
```

### Common Issues

**"Connection refused"**
- SSH tunnel from home server is down
- Check home server connection and tunnel service

**"SSL handshake failed"**
- Certificate expired or invalid
- Run: `sudo certbot renew`

**"No route to host"**
- DNS not resolving
- Check domain DNS settings

**"Timeout"**
- Firewall blocking connection
- Home server Fulcrum not responding

## ⚙️ Configuration Files

### Stunnel Configuration
**File**: `/etc/stunnel/fulcrum.conf`
```ini
pid = /var/run/stunnel4/stunnel.pid
output = /var/log/stunnel4/stunnel.log

[fulcrum-ssl]
accept = 443
connect = 127.0.0.1:50005
cert = /etc/letsencrypt/live/fulcrum.bittrade.co.in/fullchain.pem
key = /etc/letsencrypt/live/fulcrum.bittrade.co.in/privkey.pem
```

### Nginx Configuration
**File**: `/etc/nginx/sites-enabled/fulcrum.bittrade.co.in`

Key points:
- HTTP (8080) redirects to HTTPS
- HTTPS (8443) proxies to localhost:50005
- Health check endpoint at `/health`
- Rate limiting configured
- SSL certificates managed by certbot

### Project Configuration
**File**: `config.env`
```bash
DOMAIN="fulcrum.bittrade.co.in"
SSL_EMAIL="admin@bittrade.co.in"
FULCRUM_PORT="50005"
```

## 🔐 Security Features

- **SSL/TLS Encryption**: All external connections encrypted
- **Rate Limiting**: 10 requests per second via nginx
- **Firewall**: UFW configured with minimal ports
- **SSH Keys**: Passwordless authentication for tunnel
- **Security Headers**: HSTS, XSS protection, etc.

## 📊 Monitoring

### Health Checks
```bash
# Electrum protocol test
echo '{"method":"server.features","params":[],"id":1}' | \
  openssl s_client -connect fulcrum.bittrade.co.in:443 -quiet 2>/dev/null

# HTTP health endpoint
curl -k https://fulcrum.bittrade.co.in:8443/health

# SSL certificate check
openssl s_client -connect fulcrum.bittrade.co.in:443 -servername fulcrum.bittrade.co.in 2>&1 | grep -E "(verify|subject|issuer)"
```

### Log Monitoring
```bash
# Real-time connection monitoring
sudo tail -f /var/log/stunnel4/stunnel.log

# Nginx access logs
sudo tail -f /var/log/nginx/fulcrum.bittrade.co.in.access.log

# System service logs
sudo journalctl -u stunnel4 -u nginx -f
```

## 🔄 Maintenance

### SSL Certificate Renewal
Certificates auto-renew via cron. Manual renewal:
```bash
sudo certbot renew
sudo systemctl reload nginx stunnel4
```

### Service Updates
```bash
# Update system
sudo apt update && sudo apt upgrade

# Restart services after updates
sudo systemctl restart nginx stunnel4
```

### Backup Important Files
```bash
# Configuration backup
sudo cp /etc/stunnel/fulcrum.conf ~/fulcrum.conf.backup
sudo cp /etc/nginx/sites-available/fulcrum.bittrade.co.in ~/nginx.conf.backup
cp config.env config.env.backup
```

## 🏠 Home Server Requirements

Your home server must:
1. Run Fulcrum on port 50005
2. Maintain SSH reverse tunnel to this VPS
3. Have stable internet connection

### Home Server Tunnel Command Example
```bash
ssh -R 50005:127.0.0.1:50005 -N -f ubuntu@fulcrum.bittrade.co.in
```

## 📞 Support

### Quick Diagnostics
```bash
# Run comprehensive status check
./vps-status-check.sh

# Check specific service
systemctl status nginx stunnel4

# Test connection
echo '{"method":"server.version","params":["test","1.4"],"id":1}' | \
  openssl s_client -connect fulcrum.bittrade.co.in:443 -quiet 2>/dev/null
```

### Key Files to Check
- `/var/log/stunnel4/stunnel.log` - SSL connection logs
- `/var/log/nginx/fulcrum.bittrade.co.in.error.log` - Nginx errors
- `/etc/stunnel/fulcrum.conf` - SSL termination config
- `config.env` - Project configuration

---
**Status**: ✅ Operational  
**Last Updated**: September 2025  
**Domain**: fulcrum.bittrade.co.in:443:s
