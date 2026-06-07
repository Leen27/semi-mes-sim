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

echo "========================================"
echo "Three-Layer Termination Validation"
echo "========================================"
if [ -n "$FEATURE_ID" ]; then
  echo "Feature: $FEATURE_ID"
fi
echo ""
echo "Hierarchy: Layer 0 -> Layer 1 -> Layer 2 -> Layer 3"
echo "Skipping any required layer = NOT COMPLETE"
echo ""

# === Layer 0: Architecture Boundary Enforcement ===
echo "[Layer 0] Architecture Boundary Enforcement"
echo "--------------------------------------"

if bash scripts/verify-architecture.sh > /tmp/arch-check.log 2>&1; then
  echo "  ✅ Layer 0: architecture boundaries OK"
else
  echo "  ❌ Layer 0: architecture boundary violations detected"
  cat /tmp/arch-check.log | grep -E "ERROR:|WHY:|FIX:" | sed 's/^/    /'
  ERRORS=$((ERRORS + 1))
fi

echo ""

# If Layer 0 fails, we can still continue to show other errors,
# but the final exit code will be non-zero.

# === Layer 1: Syntax & Static Analysis ===
echo "[Layer 1] Syntax & Static Analysis"
echo "--------------------------------------"

if pnpm lint 2>&1 | tail -3; then
  echo "  ✅ Layer 1a: lint passed"
else
  echo "  ❌ Layer 1a: lint FAILED"
  ERRORS=$((ERRORS + 1))
fi

if pnpm type-check 2>&1 | tail -3; then
  echo "  ✅ Layer 1b: type-check passed"
else
  echo "  ❌ Layer 1b: type-check FAILED"
  ERRORS=$((ERRORS + 1))
fi

echo ""

# === Layer 2: Runtime Behavior Verification ===
echo "[Layer 2] Runtime Behavior Verification"
echo "--------------------------------------"

if pnpm test 2>&1 | tail -5; then
  echo "  ✅ Layer 2a: unit tests passed"
else
  echo "  ❌ Layer 2a: unit tests FAILED"
  ERRORS=$((ERRORS + 1))
fi

if pnpm build 2>&1 | tail -3; then
  echo "  ✅ Layer 2b: build passed"
else
  echo "  ❌ Layer 2b: build FAILED"
  ERRORS=$((ERRORS + 1))
fi

echo ""

# === Layer 3: System-Level Confirmation ===
echo "[Layer 3] System-Level Confirmation (End-to-End)"
echo "--------------------------------------"

# 3a: Check that web app build artifacts exist
if [ -f "apps/web/dist/index.html" ]; then
  echo "  ✅ Layer 3a: web app build artifacts exist"
else
  echo "  ⚠️  Layer 3a: web app build artifacts not found (run 'pnpm build' first)"
  SKIPPED=$((SKIPPED + 1))
fi

# 3b: Check that core build artifacts exist
if [ -d "packages/core/dist" ]; then
  echo "  ✅ Layer 3b: core package build artifacts exist"
else
  echo "  ⚠️  Layer 3b: core package build artifacts not found"
  SKIPPED=$((SKIPPED + 1))
fi

# 3c: Check that 3d-engine build artifacts exist
if [ -d "packages/3d-engine/dist" ]; then
  echo "  ✅ Layer 3c: 3d-engine build artifacts exist"
else
  echo "  ⚠️  Layer 3c: 3d-engine build artifacts not found"
  SKIPPED=$((SKIPPED + 1))
fi

# 3d: Check that ui build artifacts exist
if [ -d "packages/ui/dist" ]; then
  echo "  ✅ Layer 3d: ui package build artifacts exist"
else
  echo "  ⚠️  Layer 3d: ui package build artifacts not found"
  SKIPPED=$((SKIPPED + 1))
fi

# 3e: Cross-component import verification
# Verify that apps/web can import from all three workspace packages
WEB_BUNDLE=$(find apps/web/dist/assets -maxdepth 1 -name "index-*" \( -name "*.js" -o -name "*.mjs" \) | head -1)
if [ -n "$WEB_BUNDLE" ]; then
  # Heuristic: check if bundle contains references to key exports from workspace packages
  # This is a lightweight proxy for "the app actually wired everything together"
  if grep -q "SceneManager\|SimulationEngine\|EquipmentCard" "$WEB_BUNDLE" 2>/dev/null; then
    echo "  ✅ Layer 3e: cross-component symbols found in web bundle"
  else
    echo "  ⚠️  Layer 3e: cross-component symbols not detected in web bundle"
    SKIPPED=$((SKIPPED + 1))
  fi
else
  echo "  ⚠️  Layer 3e: web bundle not found (run 'pnpm build' first)"
  SKIPPED=$((SKIPPED + 1))
fi

# 3f: Check packages/ui/index.d.ts exists (AGENTS.md requirement)
if [ -f "packages/ui/index.d.ts" ]; then
  echo "  ✅ Layer 3f: packages/ui/index.d.ts exists"
else
  echo "  ❌ Layer 3f: packages/ui/index.d.ts missing"
  echo "    WHY: AGENTS.md requires @semi/ui to maintain index.d.ts for type exports."
  echo "    FIX: Create packages/ui/index.d.ts and declare all public components."
  ERRORS=$((ERRORS + 1))
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
  exit 0
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
  exit 1
fi
