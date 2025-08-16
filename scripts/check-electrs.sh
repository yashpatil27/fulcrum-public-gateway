#!/bin/bash

echo "⚡ Electrs Status Check"
echo "======================"

# Check if electrs process is running
echo "Process Status:"
if pgrep -f electrs >/dev/null; then
    echo "✅ Electrs process is running"
    echo "   PID(s): $(pgrep -f electrs | tr '\n' ' ')"
else
    echo "❌ Electrs process not found"
fi

# Check if port 50005 is listening
echo ""
echo "Port Status:"
if netstat -tlnp 2>/dev/null | grep -q ":50005"; then
    echo "✅ Port 50005 is listening"
    netstat -tlnp 2>/dev/null | grep ":50005"
else
    echo "❌ Port 50005 is not listening"
fi

# Check electrs config
echo ""
echo "Configuration:"
if [ -f "$HOME/.electrs/config.toml" ]; then
    echo "✅ Config file exists: $HOME/.electrs/config.toml"
    echo ""
    echo "Current config:"
    cat "$HOME/.electrs/config.toml"
else
    echo "❌ Config file not found: $HOME/.electrs/config.toml"
fi

# Check recent logs
echo ""
echo "Recent Electrs Logs:"
if [ -f "$HOME/.electrs/run_electrs.log" ]; then
    echo "Last 10 lines from $HOME/.electrs/run_electrs.log:"
    tail -n 10 "$HOME/.electrs/run_electrs.log"
else
    echo "❌ Log file not found: $HOME/.electrs/run_electrs.log"
fi

# Test connection
echo ""
echo "Connection Test:"
if timeout 3 bash -c "</dev/tcp/127.0.0.1/50005" 2>/dev/null; then
    echo "✅ Can connect to electrs on port 50005"
else
    echo "❌ Cannot connect to electrs on port 50005"
    echo "   This could mean electrs is not running or not listening on this port"
fi

echo ""
echo "If electrs is not running, you may need to start it through parmanode"
echo "or check the parmanode logs for issues."
