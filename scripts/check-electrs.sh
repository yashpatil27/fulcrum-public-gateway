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

echo "⚡ Electrs Status Check"
echo "======================"

# Check if electrs process is running
echo "Process Status:"
if pgrep -f electrs > /dev/null; then
    print_success "Electrs process is running"
    echo "   PID(s): $(pgrep -f electrs | tr '\n' ' ')"
else
    print_error "Electrs process is not running"
fi

# Check if port is listening
echo ""
echo "Port Status:"
if netstat -tlnp 2>/dev/null | grep -q ":$ELECTRS_PORT"; then
    print_success "Port $ELECTRS_PORT is listening"
    netstat -tlnp 2>/dev/null | grep ":$ELECTRS_PORT"
else
    print_error "Port $ELECTRS_PORT is not listening"
fi

# Check electrs config
echo ""
echo "Configuration:"
if [ -f "$ELECTRS_CONFIG_PATH" ]; then
    print_success "Config file exists: $ELECTRS_CONFIG_PATH"
    echo ""
    echo "Key configuration values:"
    grep -E "electrum_rpc_addr|network|db_dir" "$ELECTRS_CONFIG_PATH" | head -5
else
    print_error "Config file not found: $ELECTRS_CONFIG_PATH"
fi

# Check recent logs
echo ""
echo "Recent Electrs Logs:"
if [ -f "$ELECTRS_LOG_PATH" ]; then
    echo "Last 10 lines from $ELECTRS_LOG_PATH:"
    tail -n 10 "$ELECTRS_LOG_PATH"
else
    print_warning "Log file not found: $ELECTRS_LOG_PATH"
fi

# Test connection
echo ""
echo "Connection Test:"
if timeout 3 bash -c "</dev/tcp/127.0.0.1/$ELECTRS_PORT" 2>/dev/null; then
    print_success "Can connect to electrs on port $ELECTRS_PORT"
else
    print_error "Cannot connect to electrs on port $ELECTRS_PORT"
fi

