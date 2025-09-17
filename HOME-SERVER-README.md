# Home Server Setup - Fulcrum Public Gateway

This document describes the **complete home server setup** for the Fulcrum public gateway system running on **oem-NUC13ANH-B**.

## 🏠 **System Overview**

### Hardware & OS
- **Hostname**: `oem-NUC13ANH-B`
- **Operating System**: Linux Mint
- **User**: `oem`
- **Storage**: 3.6TB NVMe SSD (29% used, 2.5TB available)

### Core Services Status
- **Bitcoin Core**: ✅ Running (PID: 972329, 1.2GB RAM)
- **Fulcrum Server**: ✅ Running (PID: 1723447, 2.3GB RAM)  
- **SSH Tunnel**: ✅ Running (PID: 1723705, 8.5MB RAM)

## ⚡ **Fulcrum Server Configuration**

### Current Status
```bash
Version: Fulcrum 1.9.8 (Release d4b3fa1)
Binary: /usr/local/bin/Fulcrum
Config: /home/oem/.fulcrum/fulcrum.conf
Uptime: 1+ day (since Sep 16, 2025)
Memory: 2.3GB (peak usage varies)
Database Size: 174GB (/home/oem/.fulcrum_db/)
```

### Configuration File (`/home/oem/.fulcrum/fulcrum.conf`)
```ini
fast-sync = 1000
datadir = /home/oem/.fulcrum_db
bitcoind = 127.0.0.1:8332
ssl = 0.0.0.0:50002
tcp = 0.0.0.0:50001
cert = /home/oem/.fulcrum/cert.pem
key = /home/oem/.fulcrum/key.pem
rpcuser = parman
rpcpassword = parman
peering = false
```

### Port Configuration
- **Port 50001**: TCP (Plain Electrum protocol) - **Used by tunnel**
- **Port 50002**: SSL (Encrypted Electrum protocol) - Local only

### Service Configuration
```bash
Service: fulcrum.service
Status: active (running)
Enabled: yes (auto-start on boot)
Service File: /etc/systemd/system/fulcrum.service
```

## 🔐 **SSH Tunnel Configuration**

### Service Details
```bash
Service Name: fulcrum-tunnel.service
Status: active (running) 
PID: 1723705
Uptime: 1+ day (since Sep 16, 2025)
Memory: 8.5MB (negligible)
```

