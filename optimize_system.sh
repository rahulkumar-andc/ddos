#!/bin/bash

# System Optimization for High-Volume Load Testing
# Optimizes Linux kernel parameters to handle 10,000+ req/s

set -euo pipefail

echo "════════════════════════════════════════════════════════════"
echo "   ⚡ SYSTEM OPTIMIZATION FOR HIGH-VOLUME TESTING"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "This script will optimize your system for 10,000+ req/s:"
echo "  - Increase file descriptor limits"
echo "  - Optimize network stack"
echo "  - Tune TCP parameters"
echo "  - Increase connection tracking"
echo ""
echo "⚠️  Requires root privileges (sudo)"
echo ""
echo "════════════════════════════════════════════════════════════"
echo ""

# Check for root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root (use sudo)"
   exit 1
fi

echo "🔧 Applying system optimizations..."
echo ""

# 1. Increase file descriptor limits
echo "1️⃣  Increasing file descriptor limits..."
cat >> /etc/security/limits.conf << EOF

# Load testing optimizations
* soft nofile 1000000
* hard nofile 1000000
root soft nofile 1000000
root hard nofile 1000000
EOF

ulimit -n 1000000
echo "   ✅ File descriptors: 1,000,000"

# 2. Kernel network parameters
echo "2️⃣  Optimizing kernel network stack..."

# Backup current sysctl
cp /etc/sysctl.conf /etc/sysctl.conf.backup.$(date +%Y%m%d_%H%M%S)

# Apply optimizations
cat >> /etc/sysctl.conf << EOF

# Load Testing Optimizations (added $(date))
# Network performance
net.core.somaxconn = 65535
net.core.netdev_max_backlog = 65535
net.ipv4.tcp_max_syn_backlog = 65535

# Connection tracking
net.netfilter.nf_conntrack_max = 1048576
net.nf_conntrack_max = 1048576

# TCP tuning
net.ipv4.tcp_fin_timeout = 15
net.ipv4.tcp_keepalive_time = 300
net.ipv4.tcp_keepalive_probes = 5
net.ipv4.tcp_keepalive_intvl = 15
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_timestamps = 1

# Port range
net.ipv4.ip_local_port_range = 1024 65535

# Buffer sizes
net.core.rmem_max = 134217728
net.core.wmem_max = 134217728
net.ipv4.tcp_rmem = 4096 87380 67108864
net.ipv4.tcp_wmem = 4096 65536 67108864

# Congestion control
net.ipv4.tcp_congestion_control = htcp
net.core.default_qdisc = fq

# SYN cookies (DDoS protection)
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_tw_buckets = 1440000
EOF

# Apply immediately
sysctl -p
echo "   ✅ Kernel parameters optimized"

# 3. Increase process limits
echo "3️⃣  Increasing process limits..."
cat >> /etc/security/limits.conf << EOF
* soft nproc 1000000
* hard nproc 1000000
EOF
echo "   ✅ Process limits increased"

# 4. Disable transparent hugepages (can cause latency)
echo "4️⃣  Disabling transparent hugepages..."
echo never > /sys/kernel/mm/transparent_hugepage/enabled
echo never > /sys/kernel/mm/transparent_hugepage/defrag
echo "   ✅ Hugepages disabled"

# 5. Load conntrack module with higher limits
echo "5️⃣  Optimizing connection tracking..."
modprobe nf_conntrack
echo "1048576" > /sys/module/nf_conntrack/parameters/hashsize
echo "   ✅ Connection tracking optimized"

echo ""
echo "════════════════════════════════════════════════════════════"
echo "✅ SYSTEM OPTIMIZATION COMPLETE"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "Current limits:"
echo "  File descriptors: $(ulimit -n)"
echo "  Max connections: $(sysctl -n net.core.somaxconn)"
echo "  Port range: $(sysctl -n net.ipv4.ip_local_port_range)"
echo ""
echo "⚠️  IMPORTANT: Log out and log back in for limits to take effect!"
echo "⚠️  Or run: exec su -l \$USER"
echo ""
echo "To verify: ulimit -n"
echo "To restore: sudo cp /etc/sysctl.conf.backup.* /etc/sysctl.conf"
echo ""
echo "🚀 Your system is now ready for 10,000+ req/s testing!"
