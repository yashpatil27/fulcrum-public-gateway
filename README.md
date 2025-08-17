# Electrum Server Public Gateway Setup

This repository contains the configuration and scripts to expose your home electrum server publicly through a VPS, bypassing CGNAT limitations.

**Supports both Electrs and Fulcrum servers!**

## Overview

- **Home Server**: Runs electrs or Fulcrum locally on configurable port (default: 50005)
- **VPS**: Acts as public gateway with nginx reverse proxy and SSL
- **Connection**: SSH reverse tunnel from home server to VPS
- **Domain**: Configurable (example: electrs.bittrade.co.in)

## Architecture

```
Internet → your-domain.com (VPS) → SSH Tunnel → Home Server (electrs/fulcrum:50005)
```

## Supported Electrum Servers

### Electrs
- Lightweight Rust-based electrum server
- Lower memory usage
- Faster initial sync
- **Scripts**: `check-electrs.sh`, `tunnel-status.sh`

### Fulcrum  
- C++-based electrum server with advanced features
- Higher performance for concurrent connections
- Larger memory footprint
- **Scripts**: `check-fulcrum.sh`, `fulcrum-tunnel-status.sh`, `fulcrum-manage.sh`

**Both servers work with the same infrastructure** - just configure them to listen on port 50005!

## Prerequisites

- Home server running electrs OR Fulcrum (this machine)
- VPS with root/sudo access
- Domain pointing to VPS
- SSH access between home server and VPS

## Quick Start

### 1. Configuration

First, edit the `config.env` file to customize your setup:

```bash
# Edit the main configuration file
nano config.env
```

**Required changes:**
- `DOMAIN`: Replace with your domain (e.g., "electrs.yourdomain.com")
- `SSL_EMAIL`: Replace with your email address for SSL certificates

**Optional changes:**
- `ELECTRS_PORT`: Change if your server runs on a different port
- `SERVICE_NAME`: Change the systemd service name if desired

### 2. Home Server Setup (Current Machine)

Run the home server setup script:
```bash
./home-server/setup.sh
```

This will:
- Load configuration from `config.env`
- Generate SSH keys for the tunnel
- Create systemd service for persistent tunnel
- Set up monitoring and management scripts

### 3. VPS Setup

Clone this repo on your VPS and run:
```bash
./vps/setup.sh
```

This will:
- Load configuration from `config.env`
- Install nginx and certbot
- Configure nginx reverse proxy for your domain
- Set up SSL certificate
- Configure firewall rules

## Server Configuration

### For Electrs Users

Ensure your electrs is configured to listen on port 50005:
```toml
# In your electrs config.toml
electrum_rpc_addr = "0.0.0.0:50005"
```

### For Fulcrum Users

Ensure your Fulcrum is configured to listen on port 50005:
```bash
# In your fulcrum.conf
tcp = 0.0.0.0:50005
ssl = 0.0.0.0:50002  # Optional: for direct SSL connections
```

You can have Fulcrum listen on multiple ports:
```bash
tcp = 0.0.0.0:50001   # Standard unencrypted port
tcp = 0.0.0.0:50005   # Tunnel port (required for this setup)
ssl = 0.0.0.0:50002   # SSL port
```

## Configuration File

The `config.env` file contains all configurable values:

```bash
# Domain Configuration
DOMAIN="electrs.bittrade.co.in"          # Change this!
SSL_EMAIL="admin@bittrade.co.in"         # Change this!

# Port Configuration  
ELECTRS_PORT="50005"                     # Usually fine as-is
ELECTRS_SSL_PORT="50002"                 # Usually fine as-is
SSH_PORT="22"                            # Usually fine as-is

# Service Configuration
SERVICE_NAME="electrs-tunnel"            # Usually fine as-is
SSH_KEY_NAME="electrs_tunnel"            # Usually fine as-is
```

All scripts automatically load this configuration, making the setup portable across different domains and environments.

## Management Scripts

### Universal Scripts (work with both servers)
```bash
./scripts/tunnel-status.sh      # Check tunnel status
./scripts/tunnel-start.sh       # Start tunnel service
./scripts/tunnel-stop.sh        # Stop tunnel service  
./scripts/tunnel-restart.sh     # Restart tunnel service
./scripts/vps-status.sh         # Check VPS nginx and SSL status
./scripts/vps-logs.sh           # View VPS logs
./scripts/renew-ssl.sh          # Manually renew SSL certificate
./scripts/update-configs.sh     # Update configs from git
```

### Electrs-Specific Scripts
```bash
./scripts/check-electrs.sh      # Check electrs status and configuration
```

### Fulcrum-Specific Scripts
```bash
./scripts/check-fulcrum.sh           # Check Fulcrum status and configuration  
./scripts/fulcrum-tunnel-status.sh   # Tunnel status with Fulcrum awareness
./scripts/fulcrum-manage.sh status   # Comprehensive Fulcrum management
./scripts/fulcrum-manage.sh logs     # View Fulcrum logs
./scripts/fulcrum-manage.sh sync-status  # Check if still syncing
```

### Fulcrum Management Examples
```bash
# Check if Fulcrum is still syncing
./scripts/fulcrum-manage.sh sync-status

# View recent logs
./scripts/fulcrum-manage.sh logs

# Restart Fulcrum
./scripts/fulcrum-manage.sh restart

# Full status check
./scripts/check-fulcrum.sh
```

## File Structure

