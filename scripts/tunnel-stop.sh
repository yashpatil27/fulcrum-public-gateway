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

echo "🛑 Stopping Fulcrum Tunnel"
echo "========================="

print_info "Stopping service: $SERVICE_NAME"

# Stop the service
if sudo systemctl stop $SERVICE_NAME; then
    print_success "Service stopped successfully"
else
    print_error "Failed to stop service"
    exit 1
fi

