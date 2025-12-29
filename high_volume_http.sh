#!/bin/bash

# High-Volume HTTP Load Testing
# Uses wrk (optimized for high throughput)
# Can achieve 100,000+ req/s on good hardware

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/config.conf"

# Load configuration
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "❌ Error: config.conf not found!"
    exit 1
fi

source "$CONFIG_FILE"

# Parse arguments
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=true
fi

# Safety banner
echo "════════════════════════════════════════════════════════════"
echo "   ⚡ HIGH-VOLUME HTTP LOAD TESTING (10K+ req/s)"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "Target:       ${HTTPS_URL:-$TARGET}"
echo "Max Rate:     $MAX_RATE req/s (15K)"
echo "Duration:     $MAX_DURATION seconds"
echo "Connections:  $MAX_CONNECTIONS"
echo "Threads:      $(nproc)"
echo "Dry Run:      ${DRY_RUN:-false}"
echo ""
echo "⚠️  WARNING: This is HIGH-VOLUME mode!"
echo "⚠️  Only use on infrastructure you own!"
echo "⚠️  May trigger DDoS protection/bans!"
echo ""
echo "════════════════════════════════════════════════════════════"
echo ""

# Confirmation
if [[ "$REQUIRE_CONFIRMATION" == "true" ]] && [[ "${DRY_RUN:-false}" == "false" ]]; then
    read -p "🔴 Confirm you OWN the target and understand the risks? (yes/no): " confirm
    if [[ "$confirm" != "yes" ]]; then
        echo "❌ Test cancelled."
        exit 0
    fi
fi

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

mkdir -p "$LOG_DIR" "$RESULTS_DIR"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="${LOG_DIR}/high_volume_${TIMESTAMP}.log"

if [[ "${DRY_RUN:-false}" == "true" ]]; then
    echo "🧪 DRY RUN MODE"
    echo ""
    echo "Would execute:"
    echo "  Tool: wrk (high-performance HTTP benchmarking)"
    echo "  URL: $URL"
    echo "  Threads: $(nproc)"
    echo "  Connections: $MAX_CONNECTIONS"
    echo "  Duration: $MAX_DURATION seconds"
    echo "  Expected Rate: $MAX_RATE+ req/s"
    echo ""
    echo "Installation needed:"
    echo "  sudo apt install wrk"
    echo ""
    echo "System optimization needed:"
    echo "  sudo ./optimize_system.sh"
    echo ""
    echo "✅ Dry run complete."
    exit 0
fi

# Check if wrk is installed
if ! command -v wrk &> /dev/null; then
    echo "❌ wrk not installed!"
    echo ""
    echo "Install wrk:"
    echo "  sudo apt update"
    echo "  sudo apt install wrk"
    echo ""
    echo "Or build from source for latest version:"
    echo "  git clone https://github.com/wg/wrk.git"
    echo "  cd wrk"
    echo "  make"
    echo "  sudo cp wrk /usr/local/bin/"
    exit 1
fi

# Check system limits
CURRENT_ULIMIT=$(ulimit -n)
if [[ $CURRENT_ULIMIT -lt 100000 ]]; then
    echo "⚠️  WARNING: File descriptor limit is low ($CURRENT_ULIMIT)"
    echo "   For 10K+ req/s, you need higher limits."
    echo ""
    echo "   Run: sudo ./optimize_system.sh"
    echo "   Then logout and login again."
    echo ""
    read -p "Continue anyway? (yes/no): " continue
    if [[ "$continue" != "yes" ]]; then
        exit 0
    fi
fi

# Calculate threads (use all CPU cores)
THREADS=$(nproc)

echo "🚀 Starting high-volume HTTP test..."
echo "📊 Logging to: $LOG_FILE"
echo ""
echo "Configuration:"
echo "  URL: $URL"
echo "  Threads: $THREADS"
echo "  Connections: $MAX_CONNECTIONS"
echo "  Duration: $MAX_DURATION seconds"
echo ""

# Run wrk
wrk -t$THREADS \
    -c$MAX_CONNECTIONS \
    -d${MAX_DURATION}s \
    --latency \
    --timeout 10s \
    "$URL" 2>&1 | tee "$LOG_FILE"

echo ""
echo "✅ Test complete!"
echo "📝 Log saved to: $LOG_FILE"
echo ""

# Parse results
if grep -q "Requests/sec" "$LOG_FILE"; then
    echo "📊 Summary:"
    grep -E "(Requests/sec|Latency|requests in)" "$LOG_FILE"
fi
