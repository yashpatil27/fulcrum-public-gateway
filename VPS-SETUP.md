# VPS Setup Documentation - Electrs Public Gateway

This document explains the complete VPS setup process that was performed to make the electrs public gateway operational.

## Overview

The electrs public gateway allows your home Bitcoin electrs server to be publicly accessible through a VPS, bypassing CGNAT limitations. The architecture uses SSH reverse tunneling with SSL termination on the VPS.

## Architecture

```
Internet Client (Electrum)
    ↓ SSL Connection (port 50002)
electrs.bittrade.co.in (VPS)
    ↓ stunnel (SSL termination)
localhost:50005 (VPS)
    ↓ SSH Reverse Tunnel
Home Server electrs:50005
```

## Components Installed and Configured

### 1. Nginx (Web Server & HTTP Proxy)
**Purpose**: Provides health check endpoint and HTTP access
**Configuration**: `/etc/nginx/sites-enabled/electrs.bittrade.co.in`

```nginx
# Electrs Public Gateway Configuration - Cloudflare Compatible
server {
    listen 80;
    server_name electrs.bittrade.co.in;
    
    # Real IP from Cloudflare (if using Cloudflare)
    real_ip_header CF-Connecting-IP;
    # ... Cloudflare IP ranges ...
    
    # Rate limiting (zone defined in nginx.conf)
    limit_req zone=electrs burst=20 nodelay;
    
    # Health check endpoint
    location /health {
        access_log off;
        return 200 "Electrs Gateway OK\n";
        add_header Content-Type text/plain;
    }
    
    # Main electrs proxy (not used in final setup)
    location / {
        proxy_pass http://127.0.0.1:50005;
        # ... proxy configuration ...
    }
}
```

**Key Changes Made**:
- Added rate limiting zone to `/etc/nginx/nginx.conf`:
  ```nginx
  # Rate limiting zone for electrs
  limit_req_zone $binary_remote_addr zone=electrs:10m rate=10r/s;
  ```
- Removed default site to avoid conflicts
- Configured for direct IP access (not Cloudflare proxy)

### 2. SSL Certificates (Let's Encrypt)
**Purpose**: Provides SSL certificates for HTTPS and electrs SSL connections
**Installation**:
```bash
sudo certbot --nginx -d electrs.bittrade.co.in --non-interactive --agree-tos --email admin@bittrade.co.in
```

**Certificates Located At**:
- Certificate: `/etc/letsencrypt/live/electrs.bittrade.co.in/fullchain.pem`
- Private Key: `/etc/letsencrypt/live/electrs.bittrade.co.in/privkey.pem`
- Auto-renewal: Enabled via systemd timer

### 3. Stunnel (SSL Termination for TCP)
**Purpose**: Provides SSL termination for raw TCP electrs connections
**Configuration**: `/etc/stunnel/electrs.conf`

```ini
pid = /var/run/stunnel4/stunnel.pid
output = /var/log/stunnel4/stunnel.log

[electrs-ssl]
accept = 50002
connect = 127.0.0.1:50005
cert = /etc/letsencrypt/live/electrs.bittrade.co.in/fullchain.pem
key = /etc/letsencrypt/live/electrs.bittrade.co.in/privkey.pem
```

**Service Management**:
```bash
sudo systemctl enable stunnel4
sudo systemctl start stunnel4
sudo systemctl status stunnel4
```

### 4. Firewall Configuration (UFW)
**Ports Opened**:
```bash
sudo ufw allow ssh      # Port 22 (SSH)
sudo ufw allow 80/tcp   # Port 80 (HTTP)
sudo ufw allow 443/tcp  # Port 443 (HTTPS)
sudo ufw allow 50002/tcp # Port 50002 (Electrs SSL)
sudo ufw --force enable
```

## Service Architecture

### Port Mapping
| Port | Service | Purpose | Access |
|------|---------|---------|--------|
| 22 | SSH | Server management | External |
| 80 | Nginx | HTTP health check | External |
| 443 | Nginx | HTTPS health check | External |
| 50002 | stunnel | Electrs SSL connections | External |
| 50005 | SSH Tunnel | Forwarded electrs port | Internal only |

### Process Flow

1. **Electrum Client Connection**:
   ```
   electrum --server electrs.bittrade.co.in:50002:s
   ```

2. **SSL Handshake**:
   - Client connects to VPS port 50002
   - stunnel handles SSL termination using Let's Encrypt certificates

3. **TCP Forwarding**:
   - stunnel forwards decrypted traffic to localhost:50005
   - Port 50005 is the SSH reverse tunnel endpoint

4. **SSH Tunnel**:
   - Home server maintains SSH reverse tunnel to VPS
   - Traffic on VPS:50005 is forwarded to home server electrs:50005

5. **Electrs Response**:
   - Home electrs processes the request
   - Response travels back through the same path with SSL encryption

## Setup Steps Performed

### 1. Initial System Setup
```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install required packages
sudo apt install -y nginx certbot python3-certbot-nginx ufw stunnel4 curl dig
```

### 2. DNS Configuration
- Changed `electrs.bittrade.co.in` DNS record from "Proxied" (Cloudflare) to "DNS only"
- This allows direct connections to VPS IP: 185.18.221.146

