#!/bin/bash

source "$HOME/.config/electrs-pub/config" 2>/dev/null || {
    echo "❌ Configuration not found. Run home-server/setup.sh first."
    exit 1
}

echo "🚀 Starting Electrs Tunnel"
echo "=========================="

sudo systemctl start "$SERVICE_NAME"
sleep 2

if systemctl is-active --quiet "$SERVICE_NAME"; then
    echo "✅ Tunnel started successfully"
    echo ""
    ./scripts/tunnel-status.sh
else
    echo "❌ Failed to start tunnel"
    echo ""
    echo "Check logs:"
    journalctl -u "$SERVICE_NAME" --no-pager -n 10
fi
