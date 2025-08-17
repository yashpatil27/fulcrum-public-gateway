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

echo "🔐 SSL Certificate Renewal"
echo "=========================="

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    print_error "This script must be run as root or with sudo"
    exit 1
fi

print_info "Renewing SSL certificate for: $DOMAIN"

# Check current certificate status
if [ -f "$SSL_CERT_PATH" ]; then
    print_info "Current certificate status:"
    EXPIRY_DATE=$(openssl x509 -enddate -noout -in "$SSL_CERT_PATH" 2>/dev/null | cut -d= -f2)
    if [ -n "$EXPIRY_DATE" ]; then
        echo "  Expires: $EXPIRY_DATE"
        
        EXPIRY_EPOCH=$(date -d "$EXPIRY_DATE" +%s 2>/dev/null || echo "0")
        CURRENT_EPOCH=$(date +%s)
        DAYS_LEFT=$(( (EXPIRY_EPOCH - CURRENT_EPOCH) / 86400 ))
        
        echo "  Days remaining: $DAYS_LEFT"
    fi
else
    print_warning "Certificate file not found: $SSL_CERT_PATH"
fi

# Attempt to renew certificate
echo ""
print_info "Attempting certificate renewal..."

if certbot renew --nginx --quiet; then
    print_success "Certificate renewal completed successfully"
    
    # Reload nginx to use new certificate
    print_info "Reloading nginx..."
    if systemctl reload nginx; then
        print_success "Nginx reloaded successfully"
    else
        print_error "Failed to reload nginx"
    fi
    
    # Show new certificate status
    echo ""
    print_info "New certificate status:"
    if [ -f "$SSL_CERT_PATH" ]; then
        NEW_EXPIRY_DATE=$(openssl x509 -enddate -noout -in "$SSL_CERT_PATH" 2>/dev/null | cut -d= -f2)
        if [ -n "$NEW_EXPIRY_DATE" ]; then
            echo "  New expiry: $NEW_EXPIRY_DATE"
        fi
    fi
    
else
    print_error "Certificate renewal failed"
    print_error "Check certbot logs: /var/log/letsencrypt/letsencrypt.log"
    exit 1
fi

