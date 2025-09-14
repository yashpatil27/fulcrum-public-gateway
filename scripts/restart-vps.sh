#!/bin/bash
# Simple VPS Service Restart Script
# Restarts stunnel4 and nginx in the correct order

echo "🔄 Restarting VPS services..."
echo

# Step 1: Stop services
echo "1. Stopping services..."
ssh -i ~/.ssh/fulcrum_tunnel ubuntu@vm-374.lnvps.cloud "
    sudo systemctl stop stunnel4
    sudo systemctl stop nginx
"

# Step 2: Clean up any stuck processes
echo "2. Cleaning up processes..."
ssh -i ~/.ssh/fulcrum_tunnel ubuntu@vm-374.lnvps.cloud "
    sudo pkill stunnel4 2>/dev/null || true
    sleep 2
"

# Step 3: Check port 443 is free
echo "3. Checking port availability..."
ssh -i ~/.ssh/fulcrum_tunnel ubuntu@vm-374.lnvps.cloud "
    if sudo lsof -i :443 >/dev/null 2>&1; then
        echo '   WARNING: Port 443 still in use, force killing...'
        sudo fuser -k 443/tcp 2>/dev/null || true
        sleep 2
    else
        echo '   Port 443 is free'
    fi
"

# Step 4: Start services in order
echo "4. Starting nginx..."
ssh -i ~/.ssh/fulcrum_tunnel ubuntu@vm-374.lnvps.cloud "
    sudo systemctl start nginx
"

echo "5. Starting stunnel4..."
ssh -i ~/.ssh/fulcrum_tunnel ubuntu@vm-374.lnvps.cloud "
    sudo systemctl start stunnel4
"

# Step 5: Verify services are running
echo "6. Verifying services..."
ssh -i ~/.ssh/fulcrum_tunnel ubuntu@vm-374.lnvps.cloud "
    if sudo systemctl is-active --quiet stunnel4; then
        echo '   ✅ stunnel4: Running'
    else
        echo '   ❌ stunnel4: Failed'
    fi
    
    if sudo systemctl is-active --quiet nginx; then
        echo '   ✅ nginx: Running'
    else
        echo '   ❌ nginx: Failed'
    fi
    
    if sudo lsof -i :443 >/dev/null 2>&1; then
        echo '   ✅ Port 443: Listening'
    else
        echo '   ❌ Port 443: Not listening'
    fi
"

echo
echo "✅ VPS restart complete"
