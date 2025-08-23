# Electrum Server Public Gateway Setup

This repository contains the configuration and scripts to expose your home electrum server publicly through a VPS, bypassing CGNAT limitations.

**Supports both Electrs and Fulcrum servers!**

## 🚀 **NEW: Port 443 Solution**

**RECOMMENDED**: Use the **Port 443 Solution** for maximum reliability. Many VPS providers now block cryptocurrency-related ports like 50002, but port 443 (HTTPS) is never blocked.

**Quick Setup for Port 443**:
- Your wallets connect to: `your-domain.com:443:s`  
- See [PORT-443-SOLUTION.md](PORT-443-SOLUTION.md) for complete details

## Overview

- **Home Server**: Runs electrs or Fulcrum locally on configurable port (default: 50005)
- **VPS**: Acts as public gateway with nginx reverse proxy and SSL
- **Connection**: SSH reverse tunnel from home server to VPS
- **Domain**: Configurable (example: fulcrum.bittrade.co.in)

## Architecture

```
Internet → your-domain.com (VPS) → SSH Tunnel → Home Server (electrs/fulcrum:50005)
```

### Traditional Setup (Port 50002)
```
Electrum Wallet → domain.com:50002:s (SSL)
    ↓ (stunnel SSL termination)
VPS localhost:50005
    ↓ (SSH reverse tunnel)
Home Server Fulcrum:50005
```

### Port 443 Solution (Recommended)
```
Electrum Wallet → domain.com:443:s (SSL)
    ↓ (stunnel on port 443)
VPS localhost:50005
    ↓ (SSH reverse tunnel)
Home Server Fulcrum:50005
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
- `DOMAIN`: Replace with your domain (e.g., "fulcrum.yourdomain.com")
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

### 4. Choose Your Port Configuration

#### Option A: Port 443 Solution (Recommended)

**Benefits**: Never blocked, appears as normal HTTPS traffic, maximum reliability

**Setup**: Follow the [PORT-443-SOLUTION.md](PORT-443-SOLUTION.md) guide

**Wallet Connection**: `your-domain.com:443:s`

#### Option B: Traditional Port 50002

**Benefits**: Standard Electrum port, traditional setup

**Setup**: Use the standard VPS setup script (above)

**Wallet Connection**: `your-domain.com:50002:s`

**Note**: May be blocked by some VPS providers

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

## Configuration File

The `config.env` file contains all configurable values:

```bash
# Domain Configuration
DOMAIN="fulcrum.bittrade.co.in"          # Change this!
SSL_EMAIL="admin@bittrade.co.in"         # Change this!

# Port Configuration  
ELECTRS_PORT="50005"                     # Usually fine as-is
ELECTRS_SSL_PORT="50002"                 # Usually fine as-is (or 443)
SSH_PORT="22"                            # Usually fine as-is

# Service Configuration
SERVICE_NAME="electrs-tunnel"            # Usually fine as-is
SSH_KEY_NAME="electrs_tunnel"            # Usually fine as-is
```

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

## Connection Examples

### Port 443 Solution (Recommended)
```bash
# Electrum Desktop
electrum --server your-domain.com:443:s

# Electrum Client Test
echo '{"method":"server.version","params":["test","1.4"],"id":1}' | \
  openssl s_client -connect your-domain.com:443 -quiet 2>/dev/null
```

### Traditional Port 50002
```bash
# Electrum Desktop
electrum --server your-domain.com:50002:s

# Electrum Client Test  
echo '{"method":"server.version","params":["test","1.4"],"id":1}' | \
  openssl s_client -connect your-domain.com:50002 -quiet 2>/dev/null
```

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
   curl -k https://your-domain.com/health
   ```

## Troubleshooting

**Connection Issues?** See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for comprehensive solutions.

**Port 50002 Blocked?** Use the [Port 443 Solution](PORT-443-SOLUTION.md).

**Common fixes:**
- Restart services: `sudo systemctl restart nginx stunnel4`
- Restart tunnel: `sudo systemctl restart electrs-tunnel` (on home server)
- Check logs: `sudo journalctl -u stunnel4 -f`

## Security Notes

- SSH keys are used for authentication (no passwords)
- Only the electrum server port is forwarded through the tunnel
- SSL/TLS encryption for all external connections
- Nginx rate limiting configured
- Firewall rules restrict access to necessary ports only

## Port Comparison

| Configuration | External Port | Benefits | Drawbacks |
|---------------|---------------|----------|-----------|
| **Port 443 (Recommended)** | 443 | Never blocked, stealth mode, maximum reliability | Requires nginx port change |
| **Port 50002 (Traditional)** | 50002 | Standard Electrum port, simple setup | May be blocked by VPS providers |

## Server Comparison

| Feature | Electrs | Fulcrum |
|---------|---------|---------| 
| Language | Rust | C++ |
| Memory Usage | Lower (~2-4GB) | Higher (~8-30GB) |
| Sync Time | Moderate | Slower initial, but has fast-sync |
| Performance | Good | Excellent for many clients |
| Features | Standard | Advanced (stats, multiple coins) |
| Configuration | TOML file | Simple key=value |

## Documentation

- **[PORT-443-SOLUTION.md](PORT-443-SOLUTION.md)**: Complete guide for port 443 setup
- **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)**: Comprehensive troubleshooting guide
- **[FULCRUM-GUIDE.md](FULCRUM-GUIDE.md)**: Fulcrum-specific setup and management
- **[VPS-SETUP.md](VPS-SETUP.md)**: Detailed VPS configuration documentation

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

## Support

- Check [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for common issues
- Run diagnostic scripts if problems arise
- Verify `config.env` has been properly edited with your domain and email

## Quick Setup Summary

1. **Clone and configure**: `git clone [repo] && cd electrs-public-gateway`
2. **Edit config.env**: Change domain and email
3. **Configure your server**: Ensure electrs or Fulcrum listens on port 50005
4. **Run setup**: `./home-server/setup.sh` then `./vps/setup.sh` on VPS
5. **Choose port**: Use port 443 for maximum reliability

> **Recommendation**: Use the **Port 443 Solution** for production deployments to ensure maximum uptime and reliability.
