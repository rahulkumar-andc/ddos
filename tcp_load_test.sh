#!/bin/bash

# TCP Connection Load Testing Script
# For controlled TCP SYN testing of YOUR OWN infrastructure

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
echo "   ⚠️  CONTROLLED TCP CONNECTION TESTING"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "Target:       $TARGET"
echo "Max Rate:     $MAX_RATE packets/s"
echo "Duration:     $MAX_DURATION seconds"
echo "Dry Run:      $DRY_RUN"
echo ""
echo "⚠️  WARNING: ONLY test infrastructure you own!"
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
LOG_FILE="${LOG_DIR}/tcp_load_${TIMESTAMP}.log"

if [[ "$DRY_RUN" == "true" ]]; then
    echo "🧪 DRY RUN MODE - No actual packets will be sent"
    echo ""
    echo "Would execute:"
    echo "  Tool: hping3"
    echo "  Target: $TARGET"
    echo "  Type: TCP SYN"
    echo "  Rate: $MAX_RATE packets/s (controlled)"
    echo "  Duration: $MAX_DURATION seconds"
    echo ""
    echo "✅ Dry run complete. Remove --dry-run flag to execute."
    exit 0
fi

# Check if hping3 is installed
if ! command -v hping3 &> /dev/null; then
    echo "❌ hping3 not installed!"
    echo "Install: sudo apt install hping3"
    exit 1
fi

# Check for root
if [[ $EUID -ne 0 ]]; then
   echo "❌ This script requires root privileges (for hping3)"
   echo "Run: sudo $0"
   exit 1
fi

echo "🚀 Starting TCP connection test..."
echo "📊 Logging to: $LOG_FILE"
echo ""

# Use controlled rate (not --flood which is dangerous)
# -S = SYN flag, -p = port, --faster = controlled rate increase
timeout "$MAX_DURATION" hping3 -S -p "$HTTP_PORT" \
    --interval "u$((1000000 / MAX_RATE))" \
    --count "$((MAX_RATE * MAX_DURATION))" \
    "$TARGET" 2>&1 | tee "$LOG_FILE"

echo ""
echo "✅ Test complete!"
echo "📝 Log saved to: $LOG_FILE"