### Configuration
- **config.env**: Main configuration file (edit this!)
- **.electrs_config**: Runtime config (auto-generated by setup)

### Setup Scripts
- **home-server/setup.sh**: Initial home server setup
- **vps/setup.sh**: Initial VPS setup

## Testing

### For Electrs
1. **Test electrs locally**:
   ```bash
   telnet localhost 50005
   ```

2. **Check electrs status**:
   ```bash
   ./scripts/check-electrs.sh
   ```

### For Fulcrum  
1. **Test Fulcrum locally**:
   ```bash
   telnet localhost 50005
   ```

2. **Check Fulcrum status**:
   ```bash
   ./scripts/check-fulcrum.sh
   ```

3. **Check sync status**:
   ```bash
   ./scripts/fulcrum-manage.sh sync-status
   ```

### Universal Tests
1. **Test tunnel connection**:
   ```bash
   ./scripts/tunnel-status.sh
   ```

2. **Test public endpoint**:
   ```bash
   curl -k https://your-domain.com
   ```

3. **Test electrum client connection**:
   ```bash
   electrum --server your-domain.com:50002:s
   ```

## Switching Between Servers

You can switch between electrs and Fulcrum without changing your infrastructure:

### From Electrs to Fulcrum:
1. Stop electrs
2. Configure Fulcrum to listen on port 50005  
3. Start Fulcrum
4. Wait for sync to complete

### From Fulcrum to Electrs:
1. Stop Fulcrum
2. Configure electrs to listen on port 50005
3. Start electrs  
4. Wait for sync to complete

**The tunnel, VPS, and public domain work identically with both servers!**

## Troubleshooting

### Common Issues

1. **Tunnel disconnects**:
   - Check `./scripts/tunnel-status.sh`
   - Restart with `./scripts/tunnel-restart.sh`

2. **SSL certificate issues**:
   - Check certificate expiry: `./scripts/vps-status.sh`
   - Renew manually: `sudo ./scripts/renew-ssl.sh`

3. **Server not accessible**:
   - **For electrs**: Check `./scripts/check-electrs.sh`
   - **For Fulcrum**: Check `./scripts/check-fulcrum.sh`
   - Check server logs

### Fulcrum-Specific Issues

1. **Fulcrum not accepting connections**:
   - Check if still syncing: `./scripts/fulcrum-manage.sh sync-status`
   - Monitor sync progress: `journalctl -u fulcrum -f`

2. **High memory usage**:
   - Normal for Fulcrum during sync
   - Monitor with `./scripts/fulcrum-manage.sh status`

### Log Locations

- **Tunnel logs**: `journalctl -u electrs-tunnel -f`
- **Electrs logs**: `~/.electrs/run_electrs.log` 
- **Fulcrum logs**: `journalctl -u fulcrum -f`
- **Nginx logs**: `/var/log/nginx/[domain].*.log`

## Security Notes

- SSH keys are used for authentication (no passwords)
- Only the electrum server port is forwarded through the tunnel
- SSL/TLS encryption for all external connections
- Nginx rate limiting configured
- Firewall rules restrict access to necessary ports only

## Port Mapping

| Service | Home Server | VPS | Public |
|---------|-------------|-----|--------|
| Electrs/Fulcrum | 50005 (configurable) | 50005 | 443 (HTTPS) |
| Fulcrum SSL | 50002 (optional) | - | - |
| SSH Tunnel | - | 22 | - |

## Server Comparison

| Feature | Electrs | Fulcrum |
|---------|---------|---------|
| Language | Rust | C++ |
| Memory Usage | Lower (~2-4GB) | Higher (~8-30GB) |
| Sync Time | Moderate | Slower initial, but has fast-sync |
| Performance | Good | Excellent for many clients |
| Features | Standard | Advanced (stats, multiple coins) |
| Configuration | TOML file | Simple key=value |

## Sharing This Repository

This repository is now fully configurable and can be shared with others. To use it:

1. **Clone the repository**
2. **Edit `config.env`** - change domain and email at minimum
3. **Configure your electrum server** (electrs or Fulcrum) to listen on port 50005
4. **Run setup scripts** as documented above

The scripts automatically load configuration from `config.env`, so no hardcoded values need to be changed in the scripts themselves.

## Updates and Maintenance

1. **Update configurations**:
   ```bash
   git pull
   ./scripts/update-configs.sh
   ```

2. **Monitor SSL expiry**:
   - Certificates auto-renew via cron
   - Manual renewal: `sudo ./scripts/renew-ssl.sh`

3. **Monitor tunnel health**:
   - Service automatically restarts on failure
   - Monitor with `./scripts/tunnel-status.sh`

4. **Monitor your electrum server**:
   - **Electrs**: `./scripts/check-electrs.sh`
   - **Fulcrum**: `./scripts/check-fulcrum.sh`

## Support

Check logs and run diagnostic scripts if issues arise. The systemd service will automatically attempt to reconnect if the tunnel drops.

For configuration issues, verify that `config.env` has been properly edited with your domain and email address.

## Quick Setup Guide

For new users, the fastest way to get started:

1. **Clone and configure**: `git clone [repo] && cd electrs_pub && ./validate-config.sh`
2. **Edit config.env**: Change domain and email
3. **Configure your server**: Ensure electrs or Fulcrum listens on port 50005
4. **Run setup**: `./home-server/setup.sh` then `./vps/setup.sh` on VPS

> **Note**: This repository is fully configurable via `config.env` and supports both electrs and Fulcrum servers!