### 3. Nginx Configuration
```bash
# Fixed rate limiting configuration
sudo sed -i '/http {/a\\n\t# Rate limiting zone for electrs\n\tlimit_req_zone $binary_remote_addr zone=electrs:10m rate=10r/s;\n' /etc/nginx/nginx.conf

# Removed conflicting default site
sudo rm /etc/nginx/sites-enabled/default

# Created electrs site configuration
sudo tee /etc/nginx/sites-enabled/electrs.bittrade.co.in < electrs-nginx-config
```

### 4. SSL Certificate Installation
```bash
# Obtain SSL certificate
sudo certbot --nginx -d electrs.bittrade.co.in --non-interactive --agree-tos --email admin@bittrade.co.in

# Verify certificate
sudo ls -la /etc/letsencrypt/live/electrs.bittrade.co.in/
```

### 5. Stunnel Configuration
```bash
# Create stunnel configuration
sudo tee /etc/stunnel/electrs.conf < stunnel-config

# Create required directories
sudo mkdir -p /var/run/stunnel4 /var/log/stunnel4
sudo chown stunnel4:stunnel4 /var/run/stunnel4 /var/log/stunnel4

# Enable and start stunnel
sudo sed -i 's/ENABLED=0/ENABLED=1/' /etc/default/stunnel4
sudo systemctl start stunnel4
```

### 6. Firewall Configuration
```bash
# Configure UFW
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 50002/tcp
sudo ufw --force enable
```

## Troubleshooting & Verification

### Health Checks
```bash
# Check nginx status
sudo systemctl status nginx

# Check stunnel status
sudo systemctl status stunnel4

# Check port listeners
sudo ss -tlnp | grep -E ':(80|443|50002|50005)'

# Test SSL connection to electrs
echo '{"jsonrpc": "2.0", "method": "server.version", "params": ["Test", "1.4"], "id": 0}' | openssl s_client -connect electrs.bittrade.co.in:50002 -quiet 2>/dev/null
```

### Log Locations
- **Nginx Access**: `/var/log/nginx/electrs.bittrade.co.in.access.log`
- **Nginx Error**: `/var/log/nginx/electrs.bittrade.co.in.error.log`
- **Stunnel**: `/var/log/stunnel4/stunnel.log`
- **Let's Encrypt**: `/var/log/letsencrypt/letsencrypt.log`

### Common Issues and Solutions

#### 1. Rate Limiting Error in Nginx
**Problem**: `limit_req_zone` directive not allowed in server block
**Solution**: Move `limit_req_zone` to http block in `/etc/nginx/nginx.conf`

#### 2. SSL Certificate Issues with Cloudflare
**Problem**: Cloudflare proxy prevents Let's Encrypt domain validation
**Solution**: Change DNS record to "DNS only" (gray cloud) instead of "Proxied" (orange cloud)

#### 3. Stunnel Permission Errors
**Problem**: stunnel cannot access SSL certificates or PID directories
**Solution**: Create proper directories with correct ownership:
```bash
sudo mkdir -p /var/run/stunnel4 /var/log/stunnel4
sudo chown stunnel4:stunnel4 /var/run/stunnel4 /var/log/stunnel4
```

#### 4. HTTP Proxy to TCP Service Error
**Problem**: Nginx returns "upstream sent no valid HTTP header" 
**Solution**: Don't proxy HTTP to electrs - use direct SSL termination with stunnel instead

## Maintenance

### SSL Certificate Renewal
- **Automatic**: Handled by `certbot.timer` systemd service
- **Manual**: `sudo certbot renew`
- **Test**: `sudo certbot renew --dry-run`

### Service Monitoring
```bash
# Check all services
./scripts/vps-status.sh

# View logs
./scripts/vps-logs.sh

# Restart services if needed
sudo systemctl restart nginx
sudo systemctl restart stunnel4
```

### Updates
```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Update configurations
git pull
./scripts/update-configs.sh
```

## Security Considerations

1. **SSH Key Authentication**: Only SSH key authentication allowed (no passwords)
2. **Rate Limiting**: Nginx configured with rate limiting (10 req/s, burst 20)
3. **Firewall**: UFW enabled with minimal required ports
4. **SSL/TLS**: All external connections encrypted with Let's Encrypt certificates
5. **Minimal Attack Surface**: Only electrs port and health check exposed

## Performance Notes

- **Memory Usage**: ~50MB for nginx + stunnel + SSH tunnel
- **CPU Usage**: Minimal (mostly I/O bound)
- **Bandwidth**: Depends on electrs usage, typically low
- **Latency**: Additional ~10-50ms due to VPS hop

## Final Service Status

```
✅ Nginx: Running (HTTP health checks)
✅ Stunnel: Running (SSL termination on port 50002)  
✅ SSH Tunnel: Active (home server → VPS port 50005)
✅ SSL Certificate: Valid (auto-renewal enabled)
✅ Firewall: Configured (minimal required ports)
✅ DNS: Direct resolution to VPS IP
```

## Testing the Setup

### Basic Connectivity
```bash
# Health check
curl https://electrs.bittrade.co.in/health

# SSL electrs connection test
echo '{"jsonrpc": "2.0", "method": "server.version", "params": ["Test", "1.4"], "id": 0}' | openssl s_client -connect electrs.bittrade.co.in:50002 -quiet 2>/dev/null
```

### Electrum Client Connection
```bash
# Desktop Electrum
electrum --server electrs.bittrade.co.in:50002:s

# Command line test (if electrum client installed)
electrum -s electrs.bittrade.co.in:50002:s daemon start
```

The service is now fully operational and ready for production use!