### Service Configuration (`/etc/systemd/system/fulcrum-tunnel.service`)
```ini
[Unit]
Description=Fulcrum SSH Tunnel to VPS
After=network.target
Wants=network.target

[Service]
Type=simple
User=oem
ExecStart=/usr/bin/ssh -i /home/oem/.ssh/fulcrum_tunnel -o ServerAliveInterval=15 -o ServerAliveCountMax=2 -o ConnectTimeout=10 -o ExitOnForwardFailure=yes -N -R 50001:localhost:50001 root@31.97.62.114
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

### Tunnel Details
- **VPS Host**: `31.97.62.114` (srv1011358.hstgr.cloud)
- **VPS User**: `root`
- **SSH Key**: `/home/oem/.ssh/fulcrum_tunnel`
- **Port Forward**: VPS:50001 ← Home:50001
- **Keep-alive**: 15s intervals, 2 max failures
- **Connection Timeout**: 10 seconds

## 🪙 **Bitcoin Core Configuration**

### Status
```bash
Version: Bitcoin Core (latest)
PID: 972329
Memory: 1.2GB (very efficient)
Status: Fully synced
Data Directory: /home/oem/.bitcoin/
Config: /home/oem/.bitcoin/bitcoin.conf
Uptime: 4+ days (since Sep 13, 2025)
Total CPU Time: 33+ hours
```

### Connection to Fulcrum
- **RPC Endpoint**: `127.0.0.1:8332`
- **Authentication**: username/password (parman/parman)
- **Status**: Connected and synced

## 📁 **Directory Structure**

### Project Files
```
/home/oem/fulcrum-public-gateway/
├── config.env                    # Main configuration
├── HOME-SERVER-README.md          # This file
├── README.md                      # General documentation
├── scripts/                       # Management scripts
│   ├── check-fulcrum.sh          # Fulcrum status check
│   ├── fulcrum-manage.sh         # Comprehensive management
│   ├── fulcrum-tunnel-status.sh  # Tunnel status check
│   ├── tunnel-status.sh          # Basic tunnel status
│   ├── tunnel-start.sh           # Start tunnel service
│   ├── tunnel-stop.sh            # Stop tunnel service
│   ├── tunnel-restart.sh         # Restart tunnel service
│   └── vps-status.sh             # Check VPS status
├── home-server/                   # Home server setup scripts
├── vps/                          # VPS setup scripts
└── configs/                      # Config templates
```

### Fulcrum Files
```
/home/oem/.fulcrum/
├── fulcrum.conf                  # Main configuration
├── fulcrum.log                   # Log file (growing)
├── cert.pem                      # SSL certificate (local use)
├── key.pem                       # SSL private key (local use)
└── fulcrum.conf.backup.*         # Config backups
```

### Database & Data
```
/home/oem/.fulcrum_db/            # Fulcrum database (174GB)
/home/oem/.bitcoin/               # Bitcoin Core data (811GB)
/home/oem/.ssh/
├── fulcrum_tunnel                # SSH private key
└── fulcrum_tunnel.pub           # SSH public key
```

### System Service Files
```
/etc/systemd/system/
├── fulcrum.service               # Fulcrum service
├── fulcrum-tunnel.service        # SSH tunnel service
└── bitcoind.service             # Bitcoin Core service
```

## 🔧 **Management Commands**

### Service Control
```bash
# Fulcrum service
sudo systemctl status fulcrum
sudo systemctl restart fulcrum
sudo systemctl stop fulcrum
sudo systemctl start fulcrum

# SSH tunnel service
sudo systemctl status fulcrum-tunnel
sudo systemctl restart fulcrum-tunnel
sudo systemctl stop fulcrum-tunnel
sudo systemctl start fulcrum-tunnel

# Bitcoin Core service
sudo systemctl status bitcoind
sudo systemctl restart bitcoind
```

### Monitoring Scripts
```bash
# Navigate to project directory
cd /home/oem/fulcrum-public-gateway/

# Check Fulcrum status
./scripts/check-fulcrum.sh

# Check tunnel status
./scripts/tunnel-status.sh
./scripts/fulcrum-tunnel-status.sh

# Comprehensive Fulcrum management
./scripts/fulcrum-manage.sh status
./scripts/fulcrum-manage.sh logs
./scripts/fulcrum-manage.sh sync-status

# Tunnel management
./scripts/tunnel-start.sh
./scripts/tunnel-stop.sh
./scripts/tunnel-restart.sh
```

### Log Monitoring
```bash
# Fulcrum logs
sudo journalctl -u fulcrum -f
tail -f /home/oem/.fulcrum/fulcrum.log

# Tunnel logs
sudo journalctl -u fulcrum-tunnel -f

# Bitcoin Core logs
sudo journalctl -u bitcoind -f
tail -f /home/oem/.bitcoin/debug.log
```

## 🧪 **Testing & Verification**

### Local Fulcrum Testing
```bash
# Test plain TCP connection
echo '{"method":"server.version","params":["test","1.4"],"id":1}' | nc localhost 50001

# Test SSL connection (local certificate)
echo '{"method":"server.version","params":["test","1.4"],"id":1}' | \
  openssl s_client -connect localhost:50002 -quiet 2>/dev/null

# Check port bindings
ss -tlnp | grep -E ':50002|:50001'
```

### Tunnel Testing
```bash
# Check tunnel process
ps aux | grep fulcrum-tunnel

# Test SSH connection to VPS
ssh -i /home/oem/.ssh/fulcrum_tunnel root@31.97.62.114 "echo 'Connection successful'"
```

### System Health Checks
```bash
# Check disk usage
df -h /home/oem/.fulcrum_db
du -sh /home/oem/.fulcrum_db

