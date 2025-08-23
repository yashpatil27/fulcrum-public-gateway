# Troubleshooting Guide - Fulcrum Public Gateway

## Common Issues and Solutions

### 1. External Connections Not Working

**Symptoms:**
- Local connections work (`telnet localhost 50005` works)
- External wallet connections fail
- No traffic in iptables logs for the port

**Diagnosis:**
```bash
# Check if port is listening
sudo ss -tlnp | grep :50002   # or :443

# Check firewall rules
sudo ufw status | grep 50002   # or 443

# Monitor for incoming traffic
sudo tcpdump -i eth0 -n port 50002 -c 5

# Check iptables statistics
sudo iptables -L -n -v | grep 50002
```

**Solutions:**

1. **VPS Provider Port Blocking (Most Common)**
   - **Cause**: Many VPS providers now block cryptocurrency-related ports (like 50002)
   - **Solution**: Migrate to **Port 443 Solution** (see `PORT-443-SOLUTION.md`)
   - **Why it works**: Port 443 is never blocked as it's essential for HTTPS

2. **Firewall Issues**
   ```bash
   # Ensure UFW allows the port
   sudo ufw allow 50002/tcp   # or 443/tcp
   
   # Restart UFW if needed
   sudo ufw reload
   ```

3. **Service Not Binding Properly**
   ```bash
   # Check if stunnel is actually listening
   sudo ss -tlnp | grep stunnel4
   
   # Restart stunnel
   sudo systemctl restart stunnel4
   ```

### 2. SSH Tunnel Connection Issues

**Symptoms:**
- VPS shows no connection on port 50005
- Home server can't establish tunnel

**Diagnosis:**
```bash
# On VPS - check if tunnel port is listening
sudo ss -tlnp | grep :50005

# On Home Server - check tunnel service
./scripts/tunnel-status.sh
sudo systemctl status electrs-tunnel
```

**Solutions:**

1. **Restart SSH Tunnel Service**
   ```bash
   # On home server
   sudo systemctl restart electrs-tunnel
   ```

2. **SSH Key Issues**
   ```bash
   # On home server - check SSH key permissions
   ls -la ~/.ssh/electrs_tunnel
   chmod 600 ~/.ssh/electrs_tunnel
   
   # Test SSH connection manually
   ssh -i ~/.ssh/electrs_tunnel ubuntu@your-vps-ip
   ```

3. **VPS SSH Configuration**
   ```bash
   # On VPS - check SSH daemon config
   sudo systemctl status ssh
   
   # Check if SSH allows reverse tunnels
   grep -i "GatewayPorts\|AllowTcpForwarding" /etc/ssh/sshd_config
   ```

### 3. SSL Certificate Issues

**Symptoms:**
- Certificate verification errors
- "SSL handshake failed" messages

**Diagnosis:**
```bash
# Test certificate
echo | openssl s_client -connect localhost:50002 -servername fulcrum.bittrade.co.in

# Check certificate files
sudo ls -la /etc/letsencrypt/live/fulcrum.bittrade.co.in/

# Check certificate expiry
sudo openssl x509 -in /etc/letsencrypt/live/fulcrum.bittrade.co.in/fullchain.pem -text -noout | grep -A 2 Validity
```

**Solutions:**

1. **Certificate Renewal**
   ```bash
   # Manual renewal
   sudo certbot renew
   
   # Test renewal
   sudo certbot renew --dry-run
   
   # Restart stunnel after renewal
   sudo systemctl restart stunnel4
   ```

2. **Domain Mismatch**
   - Ensure stunnel config uses the correct domain certificate
   - Verify DNS points to correct IP

### 4. DNS Resolution Problems

**Symptoms:**
- Domain doesn't resolve
- Resolves to wrong IP

**Diagnosis:**
```bash
# Check DNS resolution
nslookup fulcrum.bittrade.co.in
dig fulcrum.bittrade.co.in

# Check from external DNS
nslookup fulcrum.bittrade.co.in 8.8.8.8
```

**Solutions:**

1. **DNS Propagation**
   - Wait 24-48 hours for DNS changes to propagate
   - Use different DNS servers for testing

2. **DNS Configuration**
   - Ensure A record points to VPS IP
   - Check TTL settings (use 300 for quick changes)

### 5. Fulcrum Server Issues

