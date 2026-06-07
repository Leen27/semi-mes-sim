#!/bin/bash
# Three-Layer Termination Validation + Architecture Boundary Enforcement
# ======================================================================
# Lecture 10: Only a Full Pipeline Run Counts as Real Verification
#
# Layer 0: Architecture Boundary Enforcement (executable rules from AGENTS.md)
# Layer 1: Syntax & Static Analysis (lint + type-check)
# Layer 2: Runtime Behavior Verification (unit tests + build)
# Layer 3: System-Level Confirmation (end-to-end / cross-component integration)
#
# Usage: bash scripts/verify-layers.sh [feature-id]

set -uo pipefail

FEATURE_ID="${1:-}"
ERRORS=0
SKIPPED=0

# Initialize trace if not already set
if [ -z "${TRACE_FILE:-}" ] && [ -n "$FEATURE_ID" ]; then
  TRACE_FILE=$(bash scripts/harness-trace.sh init "$FEATURE_ID")
  export TRACE_FILE
fi

echo "========================================"
echo "Three-Layer Termination Validation"
echo "========================================"
if [ -n "$FEATURE_ID" ]; then
  echo "Feature: $FEATURE_ID"
fi
if [ -n "${TRACE_FILE:-}" ]; then
  echo "Trace:   $TRACE_FILE"
fi
echo ""
echo "Hierarchy: Layer 0 -> Layer 1 -> Layer 2 -> Layer 3"
echo "Skipping any required layer = NOT COMPLETE"
echo ""

# === Layer 0: Architecture Boundary Enforcement ===
echo "[Layer 0] Architecture Boundary Enforcement"
echo "--------------------------------------"

LAYER0_START=$(date +%s%N)
if bash scripts/verify-architecture.sh > /tmp/arch-check.log 2>&1; then
  echo "  ✅ Layer 0: architecture boundaries OK"
  LAYER0_STATUS="passed"
else
  echo "  ❌ Layer 0: architecture boundary violations detected"
  cat /tmp/arch-check.log | grep -E "ERROR:|WHY:|FIX:" | sed 's/^/    /'
  ERRORS=$((ERRORS + 1))
  LAYER0_STATUS="failed"
fi
LAYER0_END=$(date +%s%N)
LAYER0_MS=$(( (LAYER0_END - LAYER0_START) / 1000000 ))
if [ -n "${TRACE_FILE:-}" ]; then
  bash scripts/harness-trace.sh layer 0 "$LAYER0_STATUS" "null" "$LAYER0_MS"
fi

echo ""

# If Layer 0 fails, we can still continue to show other errors,
# but the final exit code will be non-zero.

# === Layer 1: Syntax & Static Analysis ===
echo "[Layer 1] Syntax & Static Analysis"
echo "--------------------------------------"

LAYER1_START=$(date +%s%N)
LAYER1_ERRORS=0

if pnpm lint 2>&1 | tail -3; then
  echo "  ✅ Layer 1a: lint passed"
else
  echo "  ❌ Layer 1a: lint FAILED"
  ERRORS=$((ERRORS + 1))
  LAYER1_ERRORS=$((LAYER1_ERRORS + 1))
fi

if pnpm type-check 2>&1 | tail -3; then
  echo "  ✅ Layer 1b: type-check passed"
else
  echo "  ❌ Layer 1b: type-check FAILED"
  ERRORS=$((ERRORS + 1))
  LAYER1_ERRORS=$((LAYER1_ERRORS + 1))
fi

LAYER1_END=$(date +%s%N)
LAYER1_MS=$(( (LAYER1_END - LAYER1_START) / 1000000 ))
LAYER1_STATUS=$([ "$LAYER1_ERRORS" -eq 0 ] && echo "passed" || echo "failed")
if [ -n "${TRACE_FILE:-}" ]; then
  bash scripts/harness-trace.sh layer 1 "$LAYER1_STATUS" "{\"lintErrors\": $LAYER1_ERRORS}" "$LAYER1_MS"
