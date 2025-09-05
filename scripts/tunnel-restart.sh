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

echo "🔄 Restarting Fulcrum Tunnel"
echo "============================="

print_info "Restarting service: $SERVICE_NAME"

# Restart the service
if sudo systemctl restart $SERVICE_NAME; then
    print_success "Service restarted successfully"
    
    # Wait a moment and check status
    sleep 2
    if systemctl is-active --quiet $SERVICE_NAME; then
        print_success "Service is running"
    else
        print_error "Service failed to restart properly"
        echo "Check logs with: journalctl -u $SERVICE_NAME -f"
    fi
else
    print_error "Failed to restart service"
    exit 1
fi

