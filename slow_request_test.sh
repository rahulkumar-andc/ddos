#!/bin/bash

# Slow Request Testing Script (Slowloris-style)
# For testing slow HTTP attack resilience on YOUR OWN infrastructure

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
echo "   ⚠️  CONTROLLED SLOW REQUEST TESTING"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "Target:       $TARGET"
echo "Connections:  $MAX_CONNECTIONS"
echo "Duration:     $MAX_DURATION seconds"
echo "Dry Run:      $DRY_RUN"
echo ""
echo "⚠️  WARNING: ONLY test infrastructure you own!"
echo "⚠️  This tests your web server's slow request handling."
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
LOG_FILE="${LOG_DIR}/slow_request_${TIMESTAMP}.log"

if [[ "$DRY_RUN" == "true" ]]; then
    echo "🧪 DRY RUN MODE - No actual connections will be made"
    echo ""
    echo "Would execute:"
    echo "  Tool: slowloris (Python)"
    echo "  Target: $TARGET"
    echo "  Sockets: $MAX_CONNECTIONS"
    echo "  Duration: $MAX_DURATION seconds"
    echo ""
    echo "✅ Dry run complete. Remove --dry-run flag to execute."
    exit 0
fi

# Check if slowloris exists
SLOWLORIS_PATH="${SCRIPT_DIR}/slowloris/slowloris.py"
if [[ ! -f "$SLOWLORIS_PATH" ]]; then
    echo "❌ Slowloris not found!"
    echo ""
    echo "Install it:"
    echo "  cd $SCRIPT_DIR"
    echo "  git clone https://github.com/gkbrk/slowloris.git"
    echo "  cd slowloris"
    echo "  pip3 install -r requirements.txt"
    exit 1
fi

echo "🚀 Starting slow request test..."
echo "📊 Logging to: $LOG_FILE"
echo ""

# Run slowloris with controlled parameters
PORT_FLAG=""
if [[ "$HTTP_PORT" != "80" ]]; then
    PORT_FLAG="--port $HTTP_PORT"
fi

timeout "$MAX_DURATION" python3 "$SLOWLORIS_PATH" \
    "$TARGET" \
    $PORT_FLAG \
    --sockets "$MAX_CONNECTIONS" \
    --sleeptime 15 \
    2>&1 | tee "$LOG_FILE"

echo ""
echo "✅ Test complete!"
echo "📝 Log saved to: $LOG_FILE"
