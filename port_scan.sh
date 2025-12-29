#!/bin/bash

# Port Scanning Script with Masscan
# For reconnaissance on YOUR OWN infrastructure

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
echo "   ⚠️  PORT SCANNING WITH MASSCAN"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "Target:       $TARGET"
echo "Ports:        $TCP_PORTS"
echo "Rate:         $MAX_RATE packets/s"
echo "Dry Run:      $DRY_RUN"
echo ""
echo "⚠️  WARNING: ONLY scan infrastructure you own!"
echo ""
echo "════════════════════════════════════════════════════════════"
echo ""

# Confirmation
if [[ "$REQUIRE_CONFIRMATION" == "true" ]] && [[ "$DRY_RUN" == "false" ]]; then
    read -p "🔴 Confirm you OWN $TARGET and want to proceed? (yes/no): " confirm
    if [[ "$confirm" != "yes" ]]; then
        echo "❌ Scan cancelled."
        exit 0
    fi
fi

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
RESULT_FILE="${RESULTS_DIR}/port_scan_${TIMESTAMP}.txt"

if [[ "$DRY_RUN" == "true" ]]; then
    echo "🧪 DRY RUN MODE - No actual scan will be performed"
    echo ""
    echo "Would execute:"
    echo "  Tool: masscan"
    echo "  Target: $TARGET"
    echo "  Ports: $TCP_PORTS"
    echo "  Rate: $MAX_RATE packets/s"
    echo "  Output: $RESULT_FILE"
    echo ""
    echo "✅ Dry run complete. Remove --dry-run flag to execute."
    exit 0
fi

# Check if masscan is installed
if ! command -v masscan &> /dev/null; then
    echo "❌ masscan not installed!"
    echo "Install: sudo apt install masscan"
    exit 1
fi

# Check for root
if [[ $EUID -ne 0 ]]; then
   echo "❌ This script requires root privileges (for masscan)"
   echo "Run: sudo $0"
   exit 1
fi

echo "🚀 Starting port scan..."
echo "📊 Results will be saved to: $RESULT_FILE"
echo ""

# Run masscan with controlled rate
masscan -p"$TCP_PORTS" "$TARGET" \
    --rate="$MAX_RATE" \
    --output-format list \
    --output-filename "$RESULT_FILE"

echo ""
echo "✅ Scan complete!"
echo "📊 Results saved to: $RESULT_FILE"
echo ""
echo "Open ports found:"
cat "$RESULT_FILE"
