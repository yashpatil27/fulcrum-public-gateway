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

show_usage() {
    echo "Usage: $0 {start|stop|restart|status|logs|sync-status}"
    echo ""
    echo "Commands:"
    echo "  start       - Start Fulcrum service"
    echo "  stop        - Stop Fulcrum service" 
    echo "  restart     - Restart Fulcrum service"
    echo "  status      - Show detailed Fulcrum status"
    echo "  logs        - Show recent Fulcrum logs"
    echo "  sync-status - Check if Fulcrum is still syncing"
}

case "$1" in
    start)
        print_info "Starting Fulcrum service..."
        sudo systemctl start fulcrum
        sleep 3
        if systemctl is-active --quiet fulcrum; then
            print_success "Fulcrum service started"
        else
            print_error "Failed to start Fulcrum service"
            exit 1
        fi
        ;;
    
    stop)
        print_info "Stopping Fulcrum service..."
        sudo systemctl stop fulcrum
        sleep 2
        if ! systemctl is-active --quiet fulcrum; then
            print_success "Fulcrum service stopped"
        else
            print_error "Failed to stop Fulcrum service"
            exit 1
        fi
        ;;
    
    restart)
        print_info "Restarting Fulcrum service..."
        sudo systemctl restart fulcrum
        sleep 5
        if systemctl is-active --quiet fulcrum; then
            print_success "Fulcrum service restarted"
        else
            print_error "Failed to restart Fulcrum service"
            exit 1
        fi
        ;;
    
    status)
        echo "🔍 Comprehensive Fulcrum Status"
        echo "==============================="
        
        # Service status
        if systemctl is-active --quiet fulcrum; then
            print_success "Fulcrum service is running"
        else
            print_error "Fulcrum service is not running"
        fi
        
        # Process status
        if pgrep -f fulcrum > /dev/null; then
            print_success "Fulcrum process is active"
            echo "   PID: $(pgrep -f fulcrum)"
        else
            print_error "Fulcrum process is not running"
        fi
        
        # Port status
        echo ""
        echo "Port Status:"
        for port in 50002 50005; do
            if netstat -tlnp 2>/dev/null | grep -q ":$port"; then
                print_success "Port $port is listening"
            else
                print_warning "Port $port is not listening"
            fi
        done
        
        # Connection test
        echo ""
        echo "Connection Test:"
        if timeout 3 bash -c "</dev/tcp/127.0.0.1/$ELECTRS_PORT" 2>/dev/null; then
            print_success "Can connect to Fulcrum on port $ELECTRS_PORT"
        else
            print_warning "Cannot connect to port $ELECTRS_PORT (may still be syncing)"
        fi
        ;;
    
    logs)
        print_info "Recent Fulcrum logs (last 20 lines):"
        echo "====================================="
        journalctl -u fulcrum -n 20 --no-pager
        echo ""
        print_info "To follow logs in real-time: journalctl -u fulcrum -f"
        ;;
    
    sync-status)
        print_info "Checking Fulcrum sync status..."
        echo ""
        
        if ! pgrep -f fulcrum > /dev/null; then
            print_error "Fulcrum is not running"
            exit 1
        fi
        
        if timeout 3 bash -c "</dev/tcp/127.0.0.1/$ELECTRS_PORT" 2>/dev/null; then
            print_success "Fulcrum is accepting connections - likely synced!"
        else
            print_warning "Fulcrum is not accepting connections - still syncing"
            echo ""
            print_info "Recent sync-related logs:"
            journalctl -u fulcrum -n 10 --no-pager | grep -i -E "(sync|block|progress|height)" || echo "No recent sync logs found"
        fi
        ;;
    
    *)
        show_usage
        exit 1
        ;;
esac
