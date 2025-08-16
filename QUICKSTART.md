# 🚀 Quick Start Guide

## Prerequisites
- ✅ Home server with electrs running (this machine)
- ✅ VPS with root access 
- ✅ Domain `bittrade.co.in` pointing to VPS IP

## Step 1: Home Server Setup (THIS MACHINE)

```bash
cd /home/oem/electrs_pub
./home-server/setup.sh
```

This will:
- Generate SSH keys
- Set up persistent tunnel service
- Configure automatic reconnection

## Step 2: VPS Setup

1. **Clone this repo on your VPS:**
```bash
git clone <your-repo-url>
cd electrs_pub
```

2. **Run VPS setup:**
```bash
sudo ./vps/setup.sh
```

This will:
- Install nginx and SSL certificates
- Configure reverse proxy for electrs.bittrade.co.in
- Set up firewall rules

## Step 3: Test Everything

**On home server:**
```bash
./scripts/tunnel-status.sh
./scripts/check-electrs.sh
```

**On VPS:**
```bash
./scripts/vps-status.sh
curl -I https://electrs.bittrade.co.in/health
```

**Test with Electrum:**
```bash
electrum --server electrs.bittrade.co.in:443:s
```

## 🔧 Common Commands

### Home Server
```bash
./scripts/tunnel-status.sh      # Check status
./scripts/tunnel-restart.sh     # Restart tunnel
journalctl -u electrs-tunnel -f # View logs
```

### VPS
```bash
./scripts/vps-status.sh         # Check status  
./scripts/vps-logs.sh           # View logs
./scripts/renew-ssl.sh          # Renew SSL
```

## 🆘 Troubleshooting

1. **Tunnel not connecting**: Check SSH keys and VPS access
2. **SSL issues**: Ensure domain points to VPS IP
3. **Electrs not accessible**: Verify electrs is running on port 50005

See README.md for detailed documentation.
