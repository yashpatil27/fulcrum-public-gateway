#!/bin/bash

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Source configuration
if [ -f "$PROJECT_ROOT/config.env" ]; then
    source "$PROJECT_ROOT/config.env"
else
    echo "❌ Configuration file not found: $PROJECT_ROOT/config.env"
    exit 1
fi

echo "☁️  VPS Status Check"
echo "==================="

print_info "Checking domain: $DOMAIN"

# Check nginx status
echo "Nginx Status:"
if systemctl is-active --quiet nginx; then
    print_success "Nginx is running"
else
    print_error "Nginx is not running"
fi

# Check nginx configuration
echo ""
echo "Nginx Configuration:"
if [ -f "$NGINX_CONFIG" ]; then
    print_success "Nginx config exists: $NGINX_CONFIG"
    if nginx -t 2>/dev/null; then
        print_success "Nginx configuration is valid"
    else
        print_error "Nginx configuration has errors"
    fi
else
    print_error "Nginx config not found: $NGINX_CONFIG"
fi

# Check SSL certificate
echo ""
echo "SSL Certificate:"
if [ -f "$SSL_CERT_PATH" ]; then
    print_success "SSL certificate exists"
    
    # Check certificate expiry
    EXPIRY_DATE=$(openssl x509 -enddate -noout -in "$SSL_CERT_PATH" 2>/dev/null | cut -d= -f2)
    if [ -n "$EXPIRY_DATE" ]; then
        EXPIRY_EPOCH=$(date -d "$EXPIRY_DATE" +%s 2>/dev/null || echo "0")
        CURRENT_EPOCH=$(date +%s)
        DAYS_LEFT=$(( (EXPIRY_EPOCH - CURRENT_EPOCH) / 86400 ))
        
        if [ $DAYS_LEFT -gt 30 ]; then
            print_success "Certificate expires in $DAYS_LEFT days"
        elif [ $DAYS_LEFT -gt 0 ]; then
            print_warning "Certificate expires in $DAYS_LEFT days (consider renewal)"
        else
            print_error "Certificate has expired!"
        fi
    fi
else
    print_error "SSL certificate not found: $SSL_CERT_PATH"
fi

# Check port connectivity (from tunnel)
echo ""
echo "Port Connectivity:"
if timeout 3 bash -c "</dev/tcp/127.0.0.1/$ELECTRS_PORT" 2>/dev/null; then
    print_success "Can connect to port $ELECTRS_PORT (tunnel working)"
else
    print_error "Cannot connect to port $ELECTRS_PORT"
    echo "   This usually means the SSH tunnel is not connected"
fi

# Check domain resolution
echo ""
echo "Domain Resolution:"
DOMAIN_IP=$(dig +short $DOMAIN 2>/dev/null | tail -n1)
SERVER_IP=$(curl -s --connect-timeout 5 ipinfo.io/ip 2>/dev/null || echo "unknown")

if [ -n "$DOMAIN_IP" ]; then
    print_success "Domain resolves to: $DOMAIN_IP"
    if [ "$DOMAIN_IP" = "$SERVER_IP" ]; then
        print_success "Domain points to this server"
    else
        print_warning "Domain points to $DOMAIN_IP, this server is $SERVER_IP"
    fi
else
    print_error "Domain does not resolve"
fi

# Check firewall status
echo ""
echo "Firewall Status:"
if command -v ufw >/dev/null && ufw status | grep -q "Status: active"; then
    print_success "UFW firewall is active"
    echo "Open ports:"
    ufw status | grep ALLOW | head -5
else
    print_warning "UFW firewall not active or not installed"
fi

# Recent nginx logs
echo ""
echo "Recent Activity:"
if [ -f "$NGINX_ACCESS_LOG" ]; then
    echo "Last 5 access log entries:"
    tail -n 5 "$NGINX_ACCESS_LOG" 2>/dev/null || echo "No recent access logs"
fi

