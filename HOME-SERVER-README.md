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
