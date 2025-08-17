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

echo "📋 VPS Logs Viewer"
echo "=================="
echo ""

# Show options
echo "Available log files:"
echo "1. Nginx Access Log ($NGINX_ACCESS_LOG)"
echo "2. Nginx Error Log ($NGINX_ERROR_LOG)"
echo "3. System Log (journalctl -n 50)"
echo "4. SSL/Certbot Log"
echo "5. Live tail - Access Log"
echo "6. Live tail - Error Log"
echo ""

read -p "Select option (1-6): " choice

case $choice in
    1)
        print_info "Nginx Access Log (last 50 lines):"
        if [ -f "$NGINX_ACCESS_LOG" ]; then
            tail -n 50 "$NGINX_ACCESS_LOG"
        else
            print_error "Access log not found: $NGINX_ACCESS_LOG"
        fi
        ;;
    2)
        print_info "Nginx Error Log (last 50 lines):"
        if [ -f "$NGINX_ERROR_LOG" ]; then
            tail -n 50 "$NGINX_ERROR_LOG"
        else
            print_error "Error log not found: $NGINX_ERROR_LOG"
        fi
        ;;
    3)
        print_info "System Log (last 50 lines):"
        journalctl -n 50 --no-pager
        ;;
    4)
        print_info "SSL/Certbot Log:"
        if [ -f "/var/log/letsencrypt/letsencrypt.log" ]; then
            tail -n 30 /var/log/letsencrypt/letsencrypt.log
        else
            print_error "Certbot log not found"
        fi
        ;;
    5)
        print_info "Live tail - Access Log (Ctrl+C to exit):"
        if [ -f "$NGINX_ACCESS_LOG" ]; then
            tail -f "$NGINX_ACCESS_LOG"
        else
            print_error "Access log not found: $NGINX_ACCESS_LOG"
        fi
        ;;
    6)
        print_info "Live tail - Error Log (Ctrl+C to exit):"
        if [ -f "$NGINX_ERROR_LOG" ]; then
            tail -f "$NGINX_ERROR_LOG"
        else
            print_error "Error log not found: $NGINX_ERROR_LOG"
        fi
        ;;
    *)
        print_error "Invalid option"
        exit 1
        ;;
esac

