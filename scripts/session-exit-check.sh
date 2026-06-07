#!/bin/bash
# Session Exit Checklist — Five Dimensions of Clean State
# ========================================================
# Lecture 12: Leave a Clean Handoff at the End of Every Session
#
# A session is NOT "done" until all five dimensions pass.
# Missing any one means the next session will spend time fixing
# instead of building.
#
# Usage:
#   session-exit-check.sh [feature-id]
#
# Exit code 0 = all dimensions clean
# Exit code 1 = one or more dimensions failed

set -uo pipefail

FEATURE_ID="${1:-}"
ERRORS=0
WARNINGS=0

echo "========================================"
echo "Session Exit Checklist — Clean State"
echo "========================================"
if [ -n "$FEATURE_ID" ]; then
  echo "Feature: $FEATURE_ID"
fi
echo ""
echo "Session completion = task passes verification AND clean state check passes"
echo ""

# Color helpers
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

report_ok() {
  echo -e "  ${GREEN}✅${NC} $1"
}

report_fail() {
  echo -e "  ${RED}❌${NC} $1"
  ERRORS=$((ERRORS + 1))
}

report_warn() {
  echo -e "  ${YELLOW}⚠️${NC} $1"
  WARNINGS=$((WARNINGS + 1))
}

# ============================================
# Dimension 1: Build passes
# ============================================
echo "[Dimension 1] Build passes"
echo "--------------------------------------"

if make build > /tmp/exit-build.log 2>&1; then
  report_ok "Build passes (make build)"
else
  report_fail "Build FAILED — run 'make build' and fix errors before exiting"
  echo "    Output: $(tail -2 /tmp/exit-build.log)"
fi

echo ""

# ============================================
# Dimension 2: Tests pass
# ============================================
echo "[Dimension 2] Tests pass"
echo "--------------------------------------"

if make test > /tmp/exit-test.log 2>&1; then
  report_ok "All tests pass (make test)"
else
  report_fail "Tests FAILED — run 'make test' and fix failures before exiting"
  echo "    Output: $(tail -2 /tmp/exit-test.log)"
fi

echo ""

# ============================================
# Dimension 3: Progress recorded
# ============================================
echo "[Dimension 3] Progress recorded"
echo "--------------------------------------"

# 3a: feature_list.json exists and is valid JSON
if node -e "JSON.parse(require('fs').readFileSync('feature_list.json', 'utf8'))" 2>/dev/null; then
  report_ok "feature_list.json is valid JSON"
else
  report_fail "feature_list.json is malformed or missing"
fi

# 3b: PROGRESS.md has been updated recently (within last 7 days)
if [ -f "PROGRESS.md" ]; then
  MTIME=$(stat -f %m "PROGRESS.md" 2>/dev/null || stat -c %Y "PROGRESS.md" 2>/dev/null || echo 0)
  NOW=$(date +%s)
  AGE_DAYS=$(( (NOW - MTIME) / 86400 ))
  if [ "$AGE_DAYS" -le 7 ]; then
    report_ok "PROGRESS.md updated within last $AGE_DAYS day(s)"
  else
    report_warn "PROGRESS.md last updated $AGE_DAYS days ago — consider updating"
  fi
else
  report_fail "PROGRESS.md missing"
fi

