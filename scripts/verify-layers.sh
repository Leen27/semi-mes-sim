#!/bin/bash
# Three-Layer Termination Validation
# Usage: bash scripts/verify-layers.sh [feature-id]
#
# Layer 1: Syntax & Static Analysis (lint + type-check)
# Layer 2: Runtime Behavior Verification (unit tests + build)
# Layer 3: System-Level Confirmation (end-to-end / app startup)

set -uo pipefail

FEATURE_ID="${1:-}"
ERRORS=0

echo "========================================"
echo "Three-Layer Termination Validation"
echo "========================================"
if [ -n "$FEATURE_ID" ]; then
  echo "Feature: $FEATURE_ID"
fi
echo ""

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
echo "[Layer 3] System-Level Confirmation"
echo "--------------------------------------"

# Check that web app build artifacts exist
if [ -f "apps/web/dist/index.html" ]; then
  echo "  ✅ Layer 3a: web app build artifacts exist"
else
  echo "  ⚠️  Layer 3a: web app build artifacts not found (run 'pnpm build' first)"
fi

# Check that core build artifacts exist
if [ -d "packages/core/dist" ]; then
  echo "  ✅ Layer 3b: core package build artifacts exist"
else
  echo "  ⚠️  Layer 3b: core package build artifacts not found"
fi

# Check that 3d-engine build artifacts exist
if [ -d "packages/3d-engine/dist" ]; then
  echo "  ✅ Layer 3c: 3d-engine package build artifacts exist"
else
  echo "  ⚠️  Layer 3c: 3d-engine package build artifacts not found"
fi

echo ""
echo "========================================"
if [ "$ERRORS" -eq 0 ]; then
  echo "✅ All required layers passed (0 errors)"
  echo "========================================"
  exit 0
else
  echo "❌ $ERRORS layer(s) FAILED"
  echo "========================================"
  echo ""
  echo "Do NOT declare completion. Fix failures first."
  echo "Layer 1 must pass before Layer 2."
  echo "Layer 2 must pass before Layer 3."
  exit 1
fi
