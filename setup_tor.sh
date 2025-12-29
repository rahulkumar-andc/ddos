#!/bin/bash

# Tor Setup Script for Distributed Testing
# Tor provides legitimate IP rotation for testing

set -euo pipefail

echo "════════════════════════════════════════════════════════════"
echo "   🧅 TOR SETUP FOR DISTRIBUTED TESTING"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "Tor provides legitimate IP rotation through its network."
echo "This is useful for testing your infrastructure's ability"
echo "to handle geographically distributed traffic."
echo ""
echo "════════════════════════════════════════════════════════════"
echo ""

# Check if Tor is already installed
if command -v tor &> /dev/null; then
    echo "✅ Tor is already installed"
    TOR_VERSION=$(tor --version | head -n1)
    echo "   Version: $TOR_VERSION"
else
    echo "📦 Installing Tor..."
    sudo apt update
    sudo apt install -y tor
    echo "✅ Tor installed"
fi

# Check if Tor is running
if systemctl is-active --quiet tor 2>/dev/null; then
    echo "✅ Tor service is running"
else
    echo "🚀 Starting Tor service..."
    sudo systemctl start tor
    sudo systemctl enable tor
    echo "✅ Tor service started"
fi

# Verify Tor is working
echo ""
echo "🔍 Verifying Tor connection..."
sleep 3

if curl -s --socks5-hostname 127.0.0.1:9050 https://check.torproject.org/ | grep -q "Congratulations"; then
    echo "✅ Tor is working correctly!"
    
    # Get current Tor IP
    TOR_IP=$(curl -s --socks5-hostname 127.0.0.1:9050 https://api.ipify.org)
    echo "   Your Tor IP: $TOR_IP"
else
    echo "❌ Tor verification failed"
    echo "   Try: sudo systemctl restart tor"
    exit 1
fi

echo ""
echo "════════════════════════════════════════════════════════════"
echo "✅ TOR SETUP COMPLETE"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "You can now use distributed testing with Tor:"
echo "  ./distributed_http_test.sh"
echo ""
echo "Tor will automatically rotate IPs for distributed testing."
echo ""
echo "To check Tor status: sudo systemctl status tor"
echo "To restart Tor: sudo systemctl restart tor"
