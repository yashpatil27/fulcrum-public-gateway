# Fulcrum Integration Guide

This guide covers using the electrs_pub infrastructure with Fulcrum instead of electrs.

## Quick Switch from Electrs to Fulcrum

If you're already running electrs and want to switch to Fulcrum:

### 1. Configure Fulcrum
Ensure your `fulcrum.conf` includes:
```bash
tcp = 0.0.0.0:50005    # Required for tunnel
ssl = 0.0.0.0:50002    # Optional
```

### 2. Stop Electrs
```bash
# Stop any running electrs process
sudo pkill -f electrs
```

### 3. Start Fulcrum
```bash
# Start Fulcrum service
sudo systemctl start fulcrum

# Check status
./scripts/check-fulcrum.sh
```

### 4. Wait for Sync
Fulcrum needs to complete its initial sync before accepting connections:
```bash
# Monitor sync progress
./scripts/fulcrum-manage.sh sync-status

# Watch logs
journalctl -u fulcrum -f
```

## Fulcrum-Specific Scripts

### Status Checking
```bash
# Comprehensive status check
./scripts/check-fulcrum.sh

# Tunnel status with Fulcrum awareness
./scripts/fulcrum-tunnel-status.sh
```

### Management
```bash
# All management commands
./scripts/fulcrum-manage.sh [command]

# Available commands:
./scripts/fulcrum-manage.sh start
./scripts/fulcrum-manage.sh stop  
./scripts/fulcrum-manage.sh restart
./scripts/fulcrum-manage.sh status
./scripts/fulcrum-manage.sh logs
./scripts/fulcrum-manage.sh sync-status
```

## Fulcrum Configuration

### Minimal Configuration for Tunnel
```bash
# ~/.fulcrum/fulcrum.conf
datadir = /home/user/.fulcrum_db
bitcoind = 127.0.0.1:8332
tcp = 0.0.0.0:50005
rpcuser = your_rpc_user
rpcpassword = your_rpc_password
```

### Full Configuration Example
```bash
# ~/.fulcrum/fulcrum.conf  
datadir = /home/user/.fulcrum_db
bitcoind = 127.0.0.1:8332

# Multiple TCP ports
tcp = 0.0.0.0:50001    # Standard port
tcp = 0.0.0.0:50005    # Tunnel port (required)

# SSL support
ssl = 0.0.0.0:50002
cert = /home/user/.fulcrum/cert.pem
key = /home/user/.fulcrum/key.pem

# Bitcoin RPC
rpcuser = your_rpc_user  
rpcpassword = your_rpc_password

# Performance
fast-sync = 1000
peering = false
```

## Monitoring Fulcrum Sync

### Check if Still Syncing
```bash
# Quick check
./scripts/fulcrum-manage.sh sync-status

# Detailed status
./scripts/check-fulcrum.sh
```

### Monitor Sync Progress
```bash
# Follow logs in real-time
journalctl -u fulcrum -f

# Look for sync-related messages
journalctl -u fulcrum | grep -i sync
```

### Sync Complete Indicators
- Fulcrum accepts connections on port 50005
- No more "syncing" messages in logs  
- `./scripts/check-fulcrum.sh` shows connection success

## Troubleshooting

### Fulcrum Won't Start
```bash
# Check configuration syntax
/usr/local/bin/Fulcrum /home/user/.fulcrum/fulcrum.conf

# Check systemd logs
journalctl -u fulcrum -n 20
```

### Port Configuration Issues
```bash  
# Verify ports in config
grep -E "tcp|ssl" ~/.fulcrum/fulcrum.conf

# Check what's listening
sudo netstat -tlnp | grep -E ":5000"
```

### Sync Taking Too Long
- Normal for initial sync (can take 24-48 hours)
- Monitor with `journalctl -u fulcrum -f`
- Ensure Bitcoin Core is fully synced first
- Check disk space and I/O performance

### Memory Issues
- Fulcrum uses significant RAM during sync (8-30GB)
- This is normal behavior
- Monitor with `free -h` or `htop`

## Performance Notes

### Resource Requirements
- **RAM**: 8-30GB during sync, 4-8GB after
- **Storage**: ~50GB for database
- **CPU**: High during sync, moderate after

### Optimization Tips
- Use fast SSD for `datadir`
- Ensure adequate RAM
- Use `fast-sync` option for faster initial sync
- Monitor with system tools during sync

## Comparison: Electrs vs Fulcrum

| Aspect | Electrs | Fulcrum |
|--------|---------|---------|
| **Sync Time** | Moderate | Slower initial, fast-sync available |
| **Memory** | 2-4GB | 8-30GB during sync |
| **Performance** | Good | Excellent for concurrent users |
| **Config** | TOML format | Key=value format |
| **Features** | Standard Electrum protocol | Extended features, stats |
| **Maintenance** | Lower resource requirements | Higher but more robust |

## Migration Checklist

- [ ] Fulcrum installed and configured
- [ ] `fulcrum.conf` includes `tcp = 0.0.0.0:50005`
- [ ] Bitcoin Core RPC credentials configured
- [ ] Sufficient disk space (50GB+)
- [ ] Sufficient RAM (16GB+ recommended)
- [ ] Electrs stopped (if switching)
- [ ] Fulcrum service started
- [ ] Sync monitoring in place
- [ ] Scripts tested: `./scripts/check-fulcrum.sh`
- [ ] Tunnel status verified: `./scripts/fulcrum-tunnel-status.sh`

## Quick Commands Reference

```bash
# Status checks
./scripts/check-fulcrum.sh
./scripts/fulcrum-manage.sh status
./scripts/fulcrum-manage.sh sync-status

# Service management  
./scripts/fulcrum-manage.sh start|stop|restart

# Monitoring
./scripts/fulcrum-manage.sh logs
journalctl -u fulcrum -f

# Tunnel status
./scripts/fulcrum-tunnel-status.sh
./scripts/tunnel-status.sh
```

The infrastructure remains identical - only the backend server changes!
