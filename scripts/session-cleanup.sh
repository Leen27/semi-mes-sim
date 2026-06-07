#!/bin/bash
# Session Cleanup — Idempotent Entropy Reduction
# ===============================================
# Lecture 12: "Clean up later" means never clean up.
#
# This script performs idempotent cleanup operations that are safe
# to run repeatedly. It removes temporary artifacts, checks for
# common "AI slop" patterns, and verifies the repo remains healthy.
#
# Usage:
#   session-cleanup.sh [--dry-run]
#
# Options:
#   --dry-run   Show what would be done without making changes

set -uo pipefail

DRY_RUN=false
if [ "${1:-}" = "--dry-run" ]; then
  DRY_RUN=true
  echo "[DRY RUN] No changes will be made"
fi

CLEANED=0
WARNINGS=0

echo "========================================"
echo "Session Cleanup — Idempotent Operations"
echo "========================================"
echo ""

run_cmd() {
  if [ "$DRY_RUN" = true ]; then
    echo "  [would run] $*"
  else
    "$@"
  fi
}

# ============================================
# 1. Remove temporary files
# ============================================
echo "[1] Temporary file cleanup"
echo "--------------------------------------"

# Idempotent: -f ensures no error when files don't exist
for pattern in "*.tmp" "*.bak" "*.swp" "*~"; do
  FOUND=$(find . -maxdepth 3 -name "$pattern" 2>/dev/null | grep -v node_modules | grep -v dist | grep -v .git || true)
  if [ -n "$FOUND" ]; then
    echo "  Removing $pattern files:"
    echo "$FOUND" | while read -r f; do
      run_cmd rm -f "$f"
      CLEANED=$((CLEANED + 1))
      echo "    removed: $f"
    done
  fi
done

if [ "$CLEANED" -eq 0 ]; then
  echo "  ✅ No temporary files found"
fi

echo ""

# ============================================
# 2. Check for stale trace files (older than 30 days)
# ============================================
echo "[2] Stale trace cleanup"
echo "--------------------------------------"

if [ -d ".harness/traces" ]; then
  STALE_TRACES=$(find .harness/traces -name "*.json" -mtime +30 2>/dev/null || true)
  if [ -n "$STALE_TRACES" ]; then
    echo "  Removing traces older than 30 days:"
    echo "$STALE_TRACES" | while read -r f; do
      run_cmd rm -f "$f"
      echo "    removed: $f"
    done
  else
    echo "  ✅ No stale traces (>30 days)"
  fi
else
  echo "  ✅ No traces directory"
fi

echo ""

# ============================================
# 3. Check for debug code patterns
# ============================================
echo "[3] Debug code scan"
echo "--------------------------------------"

# Find console.log in non-test source
DEBUG_PATTERNS="console\.log\|console\.debug\|debugger;"
DEBUG_MATCHES=$(grep -rn "$DEBUG_PATTERNS" packages/*/src/ apps/*/src/ 2>/dev/null | grep -v "\.test\." | grep -v "\.spec\." | head -10 || true)

if [ -n "$DEBUG_MATCHES" ]; then
  echo "  ⚠️  Debug statements found in non-test source:"
  echo "$DEBUG_MATCHES" | while read -r line; do
    echo "    $line"
  done
  echo ""
  echo "  Action: Remove these before committing, or add // eslint-disable-next-line no-console with justification"
  WARNINGS=$((WARNINGS + 1))
else
  echo "  ✅ No debug statements in non-test source"
fi

echo ""

# ============================================
# 4. Check for empty directories
# ============================================
echo "[4] Empty directory cleanup"
echo "--------------------------------------"

EMPTY_DIRS=$(find packages/*/src apps/*/src -type d -empty 2>/dev/null || true)
if [ -n "$EMPTY_DIRS" ]; then
  echo "  Empty directories found:"
  echo "$EMPTY_DIRS" | while read -r d; do
    run_cmd rmdir "$d" 2>/dev/null || true
    echo "    removed: $d"
  done
else
  echo "  ✅ No empty source directories"
fi

echo ""

# ============================================
# 5. Verify cleanup didn't break anything
# ============================================
echo "[5] Post-cleanup verification"
echo "--------------------------------------"

if [ "$DRY_RUN" = true ]; then
  echo "  [dry-run] Skipping verification"
else
  if make check > /tmp/cleanup-verify.log 2>&1; then
    echo "  ✅ make check passes after cleanup"
  else
    echo "  ❌ make check FAILED after cleanup — investigate immediately"
    tail -5 /tmp/cleanup-verify.log | sed 's/^/    /'
    echo ""
    echo "  Cleanup should NEVER break the build. If it did,"
    echo "  something was deleted that shouldn't have been."
    exit 1
  fi
fi

echo ""

# ============================================
# Summary
# ============================================
echo "========================================"
if [ "$DRY_RUN" = true ]; then
  echo "[DRY RUN] Cleanup simulation complete"
  echo "========================================"
else
  if [ "$WARNINGS" -eq 0 ]; then
    echo "✅ Cleanup complete — repo is clean"
  else
    echo "⚠️  Cleanup complete — $WARNINGS warning(s) need attention"
  fi
  echo "========================================"
fi