# 3c: If feature-id provided, check its status is consistent
if [ -n "$FEATURE_ID" ]; then
  FEATURE_STATUS=$(node -e "
    const data = JSON.parse(require('fs').readFileSync('feature_list.json', 'utf8'));
    const f = data.features.find(x => x.id === '$FEATURE_ID');
    console.log(f ? f.status : 'NOT_FOUND');
  " 2>/dev/null)
  
  if [ "$FEATURE_STATUS" = "NOT_FOUND" ]; then
    report_fail "Feature '$FEATURE_ID' not found in feature_list.json"
  elif [ "$FEATURE_STATUS" = "active" ]; then
    report_warn "Feature '$FEATURE_ID' is still 'active' — did you forget to mark it passing?"
  else
    report_ok "Feature '$FEATURE_ID' status in feature_list.json: $FEATURE_STATUS"
  fi
fi

# 3d: Check that activeFeatureId is consistent with actual active features
ACTIVE_COUNT=$(node -e "
  const data = JSON.parse(require('fs').readFileSync('feature_list.json', 'utf8'));
  const count = data.features.filter(f => f.status === 'active').length;
  console.log(count);
" 2>/dev/null)
if [ "$ACTIVE_COUNT" = "0" ] || [ "$ACTIVE_COUNT" = "1" ]; then
  report_ok "WIP=1 respected: $ACTIVE_COUNT active feature(s)"
else
  report_fail "WIP=1 violated: $ACTIVE_COUNT active features found (must be ≤ 1)"
fi

echo ""

# ============================================
# Dimension 4: No stale artifacts
# ============================================
echo "[Dimension 4] No stale artifacts"
echo "--------------------------------------"

# 4a: Check for temporary files
TEMP_FILES=$(find . -maxdepth 2 -name "*.tmp" -o -name "*.log" -o -name "*.bak" 2>/dev/null | grep -v node_modules | grep -v dist | head -10)
if [ -z "$TEMP_FILES" ]; then
  report_ok "No temporary files (*.tmp, *.log, *.bak) in repo root"
else
  report_warn "Temporary files found:"
  echo "$TEMP_FILES" | sed 's/^/    /'
fi

# 4b: Check for debug console.log in source (allow in tests)
DEBUG_LOGS=$(grep -rn "console\.log\|console\.debug\|console\.warn" packages/*/src/ apps/*/src/ 2>/dev/null | grep -v "\.test\." | grep -v "\.spec\." | head -10)
if [ -z "$DEBUG_LOGS" ]; then
  report_ok "No debug console statements in non-test source"
else
  report_warn "Debug console statements found in non-test source:"
  echo "$DEBUG_LOGS" | head -5 | sed 's/^/    /'
fi

# 4c: Check for TODO(Fxxx) markers that should have been resolved
UNRESOLVED_TODOS=$(grep -rn "TODO(F[0-9]\+)" packages/*/src/ apps/*/src/ 2>/dev/null | head -10)
if [ -z "$UNRESOLVED_TODOS" ]; then
  report_ok "No unresolved TODO(Fxxx) markers in source"
else
  report_warn "Unresolved TODO(Fxxx) markers found:"
  echo "$UNRESOLVED_TODOS" | head -5 | sed 's/^/    /'
fi

# 4d: Check for uncommitted changes
if git diff-index --quiet HEAD -- 2>/dev/null; then
  report_ok "No uncommitted changes"
else
  report_warn "Uncommitted changes present — remember to commit before exiting"
  git status --short | head -5 | sed 's/^/    /'
fi

echo ""

# ============================================
# Dimension 5: Startup path available
# ============================================
echo "[Dimension 5] Startup path available"
echo "--------------------------------------"

# 5a: make check works
if make check > /tmp/exit-check.log 2>&1; then
  report_ok "Standard check path works (make check)"
else
  report_fail "make check FAILED — the next session cannot start cleanly"
  echo "    Output: $(tail -2 /tmp/exit-check.log)"
fi

# 5b: Key config files exist
if [ -f "package.json" ] && [ -f "pnpm-workspace.yaml" ] && [ -f "tsconfig.json" ]; then
  report_ok "Key config files present (package.json, pnpm-workspace.yaml, tsconfig.json)"
else
  report_fail "Missing key config files"
fi

# 5c: Node modules exist (basic sanity)
if [ -d "node_modules" ] && [ -d "node_modules/.pnpm" ]; then
  report_ok "Dependencies installed (node_modules present)"
else
  report_warn "node_modules missing or incomplete — run 'make setup'"
fi

echo ""

# ============================================
# Summary
# ============================================
echo "========================================"
if [ "$ERRORS" -eq 0 ] && [ "$WARNINGS" -eq 0 ]; then
  echo -e "${GREEN}✅ All 5 dimensions clean — session can exit${NC}"
  echo "========================================"
  echo ""
  echo "Next session will be able to start immediately without cleanup."
  exit 0
elif [ "$ERRORS" -eq 0 ]; then
  echo -e "${YELLOW}⚠️  $WARNINGS warning(s) — session can exit but consider fixing warnings${NC}"
  echo "========================================"
  exit 0
else
  echo -e "${RED}❌ $ERRORS error(s), $WARNINGS warning(s) — DO NOT EXIT${NC}"
  echo "========================================"
  echo ""
  echo "Fix the errors above before ending the session."
  echo "'Clean up later' means never clean up."
  echo ""
  echo "Entropy growth is the default state."
  echo "Only active cleanup counteracts it."
  exit 1
fi
