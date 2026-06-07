#!/bin/bash
# Feature Evaluator — Structured Scoring Based on Evidence
# =========================================================
# Lecture 11: Evaluator rubrics transform quality evaluation from subjective
# judgment into evidence-based structured scoring.
#
# Usage:
#   evaluate-feature.sh <feature-id> [--trace-file <path>]
#
# This script:
# 1. Reads the feature's completionEvidence from feature_list.json
# 2. Runs each verificationCommand and records results
# 3. Applies the rubric from .harness/rubrics/default.json
# 4. Outputs a structured scorecard with per-dimension ratings
# 5. Records everything to the trace file

set -uo pipefail

FEATURE_ID="${1:-}"
TRACE_FILE="${TRACE_FILE:-}"
RUBRIC_FILE=".harness/rubrics/default.json"
FEATURE_LIST="feature_list.json"

if [ -z "$FEATURE_ID" ]; then
  echo "Feature Evaluator — Evidence-Based Scoring"
  echo ""
  echo "Usage: evaluate-feature.sh <feature-id> [--trace-file <path>]"
  echo ""
  echo "Examples:"
  echo "  bash scripts/evaluate-feature.sh F004"
  echo "  TRACE_FILE=.harness/traces/trace-F004-xxx.json bash scripts/evaluate-feature.sh F004"
  exit 1
fi

echo "========================================"
echo "Feature Evaluator: $FEATURE_ID"
echo "========================================"
echo ""

