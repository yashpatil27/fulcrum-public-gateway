# Fulcrum Public Gateway

A complete solution to expose your home Bitcoin Fulcrum server publicly through a VPS, bypassing CGNAT limitations using SSH reverse tunnels and SSL termination.

## 🏗️ System Overview

This setup consists of two main components:

### 🏠 Home Server (oem-NUC13ANH-B)
- **OS**: Linux Mint  
- **Services**: Bitcoin Core + Fulcrum Server
- **Role**: Runs the actual Bitcoin node and Electrum server
- **Connection**: SSH reverse tunnel to VPS

### ☁️ VPS (vm-374.lnvps.cloud) 
- **OS**: Ubuntu 24.04
- **Services**: Stunnel4 + Nginx
- **Role**: SSL termination and public gateway
- **Domain**: `fulcron.in`

## 🔄 Architecture Flow

```
Bitcoin Wallets → fulcron.in:50002 (SSL)
    ↓ (Stunnel4 SSL Termination on VPS)
VPS localhost:50001
    ↓ (SSH Reverse Tunnel)
Home Server Fulcrum:50001
    ↓ (Local Connection)  
Bitcoin Core (Full Node)
```

## 📱 Wallet Connection

**Connection String**: `fulcron.in:50002:s`

Use this in any Electrum-compatible wallet:
- Electrum Desktop/Mobile
- Blue Wallet  
- Sparrow Wallet
- Any wallet supporting custom Electrum servers

## 📚 Documentation

### Setup & Configuration
- **[HOME-SERVER-README.md](HOME-SERVER-README.md)** - Complete home server setup, Fulcrum configuration, and SSH tunnel management
- **[VPS-README.md](VPS-README.md)** - VPS configuration, SSL termination, and service management

### Project Structure
```
fulcrum-public-gateway/
├── README.md                 # This overview file
├── HOME-SERVER-README.md     # Home server documentation  
├── VPS-README.md            # VPS server documentation
├── config.env               # Configuration variables
├── home-server/             
│   └── setup.sh             # Home server setup script
├── vps/
│   └── setup.sh             # VPS setup script
└── scripts/                 # Management scripts
    ├── tunnel-status.sh     # Check tunnel status
    ├── vps-status.sh        # Check VPS services
    └── [other scripts...]
```

## 🚀 Quick Start

### 1. Initial Setup
```bash
# Clone repository
git clone <repo-url>
cd fulcrum-public-gateway

# Edit configuration
nano config.env
```

### 2. Home Server Setup
```bash
# On your home server (Linux Mint)
./home-server/setup.sh
```

### 3. VPS Setup  
```bash
# On your VPS (Ubuntu)
./vps/setup.sh
```

### 4. Test Connection
```bash
# Test Electrum protocol
echo '{"method":"server.version","params":["test","1.4"],"id":1}' | \
  openssl s_client -connect fulcron.in:50002 -quiet 2>/dev/null
```

## ⚡ Quick Status Check

### Home Server Status
```bash
# Check Fulcrum and tunnel
./scripts/tunnel-status.sh
ps aux | grep -E "(fulcrum|bitcoind)"
```

### VPS Status  
```bash
# Check SSL termination and services
systemctl status nginx stunnel4
ss -tulpn | grep -E "(443|50005)"
```

## 🔧 Configuration

### Main Configuration (`config.env`)
```bash
DOMAIN="fulcron.in"       # Your domain
SSL_EMAIL="admin@fulcron.in"      # Email for SSL certificates
FULCRUM_PORT="50005"                  # Fulcrum server port
VPS_HOST="vm-374.lnvps.cloud"        # VPS hostname
VPS_USER="ubuntu"                     # VPS username
```

### Key Services
- **Home**: Bitcoin Core (port 8332), Fulcrum (port 50005), SSH tunnel
- **VPS**: Stunnel4 (port 50002), Nginx (ports 8080/8443)

## 🔍 Troubleshooting

### Common Issues

**Wallets can't connect**
1. Check VPS services: `systemctl status nginx stunnel4`
2. Check SSH tunnel: `./scripts/tunnel-status.sh`
3. Check SSL certificate: `sudo certbot certificates`

**SSH tunnel disconnects**
1. Check home server internet connection
2. Restart tunnel: `./scripts/tunnel-restart.sh`
3. Check SSH key permissions

**SSL certificate expired**
1. Renew certificate: `sudo certbot renew`
2. Restart services: `sudo systemctl reload stunnel4`

### Log Locations
- **Home Server**: `~/.fulcrum/fulcrum.log`, SSH tunnel logs
- **VPS**: `/var/log/stunnel4/stunnel.log`, `/var/log/nginx/`

## 🛡️ Security Features

- **SSL/TLS Encryption**: All external connections encrypted
- **SSH Key Authentication**: Passwordless tunnel authentication  
- **Firewall Protection**: UFW configured on VPS
- **Rate Limiting**: Nginx rate limiting for DDoS protection
- **Auto SSL Renewal**: Certbot automatic certificate renewal

## 🔄 Maintenance

### Regular Tasks
- Monitor SSL certificate expiry (auto-renews)
- Check tunnel connectivity 
- Update system packages
- Monitor service logs

### Management Scripts
```bash
./scripts/tunnel-status.sh      # Check tunnel status
./scripts/vps-status.sh         # Check VPS services  
./scripts/tunnel-restart.sh     # Restart SSH tunnel
./scripts/renew-ssl.sh          # Manual SSL renewal
```

## 📊 Monitoring

### Health Checks
```bash
# Quick system check
./vps-status-check.sh

# Test wallet connection
echo '{"method":"server.features","params":[],"id":1}' | \
  openssl s_client -connect fulcron.in:50002 -quiet 2>/dev/null

# Check services
systemctl status nginx stunnel4    # VPS
ps aux | grep fulcrum              # Home server
```

## 🆘 Support

### Documentation Links
- **Home Server**: See [HOME-SERVER-README.md](HOME-SERVER-README.md)
- **VPS Configuration**: See [VPS-README.md](VPS-README.md)

### Quick Diagnostics
1. **Connection Test**: Try connecting wallet to `fulcron.in:50002:s`
2. **Service Check**: Run `./vps-status-check.sh` on VPS
3. **Tunnel Check**: Run `./scripts/tunnel-status.sh` on home server
4. **Log Review**: Check stunnel and nginx logs for errors

---

**Current Status**: ✅ Operational  
**Domain**: fulcron.in:50002:s  
**Last Updated**: September 16, 2025

**Components**:
- Home Server: Bitcoin Core + Fulcrum (oem-NUC13ANH-B)
- VPS Gateway: SSL Termination (vm-374.lnvps.cloud)
- Connection: SSH Reverse Tunnel + Stunnel4
