#!/bin/bash

# VPS Logs Viewer
DOMAIN="electrs.bittrade.co.in"

echo "📋 VPS Logs Viewer"
echo "=================="
echo ""

# Show options
echo "Available logs:"
echo "1. Nginx access logs"
echo "2. Nginx error logs"
echo "3. SSL certificate logs"
echo "4. System logs for nginx"
echo "5. Live tail all logs"
echo ""

read -p "Select log to view (1-5): " choice

case $choice in
    1)
        echo "📊 Nginx Access Logs:"
        echo "===================="
        if [ -f "/var/log/nginx/$DOMAIN.access.log" ]; then
            tail -n 50 "/var/log/nginx/$DOMAIN.access.log"
        else
            echo "Access log not found at /var/log/nginx/$DOMAIN.access.log"
            echo "Checking default location..."
            tail -n 50 /var/log/nginx/access.log | grep "$DOMAIN" || echo "No entries found"
        fi
        ;;
    2)
        echo "🚨 Nginx Error Logs:"
        echo "==================="
        if [ -f "/var/log/nginx/$DOMAIN.error.log" ]; then
            tail -n 50 "/var/log/nginx/$DOMAIN.error.log"
        else
            echo "Error log not found at /var/log/nginx/$DOMAIN.error.log"
            echo "Checking default location..."
            tail -n 50 /var/log/nginx/error.log
        fi
        ;;
    3)
        echo "🔐 SSL Certificate Logs:"
        echo "======================="
        journalctl -u certbot --no-pager -n 30
        ;;
    4)
        echo "🔧 System Logs (Nginx):"
        echo "======================"
        journalctl -u nginx --no-pager -n 30
        ;;
    5)
        echo "👀 Live Tail (Ctrl+C to exit):"
        echo "==============================="
        echo "Tailing access logs, error logs, and nginx service..."
        (
            tail -f "/var/log/nginx/$DOMAIN.access.log" 2>/dev/null &
            tail -f "/var/log/nginx/$DOMAIN.error.log" 2>/dev/null &
            journalctl -u nginx -f &
            wait
        )
        ;;
    *)
        echo "Invalid choice"
        ;;
esac
