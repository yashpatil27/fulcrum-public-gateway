#!/bin/bash

# Fulcrum Public Gateway - VPS Setup Script
set -e

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Source configuration
if [ -f "$PROJECT_ROOT/config.env" ]; then
    source "$PROJECT_ROOT/config.env"
else
    echo "❌ Configuration file not found: $PROJECT_ROOT/config.env"
    echo "Please ensure config.env exists in the project root directory."
    exit 1
fi

echo "☁️  Setting up Fulcrum Public Gateway - VPS Server"
echo "================================================="

# Function to print colored output
print_colored() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Check if running as root or with sudo
if [ "$EUID" -ne 0 ]; then
    print_error "This script must be run as root or with sudo"
    exit 1
fi

print_info "Using configuration:"
print_info "  Domain: $DOMAIN"
print_info "  SSL Email: $SSL_EMAIL"
print_info "  Fulcrum Port: $FULCRUM_PORT"

# Get server IP
SERVER_IP=$(curl -s ipinfo.io/ip || echo "Unable to determine IP")

# Update system packages
print_info "Updating system packages..."
apt update && apt upgrade -y

# Install required packages
print_info "Installing nginx, certbot, and firewall..."
apt install -y nginx certbot python3-certbot-nginx ufw curl

# Configure UFW firewall
print_info "Configuring firewall..."
ufw --force enable
# Allow SSH, HTTP, HTTPS
ufw allow $SSH_PORT/tcp
ufw allow 80/tcp
ufw allow 443/tcp

# Create nginx configuration
print_info "Creating nginx configuration..."
cat > "$NGINX_CONFIG" << NGINXEOF
# Fulcrum Public Gateway Configuration
# HTTP server (redirect to HTTPS)
server {
    listen 80;
    server_name $DOMAIN;
    
    location / {
        return 301 https://\$server_name\$request_uri;
    }
}

# HTTPS server (SSL)
server {
    listen 443 ssl http2;
    server_name $DOMAIN;
    
    ssl_certificate $SSL_CERT_PATH;
    ssl_certificate_key $SSL_KEY_PATH;
    
    # SSL configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 1d;
    ssl_session_tickets off;
    
    # Security headers
    add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload" always;
    add_header X-Content-Type-Options nosniff;
    add_header X-Frame-Options DENY;
    add_header X-XSS-Protection "1; mode=block";
    
    # Rate limiting
    limit_req_zone \$binary_remote_addr zone=fulcrum:10m rate=10r/m;
    limit_req zone=fulcrum burst=20 nodelay;
    
    # Logging
    access_log $NGINX_ACCESS_LOG;
    error_log $NGINX_ERROR_LOG;
    
    # Proxy to local fulcrum (via SSH tunnel)
    location / {
        proxy_pass http://127.0.0.1:$FULCRUM_PORT;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # WebSocket support
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
    
    # Health check endpoint
    location /health {
        access_log off;
        return 200 "OK";
        add_header Content-Type text/plain;
    }
}
NGINXEOF

# Enable the site
print_info "Enabling nginx site..."
ln -sf "$NGINX_CONFIG" "$NGINX_ENABLED"

# Test nginx configuration
print_info "Testing nginx configuration..."
nginx -t

# Restart nginx
print_info "Restarting nginx..."
systemctl restart nginx
systemctl enable nginx

# Obtain SSL certificate
print_info "Obtaining SSL certificate for $DOMAIN..."
certbot --nginx -d $DOMAIN --non-interactive --agree-tos --email $SSL_EMAIL || {
    print_error "SSL certificate setup failed!"
    print_error "Please ensure:"
    print_error "1. Domain $DOMAIN points to this server IP: $SERVER_IP"
    print_error "2. Port 80 and 443 are accessible from the internet"
    exit 1
}

# Set up automatic SSL renewal
print_info "Setting up automatic SSL renewal..."
crontab -l 2>/dev/null | grep -q "certbot renew" || {
    (crontab -l 2>/dev/null; echo "0 12 * * * /usr/bin/certbot renew --quiet") | crontab -
}

# Create log rotation configuration
print_info "Setting up log rotation..."
cat > /etc/logrotate.d/fulcrum-nginx << LOGROTATEEOF
$NGINX_ACCESS_LOG $NGINX_ERROR_LOG {
    daily
    missingok
    rotate 52
    compress
    delaycompress
    notifempty
    sharedscripts
    postrotate
        if [ -f /var/run/nginx.pid ]; then
            kill -USR1 \$(cat /var/run/nginx.pid)
        fi
    endscript
}
LOGROTATEEOF

# Final status check
print_info "Checking final status..."
systemctl status nginx --no-pager -l

print_success "VPS setup completed successfully!"

echo ""
echo "Configuration summary:"
echo "  Domain: $DOMAIN"
echo "  Server IP: $SERVER_IP"
echo "  Nginx config: $NGINX_CONFIG"
echo "  SSL certificate: $([ -f "$SSL_CERT_PATH" ] && echo "✅ Installed" || echo "❌ Not installed")"
echo ""
echo "Next steps:"
echo "1. Ensure the home server tunnel is connected"
echo "2. Test the connection: curl -I https://$DOMAIN"
echo "3. Test electrum connection: electrum --server $DOMAIN:443:s"

