#!/bin/bash
# Validate Harness Engineering controls in the current project
# Usage: bash validate-harness.sh

set -uo pipefail

ERRORS=0

echo "=== Harness Validation ==="
echo ""

# 1. feature_list.json exists and is valid JSON
echo "[1/7] Checking feature_list.json..."
if [ ! -f "feature_list.json" ]; then
  echo "  FAIL: feature_list.json not found"
  ERRORS=$((ERRORS + 1))
else
  if python3 -c "import json; json.load(open('feature_list.json'))" 2>/dev/null; then
    echo "  PASS: Valid JSON"
  else
    echo "  FAIL: Invalid JSON"
    ERRORS=$((ERRORS + 1))
  fi
fi

# 2. WIP limit = 1
echo "[2/7] Checking WIP limit..."
if [ -f "feature_list.json" ]; then
  WIP=$(python3 -c "import json; d=json.load(open('feature_list.json')); print(d.get('scopeSurface',{}).get('wipLimit','MISSING'))")
  if [ "$WIP" = "1" ]; then
    echo "  PASS: wipLimit = 1"
  else
    echo "  FAIL: wipLimit = $WIP (expected 1)"
    ERRORS=$((ERRORS + 1))
  fi
else
  echo "  SKIP: feature_list.json missing"
fi

# 3. Active task count <= 1
echo "[3/7] Checking active task count..."
if [ -f "feature_list.json" ]; then
  ACTIVE=$(python3 -c "import json; d=json.load(open('feature_list.json')); print(sum(1 for f in d.get('features',[]) if f.get('status')=='active'))")
  if [ "$ACTIVE" -le 1 ]; then
    echo "  PASS: $ACTIVE active task(s)"
  else
    echo "  FAIL: $ACTIVE active tasks (max 1)"
    ERRORS=$((ERRORS + 1))
  fi
else
  echo "  SKIP: feature_list.json missing"
fi

# 4. Every feature has completionEvidence
echo "[4/7] Checking completion evidence..."
if [ -f "feature_list.json" ]; then
  MISSING=$(python3 -c "
import json
d=json.load(open('feature_list.json'))
for f in d.get('features',[]):
    if not f.get('completionEvidence'):
        print(f['id'])
")
  if [ -z "$MISSING" ]; then
    echo "  PASS: All features have completionEvidence"
  else
    echo "  FAIL: Missing completionEvidence for: $MISSING"
    ERRORS=$((ERRORS + 1))
  fi
else
  echo "  SKIP: feature_list.json missing"
fi

# 5. AGENTS.md mentions WIP=1
echo "[5/7] Checking AGENTS.md for WIP=1..."
if [ -f "AGENTS.md" ]; then
  if grep -qi "wip.*=.*1\|WIP=1" AGENTS.md; then
    echo "  PASS: WIP=1 mentioned"
  else
    echo "  FAIL: WIP=1 not found in AGENTS.md"
    ERRORS=$((ERRORS + 1))
  fi
else
  echo "  SKIP: AGENTS.md not found"
fi

# 6. AGENTS.md mentions completion evidence
echo "[6/7] Checking AGENTS.md for completion evidence..."
if [ -f "AGENTS.md" ]; then
  if grep -qi "completion evidence\|verificationCommand" AGENTS.md; then
    echo "  PASS: Completion evidence mentioned"
  else
    echo "  FAIL: Completion evidence not found in AGENTS.md"
    ERRORS=$((ERRORS + 1))
  fi
else
  echo "  SKIP: AGENTS.md not found"
fi

# 7. AGENTS.md mentions VCR
echo "[7/7] Checking AGENTS.md for VCR..."
if [ -f "AGENTS.md" ]; then
  if grep -qi "VCR\|Verified Completion Rate" AGENTS.md; then
    echo "  PASS: VCR mentioned"
  else
    echo "  FAIL: VCR not found in AGENTS.md"
    ERRORS=$((ERRORS + 1))
  fi
else
  echo "  SKIP: AGENTS.md not found"
fi

echo ""
if [ "$ERRORS" -eq 0 ]; then
  echo "=== All checks passed ==="
  exit 0
else
  echo "=== $ERRORS check(s) failed ==="
  exit 1
fi
