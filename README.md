# Electrs Public Gateway Setup

This repository contains the configuration and scripts to expose your home electrs server publicly through a VPS, bypassing CGNAT limitations.

## Overview

- **Home Server**: Runs electrs locally on port 50005
- **VPS**: Acts as public gateway with nginx reverse proxy and SSL
- **Connection**: SSH reverse tunnel from home server to VPS
- **Domain**: electrs.bittrade.co.in

## Architecture

```
Internet → electrs.bittrade.co.in (VPS) → SSH Tunnel → Home Server (electrs:50005)
```

## Prerequisites

- Home server running electrs (this machine)
- VPS with root/sudo access
- Domain `bittrade.co.in` pointing to VPS
- SSH access between home server and VPS

## Setup Instructions

### 1. Home Server Setup (Current Machine)

Run the home server setup script:
```bash
./home-server/setup.sh
```

This will:
- Generate SSH keys for the tunnel
- Create systemd service for persistent tunnel
- Set up monitoring and management scripts

### 2. VPS Setup

Clone this repo on your VPS and run:
```bash
./vps/setup.sh
```

This will:
- Install nginx and certbot
- Configure nginx reverse proxy
- Set up SSL certificate for electrs.bittrade.co.in
- Configure firewall rules

## Configuration

### Home Server Configuration
- **Electrs Config**: `/home/oem/.electrs/config.toml`
- **Tunnel Service**: `/etc/systemd/system/electrs-tunnel.service`
- **SSH Key**: `~/.ssh/electrs_tunnel`

### VPS Configuration
- **Nginx Config**: `/etc/nginx/sites-available/electrs.bittrade.co.in`
- **SSL Certificate**: Managed by Let's Encrypt

## Management Scripts

### Home Server Scripts
```bash
./scripts/tunnel-status.sh      # Check tunnel status
./scripts/tunnel-start.sh       # Start tunnel service
./scripts/tunnel-stop.sh        # Stop tunnel service  
./scripts/tunnel-restart.sh     # Restart tunnel service
./scripts/check-electrs.sh      # Check if electrs is running
```

### VPS Scripts
```bash
./scripts/vps-status.sh         # Check nginx and SSL status
./scripts/vps-logs.sh           # View nginx logs
./scripts/renew-ssl.sh          # Manually renew SSL certificate
```

## Testing

1. **Test electrs locally**:
   ```bash
   telnet localhost 50005
   ```

2. **Test tunnel connection**:
   ```bash
   ./scripts/tunnel-status.sh
   ```

3. **Test public endpoint**:
   ```bash
   curl -k https://electrs.bittrade.co.in
   ```

4. **Test electrum connection**:
   ```bash
   electrum --server electrs.bittrade.co.in:50002:s
   ```

## Troubleshooting

### Common Issues

1. **Tunnel disconnects**:
   - Check `systemctl status electrs-tunnel`
   - Restart with `./scripts/tunnel-restart.sh`

2. **SSL certificate issues**:
   - Check certificate expiry: `./scripts/vps-status.sh`
   - Renew manually: `./scripts/renew-ssl.sh`

3. **Electrs not accessible**:
   - Check if electrs is running: `./scripts/check-electrs.sh`
   - Check electrs logs: `tail -f ~/.electrs/run_electrs.log`

### Log Locations

- **Tunnel logs**: `journalctl -u electrs-tunnel -f`
- **Electrs logs**: `~/.electrs/run_electrs.log`
- **Nginx logs**: `/var/log/nginx/electrs.bittrade.co.in.*.log`

## Security Notes

- SSH keys are used for authentication (no passwords)
- Only port 50005 is forwarded through the tunnel
- SSL/TLS encryption for all external connections
- Nginx rate limiting configured
- Firewall rules restrict access to necessary ports only

## Port Mapping

| Service | Home Server | VPS | Public |
|---------|-------------|-----|--------|
| Electrs | 50005 | 50005 | 443 (HTTPS) |
| SSH Tunnel | - | 22 | - |

## Updates and Maintenance

1. **Update configurations**:
   ```bash
   git pull
   ./scripts/update-configs.sh
   ```

2. **Monitor SSL expiry**:
   - Certificates auto-renew via cron
   - Manual renewal: `./scripts/renew-ssl.sh`

3. **Monitor tunnel health**:
   - Service automatically restarts on failure
   - Monitor with `./scripts/tunnel-status.sh`

## Support

Check logs and run diagnostic scripts if issues arise. The systemd service will automatically attempt to reconnect if the tunnel drops.
