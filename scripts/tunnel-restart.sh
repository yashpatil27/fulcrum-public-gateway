#!/bin/bash

source "$HOME/.config/electrs-pub/config" 2>/dev/null || {
    echo "❌ Configuration not found. Run home-server/setup.sh first."
    exit 1
}

echo "🔄 Restarting Electrs Tunnel"
echo "============================"

sudo systemctl restart "$SERVICE_NAME"
sleep 3

echo ""
./scripts/tunnel-status.sh
