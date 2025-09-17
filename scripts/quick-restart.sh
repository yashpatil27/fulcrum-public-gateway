#!/bin/bash
# quick-restart.sh - Restart gateway services (keep Bitcoin Core & Fulcrum running)
# 
# This script restarts only the network/proxy services while keeping
# the core Bitcoin services (bitcoind & fulcrum) running to avoid downtime.
#
# What it restarts:
# - SSH tunnel (home server)
# - Stunnel4 SSL termination (VPS)
# - Nginx web server (VPS) 
# - PHP-FPM health API (VPS)

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔄 Quick Gateway Restart${NC}"
echo -e "${YELLOW}⚠️  Note: Keeping Bitcoin Core & Fulcrum running for zero downtime${NC}"
echo ""

# Function to check if command succeeded
check_status() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ $1${NC}"
    else
        echo -e "${RED}❌ $1 failed${NC}"
        exit 1
    fi
}

# Home Server: Restart SSH tunnel only
echo -e "${BLUE}🏠 Restarting SSH tunnel (home server)...${NC}"
sudo systemctl restart fulcrum-tunnel
check_status "SSH tunnel restarted"

# Give tunnel a moment to establish
sleep 2

# VPS: Restart SSL & web services via SSH
echo -e "${BLUE}☁️  Restarting VPS services...${NC}"
ssh -i /home/oem/.ssh/fulcrum_tunnel -o ConnectTimeout=10 root@31.97.62.114 \
  "systemctl restart stunnel4 nginx php8.3-fpm" 2>/dev/null
check_status "VPS services restarted (stunnel4, nginx, php8.3-fpm)"

# Give services a moment to start
sleep 3

echo ""
echo -e "${BLUE}🧪 Testing connectivity...${NC}"

# Test 1: SSH tunnel connectivity
echo -n "Testing SSH tunnel: "
ssh -i /home/oem/.ssh/fulcrum_tunnel -o ConnectTimeout=5 root@31.97.62.114 "echo 'OK'" 2>/dev/null
check_status "SSH tunnel working"

# Test 2: Health API
echo -n "Testing health API: "
HEALTH_STATUS=$(curl -s --connect-timeout 10 https://fulcron.in/ 2>/dev/null | jq -r '.status' 2>/dev/null || echo "error")
if [ "$HEALTH_STATUS" = "healthy" ]; then
    echo -e "${GREEN}✅ Health API responding (status: healthy)${NC}"
else
    echo -e "${YELLOW}⚠️  Health API response: $HEALTH_STATUS${NC}"
fi

# Test 3: SSL Bitcoin connection
echo -n "Testing Bitcoin SSL connection: "
BITCOIN_TEST=$(echo '{"method":"server.version","params":[],"id":1}' | \
    timeout 10 openssl s_client -connect fulcron.in:50002 -quiet 2>/dev/null | \
    jq -r '.result[0]' 2>/dev/null || echo "error")

if [[ "$BITCOIN_TEST" == *"Fulcrum"* ]]; then
    echo -e "${GREEN}✅ Bitcoin connection working ($BITCOIN_TEST)${NC}"
else
    echo -e "${YELLOW}⚠️  Bitcoin connection test result: $BITCOIN_TEST${NC}"
fi

echo ""
echo -e "${GREEN}🚀 Quick restart complete!${NC}"
echo ""
echo -e "${BLUE}📊 Service Status Summary:${NC}"
echo -e "  • ${GREEN}Bitcoin Core${NC}: Running (not restarted)"
echo -e "  • ${GREEN}Fulcrum${NC}: Running (not restarted)" 
echo -e "  • ${GREEN}SSH Tunnel${NC}: Restarted ✅"
echo -e "  • ${GREEN}Stunnel4 (SSL)${NC}: Restarted ✅"
echo -e "  • ${GREEN}Nginx (Web)${NC}: Restarted ✅"
echo -e "  • ${GREEN}PHP-FMP (API)${NC}: Restarted ✅"
echo ""
echo -e "${BLUE}🔗 Test your Bitcoin wallet with: ${YELLOW}fulcron.in:50002:s${NC}"
echo -e "${BLUE}🌐 Check system health at: ${YELLOW}https://fulcron.in/${NC}"
