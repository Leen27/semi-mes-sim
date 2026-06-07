#!/bin/bash
# Architecture Boundary Enforcement
# ==================================
# Lecture 10: Only a Full Pipeline Run Counts as Real Verification
# 
# This script turns architectural rules from AGENTS.md into executable checks.
# Every failure message includes: WHAT went wrong, WHY it matters, and HOW to fix it.
# This creates a self-correcting feedback loop for agents.
#
# Usage: bash scripts/verify-architecture.sh

set -uo pipefail

ERRORS=0
WARNINGS=0

# Color helpers (safe for CI)
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo "========================================"
echo "Architecture Boundary Enforcement"
echo "========================================"
echo ""

# --- Helper functions ---

report_error() {
  local what="$1"
  local why="$2"
  local fix="$3"
  ERRORS=$((ERRORS + 1))
  echo -e "${RED}ERROR:${NC} $what"
  echo "  WHY: $why"
  echo "  FIX: $fix"
  echo ""
}

report_ok() {
  echo -e "  ${GREEN}✅${NC} $1"
}

# ============================================
# RULE 1: @semi/core must be pure TypeScript
# No Vue, Babylon.js, Pinia, or other UI libs
# ============================================
echo "[Rule 1] @semi/core purity check"
echo "--------------------------------------"

CORE_DEPS=$(cat packages/core/package.json | grep -oE '"[^"]+"' | tr -d '"' | grep -vE '^[{}:,]*$' || true)

if echo "$CORE_DEPS" | grep -qE '^vue$'; then
  report_error \
    "Found 'vue' in packages/core/package.json dependencies" \
    "@semi/core must be pure TypeScript. UI dependencies violate the domain layer isolation." \
    "Remove 'vue' from packages/core/package.json dependencies. If you need types, use 'devDependencies' or import types only."
else
  report_ok "No Vue dependency in @semi/core"
fi

if echo "$CORE_DEPS" | grep -qE '^@babylonjs'; then
  report_error \
    "Found Babylon.js in packages/core/package.json dependencies" \
    "@semi/core must be pure TypeScript. 3D engine dependencies belong in @semi/3d-engine." \
    "Remove all '@babylonjs/*' packages from packages/core/package.json. Core should only export types consumed by 3d-engine."
else
  report_ok "No Babylon.js dependency in @semi/core"
fi

if echo "$CORE_DEPS" | grep -qE '^pinia$'; then
  report_error \
    "Found 'pinia' in packages/core/package.json dependencies" \
    "@semi/core must be pure TypeScript. State management belongs in apps/web." \
    "Remove 'pinia' from packages/core/package.json. Core emits events; consumers manage state."
else
  report_ok "No Pinia dependency in @semi/core"
fi

# Also check actual import statements in core source
if grep -r "from 'vue'" packages/core/src/ 2>/dev/null; then
  report_error \
    "Found 'import from vue' in packages/core/src/" \
    "@semi/core must be pure TypeScript. UI imports violate layer boundaries." \
    "Move Vue-related logic to apps/web or packages/ui. Core should only use plain TypeScript."
else
  report_ok "No Vue imports in @semi/core source"
fi

if grep -r "from '@babylonjs" packages/core/src/ 2>/dev/null; then
  report_error \
    "Found Babylon.js imports in packages/core/src/" \
    "@semi/core must be pure TypeScript. 3D engine imports belong in @semi/3d-engine." \
    "Move Babylon.js usage to packages/3d-engine. Core should define types, not use 3D APIs."
else
  report_ok "No Babylon.js imports in @semi/core source"
fi

echo ""

# ============================================
# RULE 2: @semi/3d-engine must not depend on Vue
# ============================================
echo "[Rule 2] @semi/3d-engine Vue isolation check"
echo "--------------------------------------"

ENGINE_DEPS=$(cat packages/3d-engine/package.json | grep -oE '"[^"]+"' | tr -d '"' | grep -vE '^[{}:,]*$' || true)

if echo "$ENGINE_DEPS" | grep -qE '^vue$'; then
  report_error \
    "Found 'vue' in packages/3d-engine/package.json dependencies" \
    "@semi/3d-engine must not depend on Vue. It is a pure Babylon.js + TypeScript layer." \
    "Remove 'vue' from packages/3d-engine/package.json. If UI integration is needed, use callbacks/events and let apps/web handle Vue."
else
  report_ok "No Vue dependency in @semi/3d-engine"
fi

if grep -r "from 'vue'" packages/3d-engine/src/ 2>/dev/null; then
  report_error \
    "Found 'import from vue' in packages/3d-engine/src/" \
    "@semi/3d-engine must not import Vue. It should be a pure rendering layer." \
    "Remove Vue imports from 3d-engine. Expose imperative APIs (play/pause/stop) and let the Vue app in apps/web call them."
else
  report_ok "No Vue imports in @semi/3d-engine source"
fi

echo ""

# ============================================
# RULE 3: @semi/ui must not depend on apps/web
# ============================================
echo "[Rule 3] @semi/ui dependency direction check"
echo "--------------------------------------"

UI_DEPS=$(cat packages/ui/package.json | grep -oE '"[^"]+"' | tr -d '"' | grep -vE '^[{}:,]*$' || true)