fi

echo ""

# === Layer 2: Runtime Behavior Verification ===
echo "[Layer 2] Runtime Behavior Verification"
echo "--------------------------------------"

LAYER2_START=$(date +%s%N)
LAYER2_ERRORS=0

if pnpm test 2>&1 | tail -5; then
  echo "  ✅ Layer 2a: unit tests passed"
else
  echo "  ❌ Layer 2a: unit tests FAILED"
  ERRORS=$((ERRORS + 1))
  LAYER2_ERRORS=$((LAYER2_ERRORS + 1))
fi

if pnpm build 2>&1 | tail -3; then
  echo "  ✅ Layer 2b: build passed"
else
  echo "  ❌ Layer 2b: build FAILED"
  ERRORS=$((ERRORS + 1))
  LAYER2_ERRORS=$((LAYER2_ERRORS + 1))
fi

LAYER2_END=$(date +%s%N)
LAYER2_MS=$(( (LAYER2_END - LAYER2_START) / 1000000 ))
LAYER2_STATUS=$([ "$LAYER2_ERRORS" -eq 0 ] && echo "passed" || echo "failed")
if [ -n "${TRACE_FILE:-}" ]; then
  bash scripts/harness-trace.sh layer 2 "$LAYER2_STATUS" "{\"testBuildErrors\": $LAYER2_ERRORS}" "$LAYER2_MS"
fi

echo ""

# === Layer 3: System-Level Confirmation ===
echo "[Layer 3] System-Level Confirmation (End-to-End)"
echo "--------------------------------------"

LAYER3_START=$(date +%s%N)
LAYER3_ERRORS=0
LAYER3_CHECKS_PASSED=0
LAYER3_CHECKS_TOTAL=0

# 3a: Check that web app build artifacts exist
LAYER3_CHECKS_TOTAL=$((LAYER3_CHECKS_TOTAL + 1))
if [ -f "apps/web/dist/index.html" ]; then
  echo "  ✅ Layer 3a: web app build artifacts exist"
  LAYER3_CHECKS_PASSED=$((LAYER3_CHECKS_PASSED + 1))
else
  echo "  ⚠️  Layer 3a: web app build artifacts not found (run 'pnpm build' first)"
  SKIPPED=$((SKIPPED + 1))
fi

# 3b: Check that core build artifacts exist
LAYER3_CHECKS_TOTAL=$((LAYER3_CHECKS_TOTAL + 1))
if [ -d "packages/core/dist" ]; then
  echo "  ✅ Layer 3b: core package build artifacts exist"
  LAYER3_CHECKS_PASSED=$((LAYER3_CHECKS_PASSED + 1))
else
  echo "  ⚠️  Layer 3b: core package build artifacts not found"
  SKIPPED=$((SKIPPED + 1))
fi

# 3c: Check that 3d-engine build artifacts exist
LAYER3_CHECKS_TOTAL=$((LAYER3_CHECKS_TOTAL + 1))
if [ -d "packages/3d-engine/dist" ]; then
  echo "  ✅ Layer 3c: 3d-engine build artifacts exist"
  LAYER3_CHECKS_PASSED=$((LAYER3_CHECKS_PASSED + 1))
else
  echo "  ⚠️  Layer 3c: 3d-engine build artifacts not found"
  SKIPPED=$((SKIPPED + 1))
fi

# 3d: Check that ui build artifacts exist
LAYER3_CHECKS_TOTAL=$((LAYER3_CHECKS_TOTAL + 1))
if [ -d "packages/ui/dist" ]; then
  echo "  ✅ Layer 3d: ui package build artifacts exist"
  LAYER3_CHECKS_PASSED=$((LAYER3_CHECKS_PASSED + 1))
else
  echo "  ⚠️  Layer 3d: ui package build artifacts not found"
  SKIPPED=$((SKIPPED + 1))
