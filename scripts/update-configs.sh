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

echo "🔄 Updating Configurations"
echo "========================="

# Check if we're on home server or VPS
if [ -f "/etc/systemd/system/$SERVICE_NAME.service" ]; then
    print_info "Detected: Home Server"
    
    # Update git repository
    print_info "Pulling latest changes..."
    cd "$PROJECT_ROOT"
    if git pull; then
        print_success "Repository updated successfully"
    else
        print_warning "Git pull failed or no changes available"
    fi
    
    # Restart tunnel service if it's running
    if systemctl is-active --quiet $SERVICE_NAME; then
        print_info "Restarting tunnel service..."
        sudo systemctl restart $SERVICE_NAME
        
        if systemctl is-active --quiet $SERVICE_NAME; then
            print_success "Service restarted successfully"
        else
            print_error "Service restart failed"
        fi
    fi
    
elif [ -f "$NGINX_CONFIG" ]; then
    print_info "Detected: VPS Server"
    
    # Update git repository
    print_info "Pulling latest changes..."
    cd "$PROJECT_ROOT"
    if git pull; then
        print_success "Repository updated successfully"
    else
        print_warning "Git pull failed or no changes available"
    fi
    
    # Test nginx configuration
    print_info "Testing nginx configuration..."
    if nginx -t; then
        print_success "Nginx configuration is valid"
        
        # Reload nginx
        print_info "Reloading nginx..."
        if systemctl reload nginx; then
            print_success "Nginx reloaded successfully"
        else
            print_error "Nginx reload failed"
        fi
    else
        print_error "Nginx configuration test failed"
        print_error "Please check your configuration"
    fi
    
else
    print_info "Server type not detected"
    print_info "Pulling latest changes..."
    cd "$PROJECT_ROOT"
    git pull
fi

print_success "Configuration update completed"

