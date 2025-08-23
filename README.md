# Bitcoin Fulcrum Server Public Gateway

A complete solution to expose your home Bitcoin Fulcrum server publicly through a VPS, bypassing CGNAT limitations with secure SSL termination.

![Bitcoin](https://img.shields.io/badge/Bitcoin-F7931E?style=for-the-badge&logo=bitcoin&logoColor=white)
![Fulcrum](https://img.shields.io/badge/Fulcrum-0D1117?style=for-the-badge&logo=bitcoin&logoColor=F7931E)
![SSL](https://img.shields.io/badge/SSL-Let's%20Encrypt-green?style=for-the-badge)

## 🎯 Overview

This repository provides a production-ready solution to make your home Bitcoin Fulcrum server accessible from anywhere on the internet with full SSL encryption, even if you're behind CGNAT or don't have a static IP.

### Architecture

```
Internet Clients (Electrum Wallets)
           ↓ SSL Connection (port 50002)
    fulcrum.yourdomain.com (VPS)
           ↓ stunnel (SSL termination)
    localhost:50005 (VPS)
           ↓ SSH Reverse Tunnel
    Home Server Fulcrum:50005
```

## ✨ Features

- **🔒 Full SSL/TLS encryption** using Let's Encrypt certificates
- **🚀 Zero-downtime deployment** with automatic reconnection
- **🔄 Auto-renewing SSL certificates**
- **📊 Comprehensive monitoring scripts**
- **🛡️ Security-first design** with minimal attack surface
- **📱 Compatible with all major Bitcoin wallets**
- **⚡ Optimized for Fulcrum server** (also supports Electrs)
- **🐳 Docker-friendly** with proper firewall integration

## 🏗️ Infrastructure Requirements

### Home Server (This Machine)
- **Bitcoin Core**: Fully synced Bitcoin node
- **Fulcrum Server**: Running and synced
- **Linux System**: Ubuntu/Debian/Mint (tested on Linux Mint)
- **Memory**: 8GB+ RAM recommended for Fulcrum
- **Storage**: SSD recommended, 1TB+ for full blockchain
- **Internet**: Stable connection (speed not critical)

### VPS Requirements
- **OS**: Ubuntu 20.04+ or similar
- **Memory**: 1GB+ RAM (minimal requirements)
- **Storage**: 20GB+ (mainly for logs and certificates)
- **Network**: Static IP address
- **Ports**: 22, 80, 443, 50002 accessible from internet

### Domain Requirements
- **Domain name**: Any domain you control
- **DNS access**: Ability to create A records
- **SSL**: Let's Encrypt compatible (most domains work)

## 🚀 Quick Start

### 1. Prerequisites Check

**Verify Bitcoin Core is running:**
```bash
bitcoin-cli getblockchaininfo
```

**Verify Fulcrum is running and synced:**
```bash
systemctl status fulcrum
journalctl -u fulcrum -f
```

### 2. Configuration

Edit the main configuration file:
```bash
nano config.env
```

**Required changes:**
```bash
# Change these values
DOMAIN="fulcrum.yourdomain.com"      # Your domain
SSL_EMAIL="admin@yourdomain.com"     # Your email for SSL certificates
```

**Current working example:**
```bash
DOMAIN="fulcrum.bittrade.co.in"
SSL_EMAIL="admin@bittrade.co.in"
ELECTRS_PORT="50005"                # Tunnel port
ELECTRS_SSL_PORT="50002"            # Public SSL port
```

### 3. Fulcrum Configuration

Ensure your Fulcrum is configured correctly in `/home/oem/.fulcrum/fulcrum.conf`:

```bash
# Required for this setup
tcp = 0.0.0.0:50005    # Tunnel endpoint

# Optional: Direct SSL (not used in tunnel setup)
ssl = 0.0.0.0:50002    # Local SSL port
```

**Verify Fulcrum is listening on the correct port:**
```bash
sudo netstat -tlnp | grep 50005
# Should show: tcp  0  0  0.0.0.0:50005  0.0.0.0:*  LISTEN  [PID]/Fulcrum
```

### 4. Home Server Setup

Run the automated setup:
```bash
./home-server/setup.sh
```

This script will:
- Generate SSH keys for secure tunnel authentication
- Create systemd service for persistent tunnel
- Configure automatic reconnection on failures
- Set up monitoring and management scripts

### 5. VPS Setup

**On your VPS, clone and setup:**
```bash
git clone https://github.com/yashpatil27/electrs-public-gateway.git
cd electrs-public-gateway
sudo ./vps/setup.sh
```

This will install and configure:
- **nginx**: Web server for health checks and HTTP traffic
- **stunnel**: SSL termination for TCP connections
- **certbot**: Automatic SSL certificate management
- **UFW firewall**: Security hardening

## 📊 Management & Monitoring

### Universal Scripts (Work with both Electrs and Fulcrum)

```bash
# Check tunnel status
./scripts/tunnel-status.sh

# Manage tunnel service
./scripts/tunnel-start.sh       # Start tunnel
./scripts/tunnel-stop.sh        # Stop tunnel  
./scripts/tunnel-restart.sh     # Restart tunnel

# Monitor VPS status
./scripts/vps-status.sh         # Check VPS services
./scripts/vps-logs.sh          # View VPS logs

# SSL management
./scripts/renew-ssl.sh         # Manual SSL renewal
```

### Fulcrum-Specific Scripts

```bash
# Comprehensive Fulcrum status check
./scripts/check-fulcrum.sh

# Advanced Fulcrum management
./scripts/fulcrum-manage.sh status      # Detailed status
./scripts/fulcrum-manage.sh logs        # View logs
./scripts/fulcrum-manage.sh sync-status # Check sync progress
./scripts/fulcrum-manage.sh restart     # Restart Fulcrum

# Tunnel status with Fulcrum awareness
./scripts/fulcrum-tunnel-status.sh
```

### Example Status Check Output

```bash
$ ./scripts/check-fulcrum.sh
⚡ Fulcrum Status Check
======================
Process Status:
✅ Fulcrum process is running
   PID(s): 1036783

Port Status:
✅ Port 50005 is listening (tunnel endpoint)
✅ Port 50002 is listening (direct SSL)

Configuration:
✅ Config file exists: /home/oem/.fulcrum/fulcrum.conf
✅ Fulcrum systemd service is active

Connection Test:
✅ Can connect to Fulcrum on port 50005
✅ Fulcrum is accepting connections - fully synced
```

## 🔧 Technical Details

### Port Mapping

| Service | Home Server | VPS | Public Access |
|---------|-------------|-----|---------------|
| Bitcoin Core | 8332 (RPC) | - | - |
| Fulcrum TCP | 50005 | 50005 (tunnel) | - |
| Fulcrum SSL | 50002 | - | - |
| SSH Tunnel | - | 22 | - |
| Web Health Check | - | 80, 443 | ✓ |
| **Public Fulcrum SSL** | - | **50002** | **✓** |

### Security Architecture

```
🌐 Internet
    ↓ Port 50002 (SSL encrypted)
🏠 VPS (185.18.221.146)
    ├── stunnel (SSL termination)
    ├── nginx (health checks)
    ├── UFW firewall
    └── SSH tunnel endpoint
        ↓ Encrypted SSH tunnel
🏠 Home Server
    ├── SSH client (persistent connection)
    ├── Fulcrum (port 50005)
    ├── Bitcoin Core (port 8332)
    └── Local firewall (UFW)
```

### SSL Certificate Chain

```
Let's Encrypt Root CA
    ↓
Let's Encrypt Intermediate CA  
    ↓
fulcrum.yourdomain.com
    ├── Used by stunnel (port 50002)
    ├── Used by nginx (ports 80, 443)
    └── Auto-renewed via certbot
```

## 🧪 Testing & Validation

### 1. Local Connectivity Tests

```bash
# Test local Fulcrum connection
telnet localhost 50005

# Test Fulcrum JSON-RPC
echo '{"jsonrpc": "2.0", "method": "server.version", "params": ["TestClient", "1.4"], "id": 0}' | nc localhost 50005

# Check tunnel connection
./scripts/tunnel-status.sh
```

### 2. VPS Connectivity Tests

```bash
# Test public SSL endpoint
timeout 10 openssl s_client -connect fulcrum.yourdomain.com:50002 -servername fulcrum.yourdomain.com

# Test web health check  
curl https://fulcrum.yourdomain.com/health

# Test Fulcrum protocol over SSL
echo '{"jsonrpc": "2.0", "method": "server.version", "params": ["TestClient", "1.4"], "id": 0}' | openssl s_client -connect fulcrum.yourdomain.com:50002 -quiet 2>/dev/null
```

### 3. Wallet Connection Tests

**Electrum Desktop:**
```bash
# Connect using your domain
electrum --server fulcrum.yourdomain.com:50002:s
```

**Electrum Command Line:**
```bash
# Start daemon with your server
electrum -s fulcrum.yourdomain.com:50002:s daemon start

# Get server info
electrum -s fulcrum.yourdomain.com:50002:s getinfo
```

**Other Wallets:**
- **Server**: `fulcrum.yourdomain.com`
- **Port**: `50002`  
- **Protocol**: `SSL/TLS`

## 🛠️ Troubleshooting

### Common Issues

#### 1. Tunnel Connection Fails
```bash
# Check tunnel status
./scripts/tunnel-status.sh

# View tunnel logs
journalctl -u electrs-tunnel -f

# Restart tunnel
./scripts/tunnel-restart.sh
```

#### 2. SSL Certificate Issues
```bash
# Check certificate status
./scripts/vps-status.sh

# Manual certificate renewal
sudo ./scripts/renew-ssl.sh

# View certificate details
openssl x509 -in /etc/letsencrypt/live/fulcrum.yourdomain.com/fullchain.pem -text -noout
```

#### 3. Fulcrum Connection Issues
```bash
# Check if Fulcrum is still syncing
./scripts/fulcrum-manage.sh sync-status

# View Fulcrum logs
./scripts/fulcrum-manage.sh logs

# Restart Fulcrum
sudo systemctl restart fulcrum
```

#### 4. VPS Service Issues
```bash
# Check all VPS services
./scripts/vps-status.sh

# Check individual services
sudo systemctl status nginx
sudo systemctl status stunnel4

# View service logs
./scripts/vps-logs.sh
```

### Advanced Diagnostics

#### Network Connectivity
```bash
# Test DNS resolution
nslookup fulcrum.yourdomain.com

# Test basic connectivity
nc -zv fulcrum.yourdomain.com 50002

# Trace network path
traceroute fulcrum.yourdomain.com
```

#### SSL/TLS Diagnostics
```bash
# Test SSL handshake
openssl s_client -connect fulcrum.yourdomain.com:50002 -servername fulcrum.yourdomain.com

# Check certificate chain
openssl s_client -connect fulcrum.yourdomain.com:50002 -showcerts

# Verify certificate matches domain
openssl x509 -in <(openssl s_client -connect fulcrum.yourdomain.com:50002 2>/dev/null) -noout -text | grep -A1 "Subject Alternative Name"
```

### Log Locations

| Service | Log Location |
|---------|-------------|
| SSH Tunnel | `journalctl -u electrs-tunnel -f` |
| Fulcrum | `journalctl -u fulcrum -f` |
| Bitcoin Core | `~/.bitcoin/debug.log` |
| VPS Nginx | `/var/log/nginx/fulcrum.yourdomain.com.*.log` |
| VPS stunnel | `/var/log/stunnel4/stunnel.log` |
| SSL Certificates | `/var/log/letsencrypt/letsencrypt.log` |

## 🔒 Security Considerations

### Network Security
- **Minimal attack surface**: Only necessary ports exposed
- **SSH key authentication**: No password authentication
- **SSL/TLS encryption**: All external traffic encrypted
- **Rate limiting**: Protection against DDoS attacks
- **Firewall rules**: UFW configured on both home and VPS

### Operational Security
- **Automated SSL renewal**: Certificates auto-renew before expiry
- **Service monitoring**: Systemd handles service failures
- **SSH tunnel persistence**: Auto-reconnection on network issues
- **Log rotation**: Prevents disk space issues
- **Regular security updates**: Keep all components updated

### Best Practices
1. **Regular monitoring**: Check services weekly with provided scripts
2. **Backup configuration**: Keep copies of config files
3. **Update schedule**: Apply security updates monthly
4. **Certificate monitoring**: Monitor SSL certificate expiry
5. **Connection monitoring**: Watch for unusual connection patterns

## 📊 Performance & Scalability

### Resource Usage

**Home Server:**
- **CPU**: 1-5% additional load for SSH tunnel
- **Memory**: ~2MB for SSH tunnel process
- **Network**: Minimal overhead for tunnel encryption
- **Storage**: Logs typically <100MB/month

**VPS:**
- **CPU**: 1-10% under normal load
- **Memory**: ~50MB for nginx + stunnel + SSH
- **Network**: Depends on wallet usage
- **Storage**: Logs typically <500MB/month

### Performance Characteristics
- **Latency**: +10-50ms due to VPS hop
- **Throughput**: Limited by home internet upload speed
- **Concurrent connections**: Fulcrum handles 100+ concurrent users
- **Reliability**: 99.9%+ uptime with proper setup

### Scaling Considerations
- **Multiple domains**: Easy to add additional subdomains
- **Load balancing**: Can distribute across multiple VPS instances
- **Geographic distribution**: Deploy VPS in multiple regions
- **Monitoring integration**: Compatible with Prometheus/Grafana

## 🔄 Backup & Disaster Recovery

### Configuration Backup
```bash
# Backup all configuration files
tar -czf fulcrum-gateway-backup-$(date +%Y%m%d).tar.gz \
    config.env \
    .electrs_config \
    ~/.ssh/electrs_tunnel* \
    /etc/systemd/system/electrs-tunnel.service
```

### Recovery Procedures

**Home Server Recovery:**
1. Restore configuration files from backup
2. Run `./home-server/setup.sh` to recreate services
3. Verify tunnel connectivity

**VPS Recovery:**
1. Deploy new VPS instance
2. Clone repository and restore configuration
3. Run `sudo ./vps/setup.sh`
4. SSL certificates will auto-renew from Let's Encrypt

**DNS Recovery:**
1. Update DNS records to point to new VPS IP
2. Wait for DNS propagation (up to 48 hours)
3. SSL certificates will automatically adjust

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

### Development Setup
```bash
git clone https://github.com/yashpatil27/electrs-public-gateway.git
cd electrs-public-gateway

# Create feature branch
git checkout -b feature/your-feature-name

# Make changes and test thoroughly
./scripts/validate-config.sh

# Submit pull request
```

### Reporting Issues
- **Security issues**: Please email directly (don't use public issues)
- **Bug reports**: Use GitHub issues with detailed logs
- **Feature requests**: Use GitHub discussions

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Fulcrum Team**: For creating an excellent Electrum server implementation
- **Let's Encrypt**: For free SSL certificates
- **Bitcoin Core**: For the reference Bitcoin implementation
- **Electrum Wallet**: For the excellent Bitcoin wallet software

## 📞 Support

- **Documentation**: See this README and inline script help
- **GitHub Issues**: For bugs and feature requests
- **GitHub Discussions**: For questions and community support
- **Email**: [Your support email] for private inquiries

---

**⚡ Made with ❤️ for the Bitcoin community**

*This project enables anyone to run their own Bitcoin infrastructure and contribute to the decentralization of the Bitcoin network.*
