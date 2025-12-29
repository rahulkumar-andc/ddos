# High-Volume Testing Guide (10,000+ req/s)

## ⚡ Overview

This guide helps you achieve **10,000+ requests per second** for load testing your infrastructure.

## 🎯 Updated Configuration

```bash
MAX_RATE=15000             # 15,000 req/s
MAX_CONNECTIONS=10000      # 10,000 concurrent connections
```

## 📊 Performance by Tool

| Tool | Max Rate | Best For |
|------|----------|----------|
| **wrk** (high_volume_http.sh) | 100K+ req/s | ⭐ Best for HTTP |
| **Apache Bench** (http_load_test.sh) | 50K req/s | Good for HTTP |
| **hping3** (tcp_load_test.sh) | 100K+ packets/s | TCP/SYN floods |
| **Python Distributed** | 5K req/s | IP rotation |

## 🚀 Quick Start for 10K+ req/s

### Step 1: System Optimization (REQUIRED)

```bash
# Run system optimization (needs sudo)
sudo ./optimize_system.sh

# Logout and login for changes to take effect
# Or run: exec su -l $USER
```

### Step 2: Choose Your Tool

#### Option A: wrk (RECOMMENDED for max performance)
```bash
# Install wrk
sudo apt install wrk

# Run high-volume test
./high_volume_http.sh
```

#### Option B: Apache Bench
```bash
# Already installed
./http_load_test.sh
```

#### Option C: TCP SYN Flood
```bash
# Requires root
sudo ./tcp_load_test.sh
```

### Step 3: Verify Results

Check logs in `./logs/` directory for actual achieved rate.

## ⚠️ Critical Warnings

### 🔴 WILL Crash Your Server
At 10K+ req/s:
- **Render.com free tier** will crash instantly
- **Shared hosting** will ban you
- **Cloudflare** will rate-limit/block you

### 💰 Will Cost Money
- Bandwidth charges can spike
- Server resources maxed out
- Potential overage fees

### 🚨 Legal Risks
- **Violates most hosting ToS**
- Could trigger abuse reports
- Potential account termination

## 📈 Gradual Ramp-Up Strategy

Start conservatively and increase:

```bash
# Test 1: Baseline (1K req/s)
MAX_RATE=1000 ./high_volume_http.sh

# Test 2: Moderate (5K req/s)
MAX_RATE=5000 ./high_volume_http.sh

# Test 3: High (10K req/s)
MAX_RATE=10000 ./high_volume_http.sh

# Test 4: Extreme (15K+ req/s)
MAX_RATE=15000 ./high_volume_http.sh
```

**Monitor your server between each test!**

## 🔍 Troubleshooting

### "Too many open files" Error
```bash
# Check current limit
ulimit -n

# Should be ≥ 100,000
# If not, run: sudo ./optimize_system.sh
```

### Low Request Rate Achieved
Possible causes:
1. **System not optimized** - Run `optimize_system.sh`
2. **Poor network** - Check bandwidth
3. **Target limiting** - Server has DDoS protection
4. **CPU bottleneck** - Your machine is limiting

### Connection Timeouts
- Server overwhelmed (success!)
- Or DDoS protection kicked in
- Reduce rate and try again

## 💡 Pro Tips

### 1. Use wrk for Best Performance
```bash
wrk -t$(nproc) -c10000 -d60s https://villen.me
```

### 2. Test from Multiple Machines
Distribute load across multiple systems for true distributed testing.

### 3. Monitor Server Metrics
Watch:
- CPU usage
- Memory
- Network bandwidth
- Response times
- Error rates

### 4. Test Different Endpoints
```bash
# Static content (easier)
https://villen.me/static/image.jpg

# Dynamic content (harder)
https://villen.me/api/search?q=test

# Login pages (hardest)
https://villen.me/login
```

## 📊 Expected Results

### Good Infrastructure (Cloudflare + CDN)
- **Should handle**: 10K-50K req/s
- **Response time**: < 100ms
- **Success rate**: > 99%

### Basic Infrastructure (Render.com free)
- **Will fail at**: 100-500 req/s
- **Response time**: Timeouts
- **Success rate**: < 50%

## 🎯 Next Steps

After testing:
1. **Analyze results** - Where did it break?
2. **Implement fixes** - Add caching, CDN, load balancer
3. **Retest** - Measure improvement
4. **Scale up** - Add more resources as needed

## 🆘 Emergency Stop

If tests go wrong:
```bash
# Kill all tests
pkill -f "wrk|ab|hping3|python.*distributed"

# Check what's running
ps aux | grep -E "wrk|ab|hping3"

# Restart network if needed
sudo systemctl restart NetworkManager
```

---

**Remember**: The goal is to **understand your limits**, not to break your service!
