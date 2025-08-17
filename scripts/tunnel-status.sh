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

echo "🔍 Electrs Tunnel Status Check"
echo "=============================="

print_info "Configuration:"
print_info "  Service: $SERVICE_NAME"
print_info "  Domain: $DOMAIN"
print_info "  Port: $ELECTRS_PORT"

# Check systemd service status
echo ""
echo "Service Status:"
if systemctl is-active --quiet $SERVICE_NAME; then
    print_success "Service $SERVICE_NAME is active"
    
    # Get service details
    echo ""
    echo "Service Details:"
    systemctl status $SERVICE_NAME --no-pager -l | head -15
    
    # Check if tunnel is actually working
    echo ""
    echo "Tunnel Connection Test:"
    if pgrep -f "ssh.*$ELECTRS_PORT.*$VPS_HOST" > /dev/null; then
        print_success "SSH tunnel process is running"
        echo "   Process: $(pgrep -f "ssh.*$ELECTRS_PORT.*$VPS_HOST" | head -1)"
    else
        print_warning "SSH tunnel process not found"
    fi
    
else
    print_error "Service $SERVICE_NAME is not active"
    echo ""
    echo "Recent logs:"
    journalctl -u $SERVICE_NAME --no-pager -l -n 10
fi

# Check SSH key
echo ""
echo "SSH Configuration:"
if [ -f "$SSH_KEY_PATH" ]; then
    print_success "SSH key exists: $SSH_KEY_PATH"
else
    print_error "SSH key not found: $SSH_KEY_PATH"
fi

# Test VPS connection if configured
if [ -n "$VPS_HOST" ] && [ -n "$VPS_USER" ]; then
    echo ""
    echo "VPS Connection Test:"
    if ssh -i "$SSH_KEY_PATH" -o BatchMode=yes -o ConnectTimeout=5 "${VPS_USER}@${VPS_HOST}" exit 2>/dev/null; then
        print_success "Can connect to VPS: ${VPS_USER}@${VPS_HOST}"
    else
        print_error "Cannot connect to VPS: ${VPS_USER}@${VPS_HOST}"
    fi
fi

