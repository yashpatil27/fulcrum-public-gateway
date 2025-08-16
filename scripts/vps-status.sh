#!/bin/bash

# VPS Status Check Script
echo "☁️  VPS Status Check"
echo "==================="

DOMAIN="electrs.bittrade.co.in"

# Check nginx status
echo "Nginx Status:"
if systemctl is-active --quiet nginx; then
    echo "✅ Nginx is running"
else
    echo "❌ Nginx is not running"
    echo "   Start with: sudo systemctl start nginx"
fi

# Check if site is enabled
echo ""
echo "Site Configuration:"
if [ -f "/etc/nginx/sites-enabled/$DOMAIN" ]; then
    echo "✅ Site is enabled"
else
    echo "❌ Site is not enabled"
    echo "   Enable with: sudo ln -s /etc/nginx/sites-available/$DOMAIN /etc/nginx/sites-enabled/"
fi

# Check SSL certificate
echo ""
echo "SSL Certificate:"
if [ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]; then
    echo "✅ SSL certificate exists"
    
    # Check expiry
    EXPIRY=$(openssl x509 -in "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" -noout -enddate | cut -d= -f2)
    EXPIRY_EPOCH=$(date -d "$EXPIRY" +%s)
    CURRENT_EPOCH=$(date +%s)
    DAYS_UNTIL_EXPIRY=$(( (EXPIRY_EPOCH - CURRENT_EPOCH) / 86400 ))
    
    if [ $DAYS_UNTIL_EXPIRY -gt 30 ]; then
        echo "✅ Certificate expires in $DAYS_UNTIL_EXPIRY days ($EXPIRY)"
    elif [ $DAYS_UNTIL_EXPIRY -gt 7 ]; then
        echo "⚠️  Certificate expires in $DAYS_UNTIL_EXPIRY days ($EXPIRY)"
    else
        echo "❌ Certificate expires soon: $DAYS_UNTIL_EXPIRY days ($EXPIRY)"
        echo "   Renew with: ./scripts/renew-ssl.sh"
    fi
else
    echo "❌ SSL certificate not found"
    echo "   Install with: sudo certbot --nginx -d $DOMAIN"
fi

# Check port 50005 connectivity (from tunnel)
echo ""
echo "Tunnel Connection:"
if timeout 3 bash -c "</dev/tcp/127.0.0.1/50005" 2>/dev/null; then
    echo "✅ Can connect to port 50005 (tunnel working)"
else
    echo "❌ Cannot connect to port 50005"
    echo "   Check if home server tunnel is connected"
fi

# Check external connectivity
echo ""
echo "External Access:"
if curl -s -I "https://$DOMAIN/health" | head -n1 | grep -q "200 OK"; then
    echo "✅ Domain is accessible externally"
else
    echo "❌ Domain is not accessible or returning errors"
    echo "   Test manually: curl -I https://$DOMAIN/health"
fi

# Check firewall status
echo ""
echo "Firewall Status:"
if command -v ufw >/dev/null && ufw status | grep -q "Status: active"; then
    echo "✅ Firewall is active"
    echo "Open ports:"
    ufw status | grep ALLOW
else
    echo "⚠️  Firewall status unclear or inactive"
fi

# Show recent nginx access logs
echo ""
echo "Recent Access (last 5 entries):"
if [ -f "/var/log/nginx/$DOMAIN.access.log" ]; then
    tail -n 5 "/var/log/nginx/$DOMAIN.access.log"
elif [ -f "/var/log/nginx/access.log" ]; then
    tail -n 5 "/var/log/nginx/access.log" | grep "$DOMAIN"
else
    echo "No access logs found"
fi

echo ""
echo "Commands:"
echo "  View nginx logs: ./scripts/vps-logs.sh"
echo "  Renew SSL cert: ./scripts/renew-ssl.sh"
echo "  Test connection: curl -I https://$DOMAIN/health"
