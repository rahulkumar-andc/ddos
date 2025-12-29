#!/bin/bash

# Distributed HTTP Load Testing Script
# Uses rotating proxies/IPs to simulate distributed attack patterns
# For testing YOUR OWN infrastructure's DDoS protection

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/config.conf"

# Load configuration
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "❌ Error: config.conf not found!"
    exit 1
fi

source "$CONFIG_FILE"

# Create directories
mkdir -p "$LOG_DIR" "$RESULTS_DIR"

# Parse arguments
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=true
fi

# Safety banner
echo "════════════════════════════════════════════════════════════"
echo "   ⚠️  DISTRIBUTED HTTP LOAD TESTING"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "Target:       $TARGET"
echo "Method:       Proxy Rotation / IP Spoofing Simulation"
echo "Max Rate:     $MAX_RATE req/s"
echo "Duration:     $MAX_DURATION seconds"
echo "Dry Run:      $DRY_RUN"
echo ""
echo "⚠️  WARNING: ONLY test infrastructure you own!"
echo "⚠️  This simulates distributed attack patterns."
echo ""
echo "════════════════════════════════════════════════════════════"
echo ""

# Confirmation
if [[ "$REQUIRE_CONFIRMATION" == "true" ]] && [[ "$DRY_RUN" == "false" ]]; then
    read -p "🔴 Confirm you OWN $TARGET and want to proceed? (yes/no): " confirm
    if [[ "$confirm" != "yes" ]]; then
        echo "❌ Test cancelled."
        exit 0
    fi
fi

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="${LOG_DIR}/distributed_http_${TIMESTAMP}.log"
PROXY_LIST="${SCRIPT_DIR}/proxy_list.txt"

# Prepare URL
if [[ -n "${HTTPS_URL:-}" ]]; then
    URL="$HTTPS_URL"
else
    PROTOCOL="http"
    if [[ "$HTTPS_ENABLED" == "true" ]]; then
        PROTOCOL="https"
    fi
    URL="${PROTOCOL}://${TARGET}:${HTTP_PORT}/"
fi

if [[ "$DRY_RUN" == "true" ]]; then
    echo "🧪 DRY RUN MODE - No actual requests will be sent"
    echo ""
    echo "Would execute:"
    echo "  Tool: Python requests with proxy rotation"
    echo "  URL: $URL"
    echo "  Proxies: From $PROXY_LIST or Tor"
    echo "  Rate: $MAX_RATE req/s distributed"
    echo "  Duration: $MAX_DURATION seconds"
    echo ""
    echo "Setup needed:"
    echo "  1. Create proxy_list.txt with proxy IPs"
    echo "  2. Or install Tor: sudo apt install tor"
    echo "  3. Install Python deps: pip3 install requests[socks] PySocks"
    echo ""
    echo "✅ Dry run complete."
    exit 0
fi

# Check if Python script exists, if not create it
PYTHON_SCRIPT="${SCRIPT_DIR}/distributed_loader.py"

if [[ ! -f "$PYTHON_SCRIPT" ]]; then
    echo "📝 Creating Python distributed loader script..."
    cat > "$PYTHON_SCRIPT" << 'PYTHON_EOF'
#!/usr/bin/env python3
"""
Distributed HTTP Load Generator
Rotates through proxies/IPs to simulate distributed load
"""

import requests
import time
import sys
import random
import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
from datetime import datetime, timedelta

# Disable SSL warnings for testing
import urllib3
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

