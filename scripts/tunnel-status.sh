#!/bin/bash

# Check SSH tunnel status
source "$HOME/.config/electrs-pub/config" 2>/dev/null || {
    echo "❌ Configuration not found. Run home-server/setup.sh first."
    exit 1
}

echo "🔍 Electrs Tunnel Status Check"
echo "=============================="

# Check systemd service status
echo "Service Status:"
if systemctl is-active --quiet "$SERVICE_NAME"; then
    echo "✅ Service is running"
else
    echo "❌ Service is not running"
    echo "   Start with: sudo systemctl start $SERVICE_NAME"
fi

# Check if SSH connection is active
echo ""
echo "SSH Connection:"
if pgrep -f "ssh.*$VPS_HOST.*$ELECTRS_PORT:127.0.0.1:$ELECTRS_PORT" >/dev/null; then
    echo "✅ SSH tunnel process is running"
else
    echo "❌ SSH tunnel process not found"
fi

# Check if port is being forwarded
echo ""
echo "Port Check:"
if ss -tlnp | grep -q ":$ELECTRS_PORT.*ssh" 2>/dev/null; then
    echo "✅ Port $ELECTRS_PORT appears to be forwarded"
else
    echo "⚠️  Port $ELECTRS_PORT forwarding status unclear"
fi

# Check electrs local availability
echo ""
echo "Local Electrs:"
if timeout 3 bash -c "</dev/tcp/127.0.0.1/$ELECTRS_PORT" 2>/dev/null; then
    echo "✅ Electrs is reachable locally on port $ELECTRS_PORT"
else
    echo "❌ Electrs is not reachable on port $ELECTRS_PORT"
    echo "   Check if electrs is running: ./scripts/check-electrs.sh"
fi

# Recent log entries
echo ""
echo "Recent Tunnel Logs:"
journalctl -u "$SERVICE_NAME" --no-pager -n 5 --output=short

echo ""
echo "Commands:"
echo "  View live logs: journalctl -u $SERVICE_NAME -f"
echo "  Restart tunnel: ./scripts/tunnel-restart.sh"
echo "  Check electrs:  ./scripts/check-electrs.sh"
