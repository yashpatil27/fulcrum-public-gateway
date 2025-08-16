#!/bin/bash

# Configuration Update Script
echo "🔄 Updating Configurations"
echo "=========================="

# Check if we're on home server or VPS
if [ -f "$HOME/.config/electrs-pub/config" ]; then
    echo "📍 Detected: Home Server"
    
    echo "Updating tunnel service configuration..."
    source "$HOME/.config/electrs-pub/config"
    
    # Restart tunnel service to pick up any changes
    if systemctl is-active --quiet "$SERVICE_NAME"; then
        echo "Restarting tunnel service..."
        sudo systemctl restart "$SERVICE_NAME"
        sleep 3
        ./scripts/tunnel-status.sh
    else
        echo "Tunnel service is not running"
    fi
    
elif command -v nginx >/dev/null 2>&1; then
    echo "📍 Detected: VPS Server"
    
    echo "Testing nginx configuration..."
    if nginx -t; then
        echo "✅ Nginx configuration is valid"
        echo "Reloading nginx..."
        systemctl reload nginx
        ./scripts/vps-status.sh
    else
        echo "❌ Nginx configuration error - not reloading"
        exit 1
    fi
    
else
    echo "❌ Could not determine server type"
    echo "Run this script on either the home server or VPS"
    exit 1
fi

echo ""
echo "✅ Configuration update complete"