class DistributedLoader:
    def __init__(self, target_url, proxy_list=None, use_tor=False):
        self.target_url = target_url
        self.proxies_pool = []
        self.use_tor = use_tor
        self.stats = {
            'success': 0,
            'failed': 0,
            'total': 0
        }
        
        # Load proxies
        if proxy_list and os.path.exists(proxy_list):
            with open(proxy_list, 'r') as f:
                for line in f:
                    line = line.strip()
                    if line and not line.startswith('#'):
                        self.proxies_pool.append({
                            'http': line,
                            'https': line
                        })
            print(f"✅ Loaded {len(self.proxies_pool)} proxies")
        
        # Setup Tor
        if use_tor:
            self.proxies_pool.append({
                'http': 'socks5h://127.0.0.1:9050',
                'https': 'socks5h://127.0.0.1:9050'
            })
            print("✅ Tor proxy added")
        
        if not self.proxies_pool:
            print("⚠️  No proxies available, using direct connection with random User-Agent")
    
    def make_request(self, request_id):
        """Make a single HTTP request"""
        try:
            # Rotate proxy if available
            proxy = None
            if self.proxies_pool:
                proxy = random.choice(self.proxies_pool)
            
            # Random User-Agent to vary fingerprint
            user_agents = [
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
                'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
                'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36',
                'Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X)',
            ]
            
            headers = {
                'User-Agent': random.choice(user_agents),
                'Accept': 'text/html,application/json',
                'Connection': 'close'
            }
            
            response = requests.get(
                self.target_url,
                headers=headers,
                proxies=proxy,
                timeout=10,
                verify=False
            )
            
            self.stats['success'] += 1
            return True, response.status_code
            
        except Exception as e:
            self.stats['failed'] += 1
            return False, str(e)
        finally:
            self.stats['total'] += 1
    
    def run(self, rate, duration, workers=50):
        """Run distributed load test"""
        print(f"\n🚀 Starting distributed load test...")
        print(f"   Target: {self.target_url}")
        print(f"   Rate: {rate} req/s")
        print(f"   Duration: {duration}s")
        print(f"   Workers: {workers}")
        print(f"   Proxies: {len(self.proxies_pool)}")
        print()
        
        end_time = datetime.now() + timedelta(seconds=duration)
        interval = 1.0 / rate  # Time between requests
        
        with ThreadPoolExecutor(max_workers=workers) as executor:
            request_id = 0
            
            while datetime.now() < end_time:
                batch_start = time.time()
                
                # Submit batch of requests
                futures = []
                for _ in range(rate):
                    if datetime.now() >= end_time:
                        break
                    future = executor.submit(self.make_request, request_id)
                    futures.append(future)
                    request_id += 1
                    time.sleep(interval)
                
                # Wait for batch to complete
                for future in as_completed(futures):
                    pass
                
                # Print stats every second
                print(f"📊 Requests: {self.stats['total']} | "
                      f"✅ Success: {self.stats['success']} | "
                      f"❌ Failed: {self.stats['failed']} | "
                      f"Rate: {self.stats['total']/(datetime.now().timestamp() - (end_time - timedelta(seconds=duration)).timestamp()):.1f} req/s",
                      end='\r')
        
        print(f"\n\n✅ Test complete!")
        print(f"   Total Requests: {self.stats['total']}")
        print(f"   Successful: {self.stats['success']}")
        print(f"   Failed: {self.stats['failed']}")
        print(f"   Success Rate: {(self.stats['success']/self.stats['total']*100):.1f}%")

if __name__ == '__main__':
    import os
    
    parser = argparse.ArgumentParser(description='Distributed HTTP Load Generator')
    parser.add_argument('url', help='Target URL')
    parser.add_argument('--rate', type=int, default=100, help='Requests per second')
    parser.add_argument('--duration', type=int, default=60, help='Test duration in seconds')
    parser.add_argument('--proxy-list', help='Path to proxy list file')
    parser.add_argument('--use-tor', action='store_true', help='Use Tor network')
    parser.add_argument('--workers', type=int, default=50, help='Concurrent workers')
    
    args = parser.parse_args()
    
    loader = DistributedLoader(
        target_url=args.url,
        proxy_list=args.proxy_list,
        use_tor=args.use_tor
    )
    
    loader.run(
        rate=args.rate,
        duration=args.duration,
        workers=args.workers
    )
PYTHON_EOF
    
    chmod +x "$PYTHON_SCRIPT"
    echo "✅ Python script created"
fi

# Check Python dependencies
echo "🔍 Checking Python dependencies..."
if ! python3 -c "import requests" 2>/dev/null; then
    echo "⚠️  Installing requests library..."
    pip3 install requests[socks] PySocks --user
fi

# Check for proxy list or Tor
USE_TOR=""
if [[ -f "$PROXY_LIST" ]]; then
    echo "✅ Found proxy list: $PROXY_LIST"
    PROXY_ARG="--proxy-list $PROXY_LIST"
elif systemctl is-active --quiet tor 2>/dev/null || pgrep tor >/dev/null; then
    echo "✅ Tor is running, will use Tor network"
    USE_TOR="--use-tor"
    PROXY_ARG="$USE_TOR"
else
    echo "⚠️  No proxies or Tor found. Will use direct connection with User-Agent rotation."
    echo "For better IP distribution:"
    echo "  1. Create $PROXY_LIST with proxy IPs (one per line)"
    echo "  2. Or install Tor: sudo apt install tor && sudo systemctl start tor"
    PROXY_ARG=""
fi

echo ""
echo "🚀 Starting distributed load test..."
echo "📊 Logging to: $LOG_FILE"
echo ""

# Run the Python distributed loader
python3 "$PYTHON_SCRIPT" \
    "$URL" \
    --rate "$MAX_RATE" \
    --duration "$MAX_DURATION" \
    --workers "$MAX_CONNECTIONS" \
    $PROXY_ARG \
    2>&1 | tee "$LOG_FILE"

echo ""
echo "✅ Test complete!"
echo "📝 Log saved to: $LOG_FILE"