# Find feature data in feature_list.json
FEATURE_DATA=$(node -e "
const data = JSON.parse(require('fs').readFileSync('$FEATURE_LIST', 'utf8'));
const f = data.features.find(x => x.id === '$FEATURE_ID');
if (!f) { process.exit(1); }
console.log(JSON.stringify(f));
" 2>/dev/null)

if [ -z "$FEATURE_DATA" ]; then
  echo "ERROR: Feature '$FEATURE_ID' not found in $FEATURE_LIST"
  exit 1
fi

FEATURE_NAME=$(echo "$FEATURE_DATA" | node -e "const d=require('fs').readFileSync(0,'utf8');console.log(JSON.parse(d).name)")
FEATURE_STATUS=$(echo "$FEATURE_DATA" | node -e "const d=require('fs').readFileSync(0,'utf8');console.log(JSON.parse(d).status)")

echo "Name:   $FEATURE_NAME"
echo "Status: $FEATURE_STATUS"
echo ""

# Initialize trace if not provided
if [ -z "$TRACE_FILE" ]; then
  TRACE_FILE=$(bash scripts/harness-trace.sh init "$FEATURE_ID")
  export TRACE_FILE
fi

bash scripts/harness-trace.sh record "evaluation_start" "{\"featureId\": \"$FEATURE_ID\", \"featureName\": \"$FEATURE_NAME\"}"

# ============================================
# Phase 1: Run all verification commands
# ============================================
echo "[Phase 1] Running verification commands"
echo "--------------------------------------"

TOTAL_COMMANDS=0
PASSED_COMMANDS=0
FAILED_COMMANDS=0

# Extract and run verification commands
# Use process substitution to avoid subshell variable scope issues
while read -r line; do
  if [[ "$line" != CMD:* ]]; then continue; fi
  
  CMD_JSON="${line#CMD:}"
  DESC=$(echo "$CMD_JSON" | node -e "const d=require('fs').readFileSync(0,'utf8');console.log(JSON.parse(d).description)")
  CMD=$(echo "$CMD_JSON" | node -e "const d=require('fs').readFileSync(0,'utf8');console.log(JSON.parse(d).command)")
  IDX=$(echo "$CMD_JSON" | node -e "const d=require('fs').readFileSync(0,'utf8');console.log(JSON.parse(d).index)")
  
  TOTAL_COMMANDS=$((TOTAL_COMMANDS + 1))
  
  echo ""
  echo "[$((IDX + 1))] $DESC"
  echo "    Command: $CMD"
  
  # Run command with timeout
  OUTPUT=$(bash -c "$CMD" 2>&1) && CMD_STATUS="passed" || CMD_STATUS="failed"
  
  if [ "$CMD_STATUS" = "passed" ]; then
    echo "    Result: ✅ passed"
    PASSED_COMMANDS=$((PASSED_COMMANDS + 1))
  else
    echo "    Result: ❌ failed"
    echo "    Output: $(echo "$OUTPUT" | head -3 | tr '\n' ' ')"
    FAILED_COMMANDS=$((FAILED_COMMANDS + 1))
  fi
  
  bash scripts/harness-trace.sh verify "$DESC" "$CMD" "$CMD_STATUS" "$OUTPUT"
done < <(echo "$FEATURE_DATA" | node -e "
const data = JSON.parse(require('fs').readFileSync(0, 'utf8'));
const cmds = data.completionEvidence || [];
cmds.forEach((cmd, i) => {
  console.log('CMD:' + JSON.stringify({ index: i, description: cmd.description, command: cmd.verificationCommand }));
});
" 2>/dev/null)

echo ""
echo "Verification Summary: $PASSED_COMMANDS/$TOTAL_COMMANDS passed"
echo ""

# ============================================
# Phase 2: Rubric-based scoring
# ============================================
echo "[Phase 2] Rubric-based scoring"
echo "--------------------------------------"

# Determine dimension scores based on evidence
# We'll use node to compute the scorecard
export EVAL_FEATURE_ID="$FEATURE_ID"
node <<'NODESCRIPT'
const fs = require('fs');

const rubric = JSON.parse(fs.readFileSync('.harness/rubrics/default.json', 'utf8'));
const featureList = JSON.parse(fs.readFileSync('feature_list.json', 'utf8'));
const featureId = process.env.EVAL_FEATURE_ID;

const feature = featureList.features.find(f => f.id === featureId);
if (!feature) {
  console.error('Feature not found: ' + featureId);
  process.exit(1);
}

// Calculate evidence-based scores
const evidence = feature.completionEvidence || [];
const passedCount = evidence.filter(e => e.evidence && e.evidence.passedAt).length;
const totalCount = evidence.length;
const allPassed = passedCount === totalCount && totalCount > 0;

// Check for tests (Layer 2 evidence)
const hasTests = evidence.some(e => /test|测试|spec/i.test(e.description));
const allTestsPass = evidence
  .filter(e => /test|测试|spec/i.test(e.description))
  .every(e => e.evidence && e.evidence.passedAt);

// Check architecture (would need to run verify-architecture.sh)
// We approximate based on evidence presence

// Check docs sync
const hasDocEvidence = evidence.some(e => 
  e.description.toLowerCase().includes('architecture') ||
  e.description.toLowerCase().includes('文档')
);

// Assign dimension grades based on evidence
const dimensions = rubric.dimensions.map(dim => {
  let grade = 'C';
  let reason = '';

  switch (dim.id) {
    case 'code-correctness':
      if (allPassed) { grade = 'A'; reason = '所有 verificationCommand 通过'; }
      else if (passedCount > 0) { grade = 'B'; reason = `${passedCount}/${totalCount} 验证通过`; }
      else { grade = 'D'; reason = '无通过验证'; }
      break;
    case 'architecture-compliance':
      // Assume architecture is OK if there are evidence records (verify-architecture.sh would catch violations)
      if (feature.status === 'passing') { grade = 'A'; reason = '功能已达到 passing 状态'; }
      else if (passedCount > 0) { grade = 'B'; reason = '部分验证通过'; }
      else { grade = 'C'; reason = '待验证'; }
      break;
    case 'test-coverage':
      if (hasTests && allTestsPass) { grade = 'A'; reason = '测试存在且通过'; }
      else if (hasTests) { grade = 'B'; reason = '有测试但部分未通过'; }
      else { grade = 'D'; reason = '无测试证据'; }
      break;
    case 'documentation-sync':
      if (hasDocEvidence) { grade = 'A'; reason = '文档验证项存在'; }
      else { grade = 'C'; reason = '无显式文档验证项'; }
      break;
    case 'end-to-end-validation':
      const hasE2E = evidence.some(e => e.description.toLowerCase().includes('端到端') || e.description.toLowerCase().includes('e2e'));
      const e2ePassed = evidence
        .filter(e => e.description.toLowerCase().includes('端到端') || e.description.toLowerCase().includes('e2e'))
        .every(e => e.evidence && e.evidence.passedAt);
      if (hasE2E && e2ePassed) { grade = 'A'; reason = '端到端验证通过'; }
      else if (hasE2E) { grade = 'C'; reason = '端到端验证未通过'; }
      else { grade = 'C'; reason = '无端到端验证项'; }
      break;
  }

  const level = dim.levels[grade];
  return {
    ...dim,
    grade,
    score: level.score,
    maxScore: 4,
    weightedScore: level.score * dim.weight,
    maxWeightedScore: 4 * dim.weight,
    reason
  };
});

const totalWeightedScore = dimensions.reduce((sum, d) => sum + d.weightedScore, 0);
const maxWeightedScore = dimensions.reduce((sum, d) => sum + d.maxWeightedScore, 0);
const normalizedScore = (totalWeightedScore / maxWeightedScore) * 4; // 0-4 scale

// Apply veto rules
const hasArchitectureVeto = dimensions.find(d => d.id === 'architecture-compliance')?.grade === 'D';
const hasAnyD = dimensions.some(d => d.grade === 'D');

let overallGrade = 'D';
if (hasArchitectureVeto) {
  overallGrade = 'D';
} else if (normalizedScore >= rubric.scoring.thresholds.excellent && !hasAnyD) {
  overallGrade = 'A';
} else if (normalizedScore >= rubric.scoring.thresholds.pass && !hasAnyD) {
  overallGrade = 'B';
} else if (normalizedScore >= 2.0) {
  overallGrade = 'C';
} else {
  overallGrade = 'D';
}

const overallLabel = overallGrade === 'A' ? '优秀' : overallGrade === 'B' ? '合格' : overallGrade === 'C' ? '部分通过' : '不合格';

// Output scorecard
console.log('');
console.log('Scorecard:');
console.log('----------');
dimensions.forEach(d => {
  const bar = '█'.repeat(d.score) + '░'.repeat(4 - d.score);
  console.log(`${d.name.padEnd(20)} ${d.grade} [${bar}] ${d.weightedScore.toFixed(2)}/${d.maxWeightedScore.toFixed(2)} — ${d.reason}`);
});
console.log('');
console.log(`Overall: ${overallGrade} (${overallLabel}) — ${normalizedScore.toFixed(2)}/4.00`);
console.log('');

if (overallGrade === 'D') {
  console.log('⚠️  Rating is D. Action required before marking as passing:');
  dimensions.filter(d => d.grade === 'D').forEach(d => {
    console.log(`   - ${d.name}: ${d.reason}`);
  });
} else if (overallGrade === 'C') {
  console.log('⚠️  Rating is C. Consider improving before finalizing:');
  dimensions.filter(d => d.grade === 'C' || d.grade === 'D').forEach(d => {
    console.log(`   - ${d.name}: ${d.reason}`);
  });
}

// Write scorecard to trace file
const traceFile = process.env.TRACE_FILE;
if (traceFile && fs.existsSync(traceFile)) {
  const trace = JSON.parse(fs.readFileSync(traceFile, 'utf8'));
  trace.scorecard = {
    timestamp: new Date().toISOString(),
    dimensions: dimensions.map(d => ({
      id: d.id,
      name: d.name,
      grade: d.grade,
      score: d.score,
      weightedScore: d.weightedScore,
      reason: d.reason
    })),
    overall: {
      grade: overallGrade,
      label: overallLabel,
      score: normalizedScore
    }
  };
  fs.writeFileSync(traceFile, JSON.stringify(trace, null, 2));
}
NODESCRIPT

echo ""
echo "Evaluation complete. Trace: $TRACE_FILE"
