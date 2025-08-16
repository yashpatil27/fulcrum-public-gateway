#!/bin/bash

# SSL Certificate Renewal Script
DOMAIN="electrs.bittrade.co.in"

echo "🔐 SSL Certificate Renewal"
echo "=========================="

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "❌ This script must be run as root or with sudo"
    exit 1
fi

echo "Checking current certificate status..."
if [ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]; then
    EXPIRY=$(openssl x509 -in "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" -noout -enddate | cut -d= -f2)
    EXPIRY_EPOCH=$(date -d "$EXPIRY" +%s)
    CURRENT_EPOCH=$(date +%s)
    DAYS_UNTIL_EXPIRY=$(( (EXPIRY_EPOCH - CURRENT_EPOCH) / 86400 ))
    
    echo "Current certificate expires in $DAYS_UNTIL_EXPIRY days ($EXPIRY)"
    
    if [ $DAYS_UNTIL_EXPIRY -gt 30 ]; then
        echo "⚠️  Certificate doesn't need renewal yet (>30 days remaining)"
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 0
        fi
    fi
else
    echo "❌ No certificate found. Will attempt to obtain new certificate."
fi

echo ""
echo "Attempting to renew certificate..."
certbot renew --nginx --force-renewal

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Certificate renewal completed successfully"
    echo "Reloading nginx..."
    systemctl reload nginx
    
    echo ""
    echo "New certificate info:"
    EXPIRY=$(openssl x509 -in "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" -noout -enddate | cut -d= -f2)
    echo "Expires: $EXPIRY"
else
    echo ""
    echo "❌ Certificate renewal failed"
    echo "Check the logs above for details"
    echo ""
    echo "You can also try:"
    echo "  certbot --nginx -d $DOMAIN"
    echo "  certbot certificates"
    exit 1
fi

echo ""
echo "Testing renewed certificate..."
if curl -s -I "https://$DOMAIN/health" | head -n1 | grep -q "200 OK"; then
    echo "✅ HTTPS is working with renewed certificate"
else
    echo "⚠️  HTTPS test failed - check nginx configuration"
fi
