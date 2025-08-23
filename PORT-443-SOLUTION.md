# Port 443 Solution for Fulcrum Public Gateway

## Overview

This document describes the **Port 443 Solution** - a robust configuration that uses port 443 for SSL Electrum connections instead of the traditional port 50002. This solution was developed to address VPS provider restrictions on cryptocurrency-related ports.

## Problem Background

Many VPS providers have started implementing automated detection and blocking of cryptocurrency-related services. Port 50002 is the standard Electrum server port and is often flagged by automated systems, leading to:

- Connections working initially, then suddenly stopping
- No external traffic reaching the service
- Standard web ports (80, 443) continuing to work normally

## Solution Architecture

```
Electrum Wallet → fulcrum.bittrade.co.in:443 (SSL)
    ↓ (stunnel SSL termination with valid cert)
VPS localhost:50005
    ↓ (SSH reverse tunnel)  
Home Server Fulcrum:50005
    ↓ (Response: Fulcrum data)
Electrum Wallet receives data ✅
```

## Implementation Details

### VPS Configuration Changes

1. **Stunnel moved to port 443** (from 50002)
2. **Nginx moved to ports 8080/8443** (from 80/443) 
3. **Same SSL certificates** used for stunnel
4. **Same firewall rules** (443 was already open)

### Files Modified

**`/etc/stunnel/electrs.conf`**:
```ini
pid = /var/run/stunnel4/stunnel.pid
output = /var/log/stunnel4/stunnel.log

[fulcrum-ssl]
accept = 443
connect = 127.0.0.1:50005
cert = /etc/letsencrypt/live/fulcrum.bittrade.co.in/fullchain.pem
key = /etc/letsencrypt/live/fulcrum.bittrade.co.in/privkey.pem
```

**Nginx configurations**: Updated to use ports 8080 and 8443

### Home Server Configuration

**No changes required!** The SSH tunnel configuration remains identical:
- Still connects to port 50005 on the VPS
- Fulcrum still runs on port 50005 locally
- All existing scripts and services work unchanged

## Benefits

✅ **Always accessible**: Port 443 is never blocked by providers  
✅ **Stealth mode**: Appears as normal HTTPS traffic  
✅ **No home changes**: Existing setup works unchanged  
✅ **Standard practice**: Many public Electrum servers use port 443  
✅ **Reliable**: Web-standard port with guaranteed routing  

## Connection Details

### For Electrum Wallets
```
fulcrum.bittrade.co.in:443:s
```

### For Testing
```bash
# Test connection
echo '{"id":1,"method":"server.version","params":["test","1.4"]}' | \
openssl s_client -connect fulcrum.bittrade.co.in:443 -quiet 2>/dev/null

# Expected response
{"id":1,"jsonrpc":"2.0","result":["Fulcrum 1.9.8","1.4"]}
```

## Port Mapping

| Service | Home Server | VPS Internal | VPS External | Public Access |
|---------|-------------|-------------|--------------|---------------|
| Fulcrum | 50005 | 50005 (SSH tunnel) | 443 (stunnel) | fulcrum.domain.com:443 |
| Nginx HTTP | - | 8080 | - | - |
| Nginx HTTPS | - | 8443 | - | - |

## Troubleshooting

### If Port 443 Doesn't Work

1. **Check stunnel status**:
   ```bash
   sudo systemctl status stunnel4
   sudo ss -tlnp | grep :443
   ```

2. **Test local connection**:
   ```bash
   echo '{"method":"server.version"}' | nc localhost 443
   ```

3. **Check SSL certificate**:
   ```bash
   echo | openssl s_client -connect localhost:443 -servername fulcrum.bittrade.co.in
   ```

### If SSH Tunnel Issues

The SSH tunnel configuration doesn't need to change, but if there are issues:

1. **Check tunnel status**:
   ```bash
   # On home server
   ./scripts/tunnel-status.sh
   ```

2. **Restart tunnel**:
   ```bash
   # On home server  
   sudo systemctl restart electrs-tunnel
   ```

## Migration Steps

If migrating from port 50002 to port 443:

### On VPS:

1. **Move nginx to different ports**:
   ```bash
   sudo sed -i 's/listen 80;/listen 8080;/g' /etc/nginx/sites-enabled/*
   sudo sed -i 's/listen 443/listen 8443/g' /etc/nginx/sites-enabled/*
   ```

2. **Update stunnel configuration**:
   ```bash
   sudo tee /etc/stunnel/electrs.conf << 'EOF'
   pid = /var/run/stunnel4/stunnel.pid
   output = /var/log/stunnel4/stunnel.log
   
   [fulcrum-ssl]
   accept = 443
   connect = 127.0.0.1:50005
   cert = /etc/letsencrypt/live/fulcrum.bittrade.co.in/fullchain.pem
   key = /etc/letsencrypt/live/fulcrum.bittrade.co.in/privkey.pem
   EOF
   ```

3. **Restart services**:
   ```bash
   sudo systemctl restart nginx
   sudo systemctl restart stunnel4
   ```

4. **Update firewall** (if needed):
   ```bash
   sudo ufw allow 8080/tcp
   sudo ufw allow 8443/tcp
   ```

### On Home Server:
**No changes required** - existing configuration continues to work.

## Why This Solution Works

1. **Port 443 is privileged**: Only system services use it, never blocked
2. **HTTPS traffic pattern**: Looks like normal web traffic to DPI systems  
3. **Standard SSL port**: Expected to carry encrypted traffic
4. **Provider-agnostic**: Works across all VPS providers
5. **Future-proof**: Won't be affected by anti-crypto measures

## Performance

No performance impact - the connection flow is identical, just using a different external port.

## Security

Enhanced security through:
- Standard SSL port (443) appears less suspicious
- Same certificate validation and encryption
- No additional attack surface

## Compatibility

Works with all Electrum wallets and applications that support custom server configuration with SSL on port 443.

---

*This solution was developed and tested on Ubuntu 24.04 with Fulcrum 1.9.8 and nginx 1.18+.*
