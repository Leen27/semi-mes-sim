#!/bin/bash
# Initialize Harness Engineering controls in the current project
# Usage: bash init-harness.sh

set -euo pipefail

echo "=== Harness Engineering Init ==="

# 1. Check prerequisites
if [ ! -f "package.json" ] && [ ! -f "Cargo.toml" ] && [ ! -f "go.mod" ]; then
  echo "Warning: No recognized project root detected (no package.json, Cargo.toml, go.mod)"
  read -p "Continue anyway? [y/N] " -n 1 -r
  echo
  [[ ! $REPLY =~ ^[Yy]$ ]] && exit 1
fi

# 2. Create feature_list.json if missing
if [ ! -f "feature_list.json" ]; then
  echo "Creating feature_list.json..."
  cp "$(dirname "$0")/../references/feature-list-template.json" feature_list.json
  echo "  -> Created feature_list.json (template)"
else
  echo "feature_list.json already exists — manual upgrade required"
  echo "  See: .agents/skills/harness-creator/references/feature-list-template.json"
fi

# 3. Check AGENTS.md
if [ -f "AGENTS.md" ]; then
  if grep -qi "wip.*=.*1\|WIP=1" AGENTS.md; then
    echo "AGENTS.md already has WIP=1 rules"
  else
    echo "AGENTS.md found but missing WIP=1 rules"
    echo "  Add rules from: .agents/skills/harness-creator/references/agents-rules.md"
  fi
else
  echo "AGENTS.md not found — create one and add WIP=1 rules"
  echo "  Template: .agents/skills/harness-creator/references/agents-rules.md"
fi

# 4. Validate JSON
echo ""
echo "Validating feature_list.json..."
if python3 -c "import json; json.load(open('feature_list.json'))" 2>/dev/null; then
  echo "  -> Valid JSON"
else
  echo "  -> Invalid JSON! Fix before continuing."
  exit 1
fi

# 5. Summary
echo ""
echo "=== Init Complete ==="
echo "Next steps:"
echo "  1. Fill in feature_list.json with real features and completionEvidence"
echo "  2. Add WIP=1 rules to AGENTS.md"
echo "  3. Update docs/workflow.md with WIP=1 execution flow"
echo "  4. Update PROGRESS.md with VCR tracking"
echo ""
echo "Run validation:"
echo "  bash .agents/skills/harness-creator/scripts/validate-harness.sh"
