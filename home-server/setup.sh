#!/bin/bash

# Electrs Public Gateway - Home Server Setup Script
set -e

echo "🏠 Setting up Electrs Public Gateway - Home Server"
echo "=================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
SSH_KEY_PATH="$HOME/.ssh/electrs_tunnel"
SERVICE_NAME="electrs-tunnel"
ELECTRS_PORT="50005"

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if electrs is configured
print_status "Checking electrs configuration..."
if [ ! -f "$HOME/.electrs/config.toml" ]; then
    print_error "Electrs configuration not found at $HOME/.electrs/config.toml"
    print_error "Please ensure electrs is properly installed and configured first."
    exit 1
fi

# Verify electrs is configured for port 50005
if ! grep -q "electrum_rpc_addr.*50005" "$HOME/.electrs/config.toml"; then
    print_warning "Electrs doesn't appear to be configured for port 50005"
    print_warning "Current electrs config:"
    cat "$HOME/.electrs/config.toml"
    echo ""
    read -p "Do you want to continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Get VPS connection details
echo ""
print_status "VPS Connection Setup"
echo "Please provide your VPS connection details:"
read -p "VPS IP address or hostname: " VPS_HOST
read -p "VPS username: " VPS_USER
read -p "VPS SSH port (default 22): " VPS_PORT
VPS_PORT=${VPS_PORT:-22}

echo ""
print_status "Creating SSH key for tunnel..."

# Generate SSH key if it doesn't exist
if [ ! -f "$SSH_KEY_PATH" ]; then
    ssh-keygen -t ed25519 -f "$SSH_KEY_PATH" -N "" -C "electrs-tunnel@$(hostname)"
    print_status "SSH key generated: $SSH_KEY_PATH"
else
    print_warning "SSH key already exists: $SSH_KEY_PATH"
fi

# Copy SSH key to VPS
print_status "Copying SSH key to VPS..."
echo "You will be prompted for your VPS password:"
ssh-copy-id -i "$SSH_KEY_PATH.pub" -p "$VPS_PORT" "$VPS_USER@$VPS_HOST" || {
    print_error "Failed to copy SSH key to VPS"
    print_error "Please manually copy the key:"
    echo "ssh-copy-id -i $SSH_KEY_PATH.pub -p $VPS_PORT $VPS_USER@$VPS_HOST"
    exit 1
}

print_status "Testing SSH connection..."
if ssh -i "$SSH_KEY_PATH" -p "$VPS_PORT" -o ConnectTimeout=10 -o BatchMode=yes "$VPS_USER@$VPS_HOST" "echo 'SSH connection successful'" >/dev/null 2>&1; then
    print_status "SSH key authentication successful"
else
    print_error "SSH key authentication failed"
    exit 1
fi

# Create systemd service file
print_status "Creating systemd service..."
sudo tee "/etc/systemd/system/$SERVICE_NAME.service" > /dev/null << SYSTEMD_EOF
[Unit]
Description=Electrs SSH Tunnel to VPS
After=network.target
Wants=network.target

[Service]
Type=simple
User=$USER
ExecStart=/usr/bin/ssh -i $SSH_KEY_PATH -p $VPS_PORT -R $ELECTRS_PORT:127.0.0.1:$ELECTRS_PORT -o ServerAliveInterval=60 -o ServerAliveCountMax=3 -o ExitOnForwardFailure=yes -o StrictHostKeyChecking=no $VPS_USER@$VPS_HOST -N
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
SYSTEMD_EOF

# Reload systemd and enable service
print_status "Enabling and starting tunnel service..."
sudo systemctl daemon-reload
sudo systemctl enable "$SERVICE_NAME"
sudo systemctl start "$SERVICE_NAME"

# Check service status
sleep 2
if sudo systemctl is-active --quiet "$SERVICE_NAME"; then
    print_status "Tunnel service started successfully"
else
    print_error "Tunnel service failed to start"
    print_error "Check logs with: journalctl -u $SERVICE_NAME -f"
    exit 1
fi

# Create configuration file for scripts
mkdir -p "$HOME/.config/electrs-pub"
cat > "$HOME/.config/electrs-pub/config" << CONFIG_EOF
VPS_HOST="$VPS_HOST"
VPS_USER="$VPS_USER"
VPS_PORT="$VPS_PORT"
SSH_KEY_PATH="$SSH_KEY_PATH"
SERVICE_NAME="$SERVICE_NAME"
ELECTRS_PORT="$ELECTRS_PORT"
CONFIG_EOF

print_status "Configuration saved to $HOME/.config/electrs-pub/config"

echo ""
print_status "Home server setup complete! ✅"
echo ""
echo "Next steps:"
echo "1. Set up the VPS using the vps/setup.sh script"
echo "2. Configure DNS to point electrs.bittrade.co.in to your VPS IP"
echo "3. Test the connection"
echo ""
echo "Management commands:"
echo "  Check tunnel status: ./scripts/tunnel-status.sh"
echo "  View tunnel logs:    journalctl -u $SERVICE_NAME -f"
echo "  Restart tunnel:      ./scripts/tunnel-restart.sh"
