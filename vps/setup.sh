#!/bin/bash

# Electrs Public Gateway - VPS Setup Script
set -e

echo "☁️  Setting up Electrs Public Gateway - VPS Server"
echo "================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DOMAIN="electrs.bittrade.co.in"
NGINX_CONFIG="/etc/nginx/sites-available/$DOMAIN"
NGINX_ENABLED="/etc/nginx/sites-enabled/$DOMAIN"
ELECTRS_PORT="50005"

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Check if running as root or with sudo
if [ "$EUID" -ne 0 ]; then
    print_error "This script must be run as root or with sudo"
    exit 1
fi

print_step "1. Updating system packages..."
apt update && apt upgrade -y

print_step "2. Installing required packages..."
apt install -y nginx certbot python3-certbot-nginx ufw curl

print_step "3. Configuring firewall..."
# Allow SSH, HTTP, HTTPS
ufw allow ssh
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable

print_step "4. Creating nginx configuration for $DOMAIN..."

# Create nginx configuration
cat > "$NGINX_CONFIG" << 'NGINX_EOF'
# Electrs Public Gateway Configuration
server {
    listen 80;
    server_name electrs.bittrade.co.in;
    
    # Redirect HTTP to HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name electrs.bittrade.co.in;
    
    # SSL configuration (will be managed by certbot)
    ssl_certificate /etc/letsencrypt/live/electrs.bittrade.co.in/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/electrs.bittrade.co.in/privkey.pem;
    
    # SSL settings
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 1d;
    
    # Security headers
    add_header Strict-Transport-Security "max-age=63072000" always;
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    
    # Rate limiting
    limit_req_zone $binary_remote_addr zone=electrs:10m rate=10r/s;
    limit_req zone=electrs burst=20 nodelay;
    
    # Logging
    access_log /var/log/nginx/electrs.bittrade.co.in.access.log;
    error_log /var/log/nginx/electrs.bittrade.co.in.error.log;
    
    # Proxy configuration for electrs
    location / {
        proxy_pass http://127.0.0.1:50005;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # WebSocket support (if needed)
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
        
        # Buffer settings
        proxy_buffering off;
        proxy_request_buffering off;
    }
    
    # Health check endpoint
    location /health {
        access_log off;
        return 200 "Electrs Gateway OK\n";
        add_header Content-Type text/plain;
    }
}
NGINX_EOF

print_step "5. Enabling nginx site..."
ln -sf "$NGINX_CONFIG" "$NGINX_ENABLED"

print_step "6. Testing nginx configuration..."
nginx -t

print_step "7. Starting nginx..."
systemctl enable nginx
systemctl restart nginx

print_step "8. Checking if domain resolves to this server..."
SERVER_IP=$(curl -s ifconfig.me)
DOMAIN_IP=$(dig +short $DOMAIN | tail -n1)

if [ "$SERVER_IP" = "$DOMAIN_IP" ]; then
    print_status "Domain $DOMAIN correctly points to this server ($SERVER_IP)"
else
    print_warning "Domain $DOMAIN points to $DOMAIN_IP but this server is $SERVER_IP"
    print_warning "Please update your DNS records to point $DOMAIN to $SERVER_IP"
    echo ""
    read -p "Continue with SSL certificate setup anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Skipping SSL certificate setup. Run this script again after updating DNS."
        exit 0
    fi
fi

print_step "9. Obtaining SSL certificate..."
certbot --nginx -d $DOMAIN --non-interactive --agree-tos --email admin@bittrade.co.in || {
    print_warning "SSL certificate setup failed. You can run it manually later:"
    print_warning "certbot --nginx -d $DOMAIN"
}

print_step "10. Setting up SSL certificate auto-renewal..."
systemctl enable certbot.timer
systemctl start certbot.timer

print_step "11. Creating log rotation for nginx..."
cat > /etc/logrotate.d/electrs-nginx << 'LOGROTATE_EOF'
/var/log/nginx/electrs.bittrade.co.in.*.log {
    daily
    missingok
    rotate 14
    compress
    notifempty
    create 644 www-data www-data
    sharedscripts
    prerotate
        if [ -d /etc/logrotate.d/httpd-prerotate ]; then \
            run-parts /etc/logrotate.d/httpd-prerotate; \
        fi \
    endscript
    postrotate
        invoke-rc.d nginx rotate >/dev/null 2>&1
    endscript
}
LOGROTATE_EOF

print_step "12. Final nginx restart..."
systemctl restart nginx

echo ""
print_status "VPS setup complete! ✅"
echo ""
echo "Configuration summary:"
echo "  Domain: $DOMAIN"
echo "  Server IP: $SERVER_IP"
echo "  Nginx config: $NGINX_CONFIG"
echo "  SSL certificate: $([ -f /etc/letsencrypt/live/$DOMAIN/fullchain.pem ] && echo "✅ Installed" || echo "❌ Not installed")"
echo ""
echo "Next steps:"
echo "1. Ensure the home server tunnel is connected"
echo "2. Test the connection: curl -I https://$DOMAIN/health"
echo "3. Test electrs: electrum --server $DOMAIN:443:s"
echo ""
echo "Management commands:"
echo "  Check nginx status: systemctl status nginx"
echo "  View nginx logs:    ./scripts/vps-logs.sh"
echo "  Check SSL status:   ./scripts/vps-status.sh"
echo "  Renew SSL cert:     ./scripts/renew-ssl.sh"
