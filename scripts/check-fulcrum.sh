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

echo "⚡ Fulcrum Status Check"
echo "======================"

# Check if fulcrum process is running
echo "Process Status:"
if pgrep -f fulcrum > /dev/null; then
    print_success "Fulcrum process is running"
    echo "   PID(s): $(pgrep -f fulcrum | tr '\n' ' ')"
else
    print_error "Fulcrum process is not running"
fi

# Check if port is listening
echo ""
echo "Port Status:"
if netstat -tlnp 2>/dev/null | grep -q ":$FULCRUM_PORT"; then
    print_success "Port $FULCRUM_PORT is listening"
    netstat -tlnp 2>/dev/null | grep ":$FULCRUM_PORT"
else
    print_error "Port $FULCRUM_PORT is not listening"
fi

# Check all Fulcrum ports
echo ""
echo "All Fulcrum Ports:"
FULCRUM_PORTS="50002 50005"
for port in $FULCRUM_PORTS; do
    if netstat -tlnp 2>/dev/null | grep -q ":$port"; then
        print_success "Port $port is listening"
    else
        print_warning "Port $port is not listening"
    fi
done

# Check fulcrum config
echo ""
echo "Configuration:"
FULCRUM_CONFIG_PATH="$HOME/.fulcrum/fulcrum.conf"
if [ -f "$FULCRUM_CONFIG_PATH" ]; then
    print_success "Config file exists: $FULCRUM_CONFIG_PATH"
    echo ""
    echo "Key configuration values:"
    grep -E "tcp|ssl|bitcoind|datadir" "$FULCRUM_CONFIG_PATH" | head -8
else
    print_error "Config file not found: $FULCRUM_CONFIG_PATH"
fi

# Check systemd service
echo ""
echo "Service Status:"
if systemctl is-active --quiet fulcrum; then
    print_success "Fulcrum systemd service is active"
    systemctl status fulcrum --no-pager -l | head -8
else
    print_error "Fulcrum systemd service is not active"
fi

# Check recent logs
echo ""
echo "Recent Fulcrum Logs:"
echo "Last 10 lines from systemd journal:"
journalctl -u fulcrum -n 10 --no-pager | tail -10

# Test connection
echo ""
echo "Connection Test:"
if timeout 3 bash -c "</dev/tcp/127.0.0.1/$FULCRUM_PORT" 2>/dev/null; then
    print_success "Can connect to Fulcrum on port $FULCRUM_PORT"
else
    print_error "Cannot connect to Fulcrum on port $FULCRUM_PORT (may still be syncing)"
fi

# Check sync status (if available)
echo ""
echo "Sync Status:"
if timeout 5 bash -c "</dev/tcp/127.0.0.1/$FULCRUM_PORT" 2>/dev/null; then
    print_info "Fulcrum is accepting connections - likely synced"
else
    print_warning "Fulcrum not accepting connections - likely still syncing"
    echo "   Check: journalctl -u fulcrum -f"
fi
