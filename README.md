# ⚠️ Controlled Load Testing Framework

## IMPORTANT LEGAL & ETHICAL NOTICE

This toolkit is designed for **controlled load testing of YOUR OWN infrastructure only**.

### 🛡️ Safety Features Built-In:
- Rate limiting (max 1000 req/s default)
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
2. `http_load_test.sh` - Layer 7 HTTP load testing
3. `tcp_load_test.sh` - Layer 4 TCP connection testing
4. `slow_request_test.sh` - Slowloris-style testing
5. `port_scan.sh` - Port discovery with masscan
6. `distributed_http_test.sh` - **NEW:** Distributed load testing with IP rotation
7. `master_test.sh` - Orchestrator script
8. `setup_tor.sh` - Setup Tor for distributed testing

## Quick Start

1. **Edit configuration:**
   ```bash
   nano config.conf
   ```

2. **Run dry-run test:**
   ```bash
   ./http_load_test.sh --dry-run
   ```

3. **Run actual test (with confirmation):**
   ```bash
   ./http_load_test.sh
   ```

4. **NEW: Distributed testing (different IPs):**
   ```bash
   # Setup Tor for IP rotation
   ./setup_tor.sh
   
   # Run distributed test
   ./distributed_http_test.sh
   ```

## Installation Requirements

```bash
# Install required tools
sudo apt update
sudo apt install -y hping3 apache2-utils masscan python3 python3-pip git

# Optional: slowloris
git clone https://github.com/gkbrk/slowloris.git
cd slowloris
pip3 install -r requirements.txt
```

## Responsible Testing Checklist

- [ ] I own this domain/infrastructure
- [ ] I've checked my hosting provider's ToS
- [ ] I've notified my team about the testing
- [ ] I have monitoring in place
- [ ] I'm testing during off-peak hours
- [ ] I've started with low rate limits
- [ ] I have a way to stop tests quickly

---

**Remember:** The goal is to understand your limits, not to break your own service.