if echo "$UI_DEPS" | grep -qE '^@semi/web'; then
  report_error \
    "Found '@semi/web' in packages/ui/package.json dependencies" \
    "@semi/ui must not depend on apps/web. UI is a reusable library consumed by web, not the other way around." \
    "Remove '@semi/web' from packages/ui/package.json. If UI needs web-specific data, accept it via props."
else
  report_ok "No apps/web dependency in @semi/ui"
fi

if grep -r "from '@semi/web'" packages/ui/src/ 2>/dev/null; then
  report_error \
    "Found imports from '@semi/web' in packages/ui/src/" \
    "@semi/ui must not import from apps/web. This creates a circular dependency." \
    "Move shared types to @semi/core and import from there. UI components receive data via props."
else
  report_ok "No apps/web imports in @semi/ui source"
fi

echo ""

# ============================================
# RULE 4: Local workspace refs must use workspace:*
# ============================================
echo "[Rule 4] Workspace protocol check"
echo "--------------------------------------"

for pkg in packages/*/package.json apps/web/package.json; do
  # Find local workspace refs without workspace:*
  # This grep looks for @semi/ references in dependencies that don't use workspace:*
  bad_refs=$(cat "$pkg" | grep -E '"@semi/[^"]+":\s*"[^(workspace)]' || true)
  if [ -n "$bad_refs" ]; then
    report_error \
      "Found non-workspace reference in $pkg" \
      "All local @semi/* dependencies must use 'workspace:*' protocol to ensure monorepo consistency." \
      "Change the dependency to use 'workspace:*'. Example: \"@semi/core\": \"workspace:*\""
    echo "  Found: $bad_refs"
  fi
done

if [ "$ERRORS" -eq 0 ]; then
  report_ok "All workspace references use workspace:* protocol"
fi

echo ""

# ============================================
# RULE 5: No external .glb/.gltf files
# ============================================
echo "[Rule 5] External 3D model file check"
echo "--------------------------------------"

GLB_FILES=$(find packages/3d-engine/src -name "*.glb" -o -name "*.gltf" 2>/dev/null || true)
if [ -n "$GLB_FILES" ]; then
  report_error \
    "Found external 3D model files in packages/3d-engine/src/" \
    "Device models must use MeshBuilder basic geometries. External files increase bundle size and break self-containment." \
    "Remove .glb/.gltf files and recreate the model using MeshBuilder (Box, Cylinder, Sphere, etc.) in TypeScript code."
  echo "  Files: $GLB_FILES"
else
  report_ok "No external .glb/.gltf files in 3d-engine"
fi

echo ""

# ============================================
# RULE 6: All 3D meshes must have name property
# (Static check: grep for Create calls where first arg is clearly missing)
# ============================================
echo "[Rule 6] 3D object naming check (heuristic)"
echo "--------------------------------------"

# Heuristic: find Create* calls where the first argument is directly an object literal (no name)
# This catches the most obvious violations: CreateBox({ width: ... }) without a name string.
# Multi-line calls and template-string names require runtime tests for full validation.
BAD_NAMES=$(grep -rnE "Create(Box|Sphere|Cylinder|Lines|Ground|Plane)\s*\(\s*\{" packages/3d-engine/src/ || true)

if [ -n "$BAD_NAMES" ]; then
  report_error \
    "Found MeshBuilder calls with object literal as first argument (missing name)" \
    "All 3D objects must have a 'name' property for debugging, ray-picking, and scene traversal." \
    "Add a string name as the first argument. Example: MeshBuilder.CreateBox('body', { width: 4, ... }, scene). For dynamic names, use template literals: \`lot-\${lotId}\`."
  echo "  Lines:"
  echo "$BAD_NAMES" | head -5 | sed 's/^/    /'
else
  report_ok "No obvious missing-name MeshBuilder calls found"
fi

echo ""

# ============================================
# RULE 7: tsconfig paths must point to dist/ or index.d.ts
# ============================================
echo "[Rule 7] TypeScript paths target check"
echo "--------------------------------------"

# Only check compilerOptions.paths, not include/exclude
PATHS_WITH_SRC=$(grep -A5 '"paths"' tsconfig.json apps/*/tsconfig.json packages/*/tsconfig.json 2>/dev/null | grep '"src/' || true)
if [ -n "$PATHS_WITH_SRC" ]; then
  report_error \
    "Found tsconfig compilerOptions.paths pointing to 'src/' directories" \
    "TypeScript paths must point to 'dist/' or 'index.d.ts' to enforce build artifact boundaries." \
    "Change paths in tsconfig.json compilerOptions.paths to point to './dist/index.js' or './index.d.ts', not './src/'."
  echo "  Found: $PATHS_WITH_SRC"
else
  report_ok "No tsconfig paths pointing to src/"
fi

echo ""

# ============================================
# Summary
# ============================================
echo "========================================"
if [ "$ERRORS" -eq 0 ]; then
  echo -e "${GREEN}✅ All architecture boundary checks passed${NC}"
  echo "========================================"
  exit 0
else
  echo -e "${RED}❌ $ERRORS architecture boundary violation(s) found${NC}"
  echo "========================================"
  echo ""
  echo "Architectural rules are not 'suggestions'. They are enforced invariants."
  echo "Do NOT bypass these checks. Fix the root cause instead."
  echo ""
  echo "If a rule genuinely needs to change:"
  echo "  1. Update AGENTS.md with the new rule and justification"
  echo "  2. Update this script (scripts/verify-architecture.sh)"
  echo "  3. Record the decision in DECISIONS.md"
  exit 1
fi
