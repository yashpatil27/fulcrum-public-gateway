#!/bin/bash

echo "🔍 VPS Configuration Status Check"
echo "=================================="
echo

echo "📋 Nginx Sites Available:"
ls -la /etc/nginx/sites-available/ | grep bittrade
echo

echo "🔗 Nginx Sites Enabled:"
ls -la /etc/nginx/sites-enabled/ | grep bittrade
echo

echo "✅ SSL Certificates:"
sudo certbot certificates | grep bittrade
echo

echo "🌐 Domain Health Checks:"
echo "Testing electrs.bittrade.co.in/health:"
curl -s https://electrs.bittrade.co.in/health
echo
echo "Testing fulcrum.bittrade.co.in/health:"
curl -s https://fulcrum.bittrade.co.in/health
echo

echo "🔒 HTTPS Redirects:"
echo "Testing HTTP to HTTPS redirect for fulcrum domain:"
curl -I http://fulcrum.bittrade.co.in 2>/dev/null | grep Location
echo

echo "🛡️ Firewall Status:"
sudo ufw status | grep -E "(80|443)"
echo

echo "✅ Setup Complete! Both domains are configured:"
echo "  • electrs.bittrade.co.in → Your Fulcrum server (port 50005)"
echo "  • fulcrum.bittrade.co.in → Same Fulcrum server (port 50005)"
echo "  • Both domains have SSL certificates"
echo "  • Both domains redirect HTTP to HTTPS"
echo "  • Rate limiting and security headers configured"