fi

# 3e: Cross-component import verification
LAYER3_CHECKS_TOTAL=$((LAYER3_CHECKS_TOTAL + 1))
WEB_BUNDLE=$(find apps/web/dist/assets -maxdepth 1 -name "index-*" \( -name "*.js" -o -name "*.mjs" \) | head -1)
if [ -n "$WEB_BUNDLE" ]; then
  if grep -q "SceneManager\|SimulationEngine\|EquipmentCard" "$WEB_BUNDLE" 2>/dev/null; then
    echo "  ✅ Layer 3e: cross-component symbols found in web bundle"
    LAYER3_CHECKS_PASSED=$((LAYER3_CHECKS_PASSED + 1))
  else
    echo "  ⚠️  Layer 3e: cross-component symbols not detected in web bundle"
    SKIPPED=$((SKIPPED + 1))
  fi
else
  echo "  ⚠️  Layer 3e: web bundle not found (run 'pnpm build' first)"
  SKIPPED=$((SKIPPED + 1))
fi

# 3f: Check packages/ui/index.d.ts exists (AGENTS.md requirement)
LAYER3_CHECKS_TOTAL=$((LAYER3_CHECKS_TOTAL + 1))
if [ -f "packages/ui/index.d.ts" ]; then
  echo "  ✅ Layer 3f: packages/ui/index.d.ts exists"
  LAYER3_CHECKS_PASSED=$((LAYER3_CHECKS_PASSED + 1))
else
  echo "  ❌ Layer 3f: packages/ui/index.d.ts missing"
  echo "    WHY: AGENTS.md requires @semi/ui to maintain index.d.ts for type exports."
  echo "    FIX: Create packages/ui/index.d.ts and declare all public components."
  ERRORS=$((ERRORS + 1))
  LAYER3_ERRORS=$((LAYER3_ERRORS + 1))
fi

LAYER3_END=$(date +%s%N)
LAYER3_MS=$(( (LAYER3_END - LAYER3_START) / 1000000 ))
LAYER3_STATUS=$([ "$LAYER3_ERRORS" -eq 0 ] && echo "passed" || echo "failed")
if [ -n "${TRACE_FILE:-}" ]; then
  bash scripts/harness-trace.sh layer 3 "$LAYER3_STATUS" "{\"checksPassed\": $LAYER3_CHECKS_PASSED, \"checksTotal\": $LAYER3_CHECKS_TOTAL, \"skipped\": $SKIPPED}" "$LAYER3_MS"
fi

echo ""

# ============================================
# Summary
# ============================================
echo "========================================"
if [ "$ERRORS" -eq 0 ]; then
  echo "✅ All required layers passed (0 errors)"
  if [ "$SKIPPED" -gt 0 ]; then
    echo "⚠️  $SKIPPED layer-3 check(s) skipped (run 'pnpm build' to enable full Layer 3)"
  fi
  echo "========================================"
  FINAL_STATUS="passed"
else
  echo "❌ $ERRORS layer(s) FAILED"
  echo "========================================"
  echo ""
  echo "Do NOT declare completion. Fix failures first."
  echo "Layer 0 must pass before Layer 1."
  echo "Layer 1 must pass before Layer 2."
  echo "Layer 2 must pass before Layer 3."
  echo ""
  echo "For cross-component changes (e.g., changes in both core and web):"
  echo "  - Unit tests alone are systematically blind to boundary defects"
  echo "  - End-to-end verification (Layer 3) is MANDATORY"
  echo "  - Build artifacts + cross-component symbol checks prove integration"
  FINAL_STATUS="failed"
fi

# Finalize trace
if [ -n "${TRACE_FILE:-}" ]; then
  echo ""
  bash scripts/harness-trace.sh finalize "$FINAL_STATUS"
fi

if [ "$ERRORS" -eq 0 ]; then
  exit 0
else
  exit 1
fi
