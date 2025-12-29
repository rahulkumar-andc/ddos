#!/bin/bash

# HTTP Load Testing Script
# For controlled load testing of YOUR OWN infrastructure

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
DRY_RUN_ARG=false
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN_ARG=true
    DRY_RUN=true
fi

# Safety banner
echo "════════════════════════════════════════════════════════════"
echo "   ⚠️  CONTROLLED HTTP LOAD TESTING FRAMEWORK"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "Target:       $TARGET"
echo "Max Rate:     $MAX_RATE req/s"
echo "Duration:     $MAX_DURATION seconds"
echo "Connections:  $MAX_CONNECTIONS"
echo "Dry Run:      $DRY_RUN"
echo ""
echo "⚠️  WARNING: ONLY test infrastructure you own!"
echo "⚠️  This test will generate load on the target."
echo ""
echo "════════════════════════════════════════════════════════════"
echo ""

# Confirmation prompt
if [[ "$REQUIRE_CONFIRMATION" == "true" ]] && [[ "$DRY_RUN" == "false" ]]; then
    read -p "🔴 Confirm you OWN $TARGET and want to proceed? (yes/no): " confirm
    if [[ "$confirm" != "yes" ]]; then
        echo "❌ Test cancelled."
        exit 0
    fi
fi

# Prepare URL
if [[ -n "${HTTPS_URL:-}" ]]; then
    # Use HTTPS_URL from config if set
    URL="$HTTPS_URL"
else
    # Build URL from protocol and target
    PROTOCOL="http"
    PORT=$HTTP_PORT
    if [[ "$HTTPS_ENABLED" == "true" ]]; then
        PROTOCOL="https"
    fi
    URL="${PROTOCOL}://${TARGET}:${PORT}/"
fi
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="${LOG_DIR}/http_load_${TIMESTAMP}.log"
RESULT_FILE="${RESULTS_DIR}/http_result_${TIMESTAMP}.txt"

if [[ "$DRY_RUN" == "true" ]]; then
    echo "🧪 DRY RUN MODE - No actual requests will be sent"
    echo ""
    echo "Would execute:"
    echo "  Tool: Apache Bench (ab)"
    echo "  URL: $URL"
    echo "  Requests: $((MAX_RATE * MAX_DURATION))"
    echo "  Concurrency: $MAX_CONNECTIONS"
    echo "  Duration: ~$MAX_DURATION seconds"
    echo ""
    echo "✅ Dry run complete. Remove --dry-run flag to execute."
    exit 0
fi

# Check if ab is installed
if ! command -v ab &> /dev/null; then
    echo "❌ Apache Bench (ab) not installed!"
    echo "Install: sudo apt install apache2-utils"
    exit 1
fi

# Run test
echo "🚀 Starting HTTP load test..."
echo "📊 Logging to: $LOG_FILE"
echo ""

TOTAL_REQUESTS=$((MAX_RATE * MAX_DURATION))
REQUESTS_PER_TEST=$((MAX_RATE < 50000 ? MAX_RATE * 10 : 50000))  # Limit ab requests

echo "Testing with ab (Apache Bench)..."
ab -n "$REQUESTS_PER_TEST" \
   -c "$MAX_CONNECTIONS" \
   -t "$MAX_DURATION" \
   -g "$RESULT_FILE" \
   -H "User-Agent: $USER_AGENT" \
   "$URL" 2>&1 | tee "$LOG_FILE"

echo ""
echo "✅ Test complete!"
echo "📊 Results saved to: $RESULT_FILE"
echo "📝 Log saved to: $LOG_FILE"
echo ""
echo "Summary:"
grep -E "(Requests per second|Time per request|Failed requests)" "$LOG_FILE" || true
