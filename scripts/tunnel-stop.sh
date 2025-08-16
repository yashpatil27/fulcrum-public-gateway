#!/bin/bash

source "$HOME/.config/electrs-pub/config" 2>/dev/null || {
    echo "❌ Configuration not found. Run home-server/setup.sh first."
    exit 1
}

echo "🛑 Stopping Electrs Tunnel"
echo "=========================="

sudo systemctl stop "$SERVICE_NAME"
sleep 2

if ! systemctl is-active --quiet "$SERVICE_NAME"; then
    echo "✅ Tunnel stopped successfully"
else
    echo "❌ Failed to stop tunnel"
    systemctl status "$SERVICE_NAME"
fi
