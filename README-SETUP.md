# OEM's Fulcrum Public Gateway - Current Setup Documentation

This document describes the **exact current setup** of your Fulcrum public gateway running on your home server.

## 🏠 Current System Configuration

### Home Server Details
- **Location**: `/home/oem/fulcrum-public-gateway`
- **Operating System**: Linux Mint  
- **Hostname**: `oem-NUC13ANH-B`
- **User**: `oem`

### Domain Configuration
- **Public Domain**: `fulcrum.bittrade.co.in`
- **SSL Email**: `admin@bittrade.co.in`
- **DNS Points To**: `185.18.221.146` (VPS IP)

### VPS Configuration
- **VPS Host**: `vm-374.lnvps.cloud`
- **VPS IP**: `185.18.221.146`
- **VPS User**: `ubuntu`
- **SSH Key**: `/home/oem/.ssh/fulcrum_tunnel`

## ⚡ Fulcrum Server Status

### Current Running Process
```bash
PID: 2287
Command: /usr/local/bin/Fulcrum /home/oem/.fulcrum/fulcrum.conf
Version: Fulcrum 1.9.8
Memory Usage: ~13.4GB
Uptime: 5+ days (started Sep 08, 2025)
```

### Fulcrum Configuration (`/home/oem/.fulcrum/fulcrum.conf`)
```bash
fast-sync = 1000 
datadir = /home/oem/.fulcrum_db
bitcoind = 127.0.0.1:8332
ssl = 0.0.0.0:50002
tcp = 0.0.0.0:50005
cert = /home/oem/.fulcrum/cert.pem
key = /home/oem/.fulcrum/key.pem 
rpcuser = parman
rpcpassword = parman
peering = false
```

### Key Port Bindings
- **Port 50005**: TCP (Plain text Electrum protocol) - Used for tunnel
- **Port 50002**: SSL (Encrypted Electrum protocol) - Local only

## 🔐 SSH Tunnel Configuration

### Current Service
- **Service Name**: `fulcrum-tunnel.service`
- **Status**: Active and running
- **Auto-restart**: Enabled
- **PID**: 1004417 (current process)

### Service Configuration
```ini
[Unit]
Description=Fulcrum SSH Tunnel to VPS
After=network.target
Wants=network.target

[Service]
Type=simple
User=oem
ExecStart=/usr/bin/ssh -i /home/oem/.ssh/fulcrum_tunnel -o ServerAliveInterval=30 -o ServerAliveCountMax=3 -o ExitOnForwardFailure=yes -N -R 50005:localhost:50005 ubuntu@vm-374.lnvps.cloud
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

### Tunnel Details
- **Local Endpoint**: `localhost:50005` (Fulcrum server)
- **Remote Forward**: VPS port 50005 → Home server port 50005
- **Connection**: Home server initiates reverse SSH tunnel to VPS
- **Keep-alive**: 30 second intervals, max 3 failed attempts

## 🌐 Network Architecture

```
Internet User
    ↓
fulcrum.bittrade.co.in:443 (VPS: vm-374.lnvps.cloud)
    ↓ [nginx reverse proxy + SSL termination]
VPS localhost:50005
    ↓ [SSH reverse tunnel]
Home Server (oem-NUC13ANH-B) localhost:50005
    ↓ [Direct connection]
Fulcrum Server Process (PID: 2287)
```

## 🔧 Management Commands

### Service Management
```bash
# Check tunnel status
./scripts/tunnel-status.sh
./scripts/fulcrum-tunnel-status.sh

# Service control
sudo systemctl status fulcrum-tunnel
sudo systemctl restart fulcrum-tunnel
sudo systemctl stop fulcrum-tunnel
sudo systemctl start fulcrum-tunnel

# View logs
sudo journalctl -u fulcrum-tunnel -f
```

### Fulcrum Management
```bash
# Check Fulcrum status
./scripts/check-fulcrum.sh

# Fulcrum service control
sudo systemctl status fulcrum
sudo systemctl restart fulcrum

# Check Fulcrum logs
sudo journalctl -u fulcrum -f
```

### VPS Management (from home server)
```bash
# Check VPS status (requires VPS setup)
./scripts/vps-status.sh

# View VPS logs (requires VPS setup)
./scripts/vps-logs.sh
```

## 🧪 Testing Commands

### Local Testing
```bash
# Test Fulcrum directly
echo '{"method":"server.version","params":["test","1.4"],"id":1}' | nc localhost 50005

# Test tunnel process
ps aux | grep fulcrum-tunnel

# Check port binding
ss -tlnp | grep 50005
```

### Remote Testing (when VPS is fully configured)
```bash
# Test public endpoint
echo '{"method":"server.version","params":["test","1.4"],"id":1}' | \
  openssl s_client -connect fulcrum.bittrade.co.in:443 -quiet 2>/dev/null

# Test with Electrum wallet
electrum --server fulcrum.bittrade.co.in:443:s
```

## 📁 File Locations

### Configuration Files
- **Main Config**: `/home/oem/fulcrum-public-gateway/config.env`
- **Fulcrum Config**: `/home/oem/.fulcrum/fulcrum.conf`
- **SSH Key**: `/home/oem/.ssh/fulcrum_tunnel` (private)
- **SSH Public Key**: `/home/oem/.ssh/fulcrum_tunnel.pub`

### Service Files
- **Systemd Service**: `/etc/systemd/system/fulcrum-tunnel.service`
- **Fulcrum Service**: `/etc/systemd/system/fulcrum.service`

### Data Directories
- **Fulcrum Database**: `/home/oem/.fulcrum_db/`
- **Fulcrum Logs**: `/home/oem/.fulcrum/fulcrum.log`
- **Project Scripts**: `/home/oem/fulcrum-public-gateway/scripts/`

## 🔄 Current Status Summary

### ✅ What's Working
1. **Fulcrum Server**: Running perfectly for 5+ days
2. **SSH Tunnel**: Active with proper service naming
3. **Local Connectivity**: Fulcrum responds to Electrum protocol locally
4. **Configuration**: All config files properly set up
5. **Service Management**: All scripts now work with correct service names

### ⚠️ What Needs VPS Setup
1. **Public SSL Endpoint**: Requires nginx configuration on VPS
2. **SSL Certificates**: Need Let's Encrypt setup on VPS  
3. **Firewall Rules**: VPS ports need to be opened
4. **Public Connectivity**: External users can't connect yet

### 🚀 Next Steps
1. **Run VPS Setup**: Execute `./vps/setup.sh` on the VPS server
2. **Configure SSL**: Set up Let's Encrypt for `fulcrum.bittrade.co.in`
3. **Test Public Access**: Verify external Electrum wallets can connect
4. **Optional**: Implement Port 443 solution for maximum reliability

## 📞 Connection Information

### For Electrum Wallets (when VPS setup is complete)
- **Domain**: `fulcrum.bittrade.co.in`
- **Port**: `443` (recommended) or `50002` (traditional)
- **Protocol**: SSL (`s` flag)
- **Connection String**: `fulcrum.bittrade.co.in:443:s`

### Backup Connection (local network only)
- **Direct Local**: `localhost:50005` (plain TCP)
- **Direct Local SSL**: `localhost:50002` (SSL)

## 🔒 Security Notes

- SSH key authentication (no passwords)
- SSL/TLS encryption for public connections
- Fulcrum configured with minimal attack surface
- Bitcoin Core RPC secured with username/password
- No P2P peering enabled (private Fulcrum instance)

---

**Last Updated**: September 13, 2025  
**Setup Status**: Home server ✅ | VPS setup ⚠️ | Public access ⚠️
