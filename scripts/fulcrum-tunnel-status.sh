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

# Check if runtime config exists (created by setup.sh)
RUNTIME_CONFIG="$PROJECT_ROOT/.electrs_config"
if [ -f "$RUNTIME_CONFIG" ]; then
    source "$RUNTIME_CONFIG"
fi

print_info "🔍 Fulcrum Tunnel Status Check"
echo "=============================="
print_info "Configuration:"
print_info "  Service: $SERVICE_NAME"
print_info "  Domain: $DOMAIN"
print_info "  Port: $ELECTRS_PORT"

echo ""
echo "Service Status:"
if systemctl is-active --quiet "$SERVICE_NAME"; then
    print_success "Service $SERVICE_NAME is active"
else
    print_error "Service $SERVICE_NAME is not active"
fi

echo ""
echo "Service Details:"
systemctl status "$SERVICE_NAME" --no-pager -l

echo ""
echo "Tunnel Connection Test:"
if pgrep -f "ssh.*$ELECTRS_PORT.*$VPS_HOST" > /dev/null; then
    print_success "SSH tunnel process is running"
    echo "   Process: $(pgrep -f "ssh.*$ELECTRS_PORT.*$VPS_HOST" | head -1)"
else
    print_error "SSH tunnel process is not running"
fi

echo ""
echo "SSH Configuration:"
if [ -f "$SSH_KEY_PATH" ]; then
    print_success "SSH key exists: $SSH_KEY_PATH"
else
    print_error "SSH key missing: $SSH_KEY_PATH"
fi

echo ""
echo "VPS Connection Test:"
if timeout 5 ssh -i "$SSH_KEY_PATH" -o ConnectTimeout=5 -o StrictHostKeyChecking=no "$VPS_USER@$VPS_HOST" "echo 'Connected'" 2>/dev/null | grep -q "Connected"; then
    print_success "Can connect to VPS: $VPS_USER@$VPS_HOST"
else
    print_error "Cannot connect to VPS: $VPS_USER@$VPS_HOST"
fi

echo ""
echo "Fulcrum Status:"
if pgrep -f fulcrum > /dev/null; then
    print_success "Fulcrum is running"
    if timeout 3 bash -c "</dev/tcp/127.0.0.1/$ELECTRS_PORT" 2>/dev/null; then
        print_success "Fulcrum is accepting connections on port $ELECTRS_PORT"
    else
        print_warning "Fulcrum is running but not accepting connections (likely still syncing)"
    fi
else
    print_error "Fulcrum is not running"
fi

echo ""
echo "Port Forward Test:"
if netstat -tlnp 2>/dev/null | grep -q ":$ELECTRS_PORT"; then
    print_success "Local port $ELECTRS_PORT is listening"
    echo "   $(netstat -tlnp 2>/dev/null | grep ":$ELECTRS_PORT")"
else
    print_error "Local port $ELECTRS_PORT is not listening"
fi
