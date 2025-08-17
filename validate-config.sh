#!/bin/bash

# Configuration Validation Script
echo "🔍 Validating Configuration"
echo "============================"

# Source configuration
if [ -f "config.env" ]; then
    source config.env
    echo "✅ Configuration file found"
else
    echo "❌ Configuration file 'config.env' not found"
    echo "   Please ensure you're in the project root directory"
    exit 1
fi

echo ""
echo "Current Configuration:"
echo "  Domain: $DOMAIN"
echo "  SSL Email: $SSL_EMAIL" 
echo "  Electrs Port: $ELECTRS_PORT"
echo "  Service Name: $SERVICE_NAME"

echo ""
echo "⚠️  Required Changes for New Users:"

# Check if domain is still the default
if [ "$DOMAIN" = "electrs.bittrade.co.in" ]; then
    echo "  ❌ DOMAIN still set to default value"
    echo "     Please change DOMAIN in config.env to your own domain"
else
    echo "  ✅ DOMAIN has been customized"
fi

# Check if email is still the default  
if [ "$SSL_EMAIL" = "admin@bittrade.co.in" ]; then
    echo "  ❌ SSL_EMAIL still set to default value"
    echo "     Please change SSL_EMAIL in config.env to your email"
else
    echo "  ✅ SSL_EMAIL has been customized"
fi

echo ""
echo "📋 Configuration Summary:"
echo "  All scripts will use the values from config.env"
echo "  No hardcoded values need to be changed in scripts"
echo "  Edit config.env to customize your setup"

if [ "$DOMAIN" = "electrs.bittrade.co.in" ] || [ "$SSL_EMAIL" = "admin@bittrade.co.in" ]; then
    echo ""
    echo "🚨 Action Required:"
    echo "   Edit config.env and change the default values before proceeding"
    exit 1
else
    echo ""
    echo "✅ Configuration appears ready for use!"
fi
