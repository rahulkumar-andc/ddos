#!/bin/bash

# Master Test Orchestrator
# Runs all load tests in sequence with controlled intervals

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
DRY_RUN_FLAG=""
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN_FLAG="--dry-run"
fi

# Safety banner
echo "════════════════════════════════════════════════════════════"
echo "   ⚠️  MASTER LOAD TESTING ORCHESTRATOR"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "Target:       $TARGET"
echo "Tests:        Port Scan → TCP Load → HTTP Load → Slow Request"
echo "Dry Run:      ${DRY_RUN:-false}"
echo ""
echo "⚠️  WARNING: This will run ALL tests sequentially."
echo "⚠️  ONLY use on infrastructure you own!"
echo ""
echo "════════════════════════════════════════════════════════════"
echo ""

# Confirmation
if [[ "$REQUIRE_CONFIRMATION" == "true" ]] && [[ -z "$DRY_RUN_FLAG" ]]; then
    read -p "🔴 Confirm you OWN $TARGET and want to run ALL tests? (yes/no): " confirm
    if [[ "$confirm" != "yes" ]]; then
        echo "❌ Tests cancelled."
        exit 0
    fi
fi

# Cool-down interval between tests (seconds)
COOLDOWN=30

echo "🚀 Starting master test sequence..."
echo ""

# Test 1: Port Scan
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "TEST 1/4: Port Scanning"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
bash "${SCRIPT_DIR}/port_scan.sh" $DRY_RUN_FLAG
if [[ -z "$DRY_RUN_FLAG" ]]; then
    echo "⏳ Cooling down for ${COOLDOWN}s..."
    sleep "$COOLDOWN"
fi
echo ""

# Test 2: TCP Load
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "TEST 2/4: TCP Connection Load"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
bash "${SCRIPT_DIR}/tcp_load_test.sh" $DRY_RUN_FLAG
if [[ -z "$DRY_RUN_FLAG" ]]; then
    echo "⏳ Cooling down for ${COOLDOWN}s..."
    sleep "$COOLDOWN"
fi
echo ""

# Test 3: HTTP Load
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "TEST 3/4: HTTP Load Testing"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
bash "${SCRIPT_DIR}/http_load_test.sh" $DRY_RUN_FLAG
if [[ -z "$DRY_RUN_FLAG" ]]; then
    echo "⏳ Cooling down for ${COOLDOWN}s..."
    sleep "$COOLDOWN"
fi
echo ""

# Test 4: Slow Request
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "TEST 4/4: Slow Request Testing"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
bash "${SCRIPT_DIR}/slow_request_test.sh" $DRY_RUN_FLAG
echo ""

echo "════════════════════════════════════════════════════════════"
echo "✅ ALL TESTS COMPLETE!"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "📊 Results location: ${RESULTS_DIR}/"
echo "📝 Logs location: ${LOG_DIR}/"
echo ""
echo "Next steps:"
echo "  1. Review results in ${RESULTS_DIR}/"
echo "  2. Check logs in ${LOG_DIR}/"
echo "  3. Analyze your infrastructure's performance"
echo "  4. Implement improvements based on findings"