**Symptoms:**
- SSH tunnel works but no Fulcrum response
- Connection established but no data

**Diagnosis:**
```bash
# On home server - check Fulcrum status
./scripts/check-fulcrum.sh
sudo systemctl status fulcrum

# Check if Fulcrum is listening locally
sudo ss -tlnp | grep :50005

# Test direct connection to Fulcrum
echo '{"method":"server.version","params":[],"id":1}' | nc localhost 50005
```

**Solutions:**

1. **Restart Fulcrum**
   ```bash
   # On home server
   ./scripts/fulcrum-manage.sh restart
   
   # Check sync status
   ./scripts/fulcrum-manage.sh sync-status
   ```

2. **Check Fulcrum Configuration**
   ```bash
   # Ensure Fulcrum listens on correct port
   grep -E "tcp|ssl" ~/.fulcrum/fulcrum.conf
   
   # Should show: tcp = 0.0.0.0:50005
   ```

### 6. Network Connectivity Issues

**Symptoms:**
- VPS can't reach external services
- DNS resolution fails
- Can't ping external IPs

**Diagnosis:**
```bash
# Test external connectivity
ping -c 2 8.8.8.8
nslookup google.com

# Check network interface
ip addr show eth0
ip route show

# Check DNS configuration
cat /etc/resolv.conf
resolvectl status
```

**Solutions:**

1. **Restart Networking**
   ```bash
   # Restart systemd-resolved
   sudo systemctl restart systemd-resolved
   
   # Restart networking (be careful if remote!)
   sudo systemctl restart systemd-networkd
   ```

2. **VPS Provider Issue**
   - Contact VPS provider support
   - Check provider control panel for network issues
   - Verify VPS hasn't been moved to restricted network

### 7. Service Startup Issues After Reboot

**Symptoms:**
- Services don't start automatically
- Need to manually restart everything

**Diagnosis:**
```bash
# Check which services are enabled
sudo systemctl is-enabled nginx stunnel4 ufw

# Check service dependencies
sudo systemctl list-dependencies stunnel4
```

**Solutions:**

1. **Enable Services**
   ```bash
   sudo systemctl enable nginx
   sudo systemctl enable stunnel4
   sudo systemctl enable ufw
   ```

2. **Service Dependencies**
   ```bash
   # Ensure services start in correct order
   sudo systemctl edit stunnel4
   # Add:
   # [Unit]
   # After=network.target
   ```

## Diagnostic Commands Quick Reference

```bash
# Service Status
sudo systemctl status nginx stunnel4

# Port Listeners
sudo ss -tlnp | grep -E ":(80|443|50002|50005)"

# Test Local Connections
echo '{"method":"server.version"}' | nc localhost 50002
telnet localhost 50005

# Firewall Status
sudo ufw status verbose
sudo iptables -L -n -v

# Network Tests
ping -c 2 your-vps-ip
nslookup your-domain.com

# Certificate Check
echo | openssl s_client -connect localhost:50002 -servername your-domain.com

# Log Monitoring
sudo journalctl -u stunnel4 -f
sudo tail -f /var/log/stunnel4/stunnel.log
```

## Emergency Recovery

If everything breaks:

1. **Restart All Services**
   ```bash
   sudo systemctl restart nginx stunnel4
   # On home server:
   sudo systemctl restart electrs-tunnel
   ```

2. **Reset to Known Good State**
   ```bash
   # Restore from git
   git checkout -- .
   
   # Restart services
   sudo systemctl restart stunnel4 nginx
   ```

3. **Full System Restart**
   - Restart VPS from provider panel
   - Restart home server
   - Verify tunnel reconnects automatically

## Getting Help

When reporting issues, please include:

1. **System Information**
   ```bash
   uname -a
   lsb_release -a
   ```

2. **Service Status**
   ```bash
   sudo systemctl status nginx stunnel4
   ```

3. **Network Configuration**
   ```bash
   ip addr show
   sudo ss -tlnp | grep -E ":(443|50005)"
   ```

4. **Recent Logs**
   ```bash
   sudo journalctl -u stunnel4 --since "1 hour ago" --no-pager
   ```

5. **Error Messages**
   - Copy exact error messages from logs
   - Include client-side errors from wallet applications

---

*For additional support, check the main README.md or create an issue in the GitHub repository.*
