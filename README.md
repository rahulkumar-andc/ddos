# ⚠️ Controlled Load Testing Framework

## IMPORTANT LEGAL & ETHICAL NOTICE

This toolkit is designed for **controlled load testing of YOUR OWN infrastructure only**.

### 🛡️ Safety Features Built-In:
- Rate limiting (max 15K req/s - configurable)
- Automatic timeout (60 seconds default)
- Dry-run mode for testing
- Clear warning prompts
- Configurable safety limits

### ⚠️ WARNING:
- **ONLY use on domains you own** (villen.me confirmed)
- **Check your hosting ToS** - Render.com may prohibit load testing
- **Test during off-peak hours** to avoid impacting real users
- **Monitor your infrastructure** during tests
- **Start small** - gradually increase load

### 🚫 DO NOT:
- Use on domains you don't own
- Remove safety limits
- Run unattended
- Exceed your infrastructure capacity
- Violate your hosting provider's terms

---

## Scripts Included

1. `config.conf` - Central configuration (EDIT THIS FIRST)
2. `http_load_test.sh` - Layer 7 HTTP load testing (Apache Bench)
3. `tcp_load_test.sh` - Layer 4 TCP connection testing (hping3)
4. `slow_request_test.sh` - Slowloris-style testing
5. `port_scan.sh` - Port discovery with masscan
6. `distributed_http_test.sh` - Distributed load testing with IP rotation
7. `high_volume_http.sh` - **NEW:** High-volume testing with wrk (10K+ req/s)
8. `master_test.sh` - Orchestrator script
9. `setup_tor.sh` - Setup Tor for distributed testing
10. `optimize_system.sh` - **NEW:** System optimization for high-volume testing

## Quick Start

### Standard Testing (1K req/s)

```bash
cd /home/villen/Desktop/ddos

# 1. Edit configuration
nano config.conf

# 2. Run dry-run test
./http_load_test.sh --dry-run

# 3. Run actual test (with confirmation)
./http_load_test.sh
```

### Distributed Testing (Different IPs)

```bash
# Setup Tor for IP rotation
./setup_tor.sh

# Run distributed test
./distributed_http_test.sh
```

### High-Volume Testing (10K+ req/s) ⚡

```bash
# 1. Optimize system (REQUIRED - needs sudo)
sudo ./optimize_system.sh

# 2. Logout and login (or run: exec su -l $USER)

# 3. Run high-volume test
./high_volume_http.sh

# Or dry-run first
./high_volume_http.sh --dry-run
```

## Installation Requirements

### Basic Tools
```bash
# Install required tools
sudo apt update
sudo apt install -y hping3 apache2-utils masscan python3 python3-pip git
```

### For Distributed Testing
```bash
# Install Tor
sudo apt install tor
sudo systemctl start tor

# Install Python dependencies
pip3 install requests[socks] PySocks --user
```

### For High-Volume Testing (10K+ req/s)
```bash
# Install wrk
sudo apt install wrk

# Optimize system
sudo ./optimize_system.sh
# Then logout and login
```

### Optional: Slowloris
```bash
git clone https://github.com/gkbrk/slowloris.git
cd slowloris
pip3 install -r requirements.txt
```

## Configuration

Edit `config.conf`:

```bash
# Current configuration (High-Volume Mode)
TARGET="villen.me"
HTTPS_URL="https://villen.me"
MAX_RATE=15000              # 15,000 req/s
MAX_CONNECTIONS=10000       # 10,000 concurrent
MAX_DURATION=60             # 60 seconds
```

### Performance Tiers

**Conservative** (Safe for most servers):
```bash
MAX_RATE=1000
MAX_CONNECTIONS=500
```

**Moderate** (Mid-range):
```bash
MAX_RATE=5000
MAX_CONNECTIONS=2000
```

**High-Volume** (Current - 10K+ req/s):
```bash
MAX_RATE=15000
MAX_CONNECTIONS=10000
```

## 📊 Tool Comparison

| Tool | Script | Max Rate | Best For |
|------|--------|----------|----------|
| **wrk** | high_volume_http.sh | 100K+ req/s | ⭐ Maximum performance |
| **Apache Bench** | http_load_test.sh | 50K req/s | General HTTP testing |
| **hping3** | tcp_load_test.sh | 100K pkt/s | TCP/SYN floods |
| **Python + Tor** | distributed_http_test.sh | 5K req/s | IP rotation |
| **Slowloris** | slow_request_test.sh | N/A | Slow attacks |
| **Masscan** | port_scan.sh | N/A | Port scanning |

## ⚠️ High-Volume Testing Warnings

At 10K+ req/s:

### 🔴 Will Likely Happen:
- Server resource exhaustion
- DDoS protection triggered
- Rate limiting/blocking
- Service degradation
- Hosting provider alerts

### 💰 Cost Implications:
- Bandwidth overage charges
- Increased server costs
- Potential suspension fees

### 🚨 Legal & ToS:
- May violate hosting ToS
- Could trigger abuse reports
- Account termination risk

**Always start with lower rates and increase gradually!**

## 🎯 Usage Examples

### Test 1: Baseline (Safe)
```bash
# Edit config
MAX_RATE=1000
./http_load_test.sh
```

### Test 2: Distributed Attack Simulation
```bash
./setup_tor.sh
./distributed_http_test.sh
```

### Test 3: High-Volume Stress Test
```bash
sudo ./optimize_system.sh
# Logout/login
./high_volume_http.sh
```

### Test 4: Full Test Suite
```bash
./master_test.sh
```

## 📈 Gradual Ramp-Up (Recommended)

```bash
# Phase 1: Baseline
MAX_RATE=1000 ./http_load_test.sh

# Phase 2: Moderate
MAX_RATE=5000 ./http_load_test.sh

# Phase 3: High
MAX_RATE=10000 ./high_volume_http.sh

# Phase 4: Maximum
MAX_RATE=15000 ./high_volume_http.sh
```

**Monitor between each phase!**

## 📝 Documentation

- **PERFORMANCE_GUIDE.md** - Detailed guide for 10K+ req/s testing
- **config.conf** - Configuration reference
- **logs/** - Test logs and results
- **results/** - Test outputs

## Responsible Testing Checklist

- [ ] I own this domain/infrastructure
- [ ] I've checked my hosting provider's ToS
- [ ] I've notified my team about the testing
- [ ] I have monitoring in place
- [ ] I'm testing during off-peak hours
- [ ] I've started with low rate limits
- [ ] I have a way to stop tests quickly
- [ ] I've optimized my system (for high-volume)
- [ ] I understand the risks and costs

---

**Remember:** The goal is to understand your limits and improve resilience, not to break your own service.

For detailed high-volume testing guide, see: **PERFORMANCE_GUIDE.md**