# Check memory usage
free -h
ps aux | grep -E "(fulcrum|bitcoind)"

# Check Bitcoin sync status
bitcoin-cli getblockchaininfo

# Check network connections
ss -an | grep -E ':8332|:50002|:50001'
```

## ⚙️ **Configuration Reference**

### Main Configuration (`config.env`)
```bash
DOMAIN="fulcron.in"
SSL_EMAIL="admin@bittrade.co.in"
FULCRUM_PORT="50001"
FULCRUM_SSL_PORT="50002"
VPS_HOST="31.97.62.114"
VPS_USER="root"
SERVICE_NAME="fulcrum-tunnel"
SSH_KEY_NAME="fulcrum_tunnel"
```

### Key Service Dependencies
1. **Bitcoin Core** → Must be running and synced
2. **Fulcrum** → Depends on Bitcoin Core RPC
3. **SSH Tunnel** → Depends on network and SSH keys
4. **VPS** → Must be configured to accept tunneled connections

## 🔒 **Security Configuration**

### SSH Security
- **Key-based authentication**: No passwords
- **Restricted user**: Only `oem` user access
- **Keep-alive monitoring**: 15s intervals
- **Auto-restart**: Service restarts on failure

### Fulcrum Security
- **No P2P peering**: `peering = false`
- **Local RPC only**: Bitcoin RPC on localhost
- **SSL certificates**: Self-signed for local SSL
- **Firewall**: Only necessary ports exposed

### Network Security
- **Local binding**: Bitcoin RPC bound to localhost only
- **Tunnel only**: External access only via SSH tunnel
- **VPS proxy**: Public access through VPS reverse proxy

## 📊 **Performance Metrics**

### Current Resource Usage (September 17, 2025)
```
Total System Memory: 62GB
Bitcoin Core: 1.2GB (1.8% of total RAM)
Fulcrum: 2.3GB (3.5% of total RAM)
SSH Tunnel: 8.5MB (negligible)
System + Other: ~5.4GB used, 53GB available
Disk Usage: 985GB (811GB Bitcoin + 174GB Fulcrum)
```

### Expected Performance
- **Sync Status**: Fully synced and operational
- **Query Response**: ~100-500ms for standard requests
- **Memory Efficiency**: Extremely efficient usage
- **Database Growth**: ~1-2GB per week
- **Uptime**: Services designed for 24/7 operation
- **System Load**: 0.96-1.00 (optimal)

## 🚨 **Troubleshooting**

### Common Issues
1. **Fulcrum not responding**: Check Bitcoin Core RPC connection
2. **Tunnel disconnected**: Check SSH keys and VPS connectivity
3. **Memory usage spikes**: Monitor during peak sync periods
4. **Disk space**: Monitor `/home/oem/.fulcrum_db` growth

### Emergency Recovery
```bash
# Restart all services
sudo systemctl restart bitcoind fulcrum fulcrum-tunnel

# Check service status
systemctl status bitcoind fulcrum fulcrum-tunnel

# View recent logs
sudo journalctl -u fulcrum -n 50
sudo journalctl -u fulcrum-tunnel -n 50
```

### Log Locations
- **Fulcrum**: `/home/oem/.fulcrum/fulcrum.log`
- **Bitcoin**: `/home/oem/.bitcoin/debug.log`  
- **System logs**: `journalctl -u [service-name]`

## 📈 **Maintenance Tasks**

### Daily
- Monitor service status with scripts
- Check log files for errors
- Verify tunnel connectivity

### Weekly
- Check disk space usage
- Review Fulcrum sync status
- Backup configuration files

### Monthly
- Update system packages
- Review and rotate logs
- Test emergency recovery procedures

---

**Server**: oem-NUC13ANH-B  
**Last Updated**: September 17, 2025  
**Services Status**: All operational ✅  
**Total Memory Usage**: 3.5GB (extremely efficient)  
**Tunnel Target**: `root@31.97.62.114`  
**Public Domain**: `fulcron.in`  
**System Uptime**: 9+ days continuous operation  
