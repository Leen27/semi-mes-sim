#!/bin/bash
# Harness Trace Recorder
# =======================
# Making the Agent's Runtime Observable
#
# Records structured task traces for every agent session.
# Each trace is a JSON file in .harness/traces/ that captures:
# - Session lifecycle (start, events, end)
# - Validation layer results (Layer 0-3)
# - Feature-level verification commands
# - Errors and decisions
#
# Usage:
#   harness-trace.sh init <feature-id>     # Start a new trace for a feature
#   harness-trace.sh record <event> [data] # Record an event
#   harness-trace.sh layer <n> <status>    # Record layer validation result
#   harness-trace.sh finalize              # End trace and output summary

set -uo pipefail

TRACE_DIR=".harness/traces"
TRACE_FILE=""
FEATURE_ID=""

# Initialize trace directory
mkdir -p "$TRACE_DIR"

# Get current ISO timestamp
iso_timestamp() {
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

# Generate trace filename
trace_filename() {
  local fid="${1:-unknown}"
  local ts=$(date -u +"%Y%m%d-%H%M%S")
  echo "${TRACE_DIR}/trace-${fid}-${ts}.json"
}

# Initialize a new trace
init_trace() {
  FEATURE_ID="${1:-unknown}"
  TRACE_FILE=$(trace_filename "$FEATURE_ID")

  cat > "$TRACE_FILE" <<EOF
{
  "traceVersion": "1.0.0",
  "featureId": "$FEATURE_ID",
  "startedAt": "$(iso_timestamp)",
  "endedAt": null,
  "status": "running",
  "sessionInfo": {
    "pwd": "$(pwd)",
    "gitBranch": "$(git branch --show-current 2>/dev/null || echo 'unknown')",
    "gitCommit": "$(git rev-parse --short HEAD 2>/dev/null || echo 'unknown')"
  },
  "events": [],
  "layers": {
    "layer0": { "name": "Architecture Boundaries", "status": "pending", "details": null, "durationMs": null },
    "layer1": { "name": "Syntax & Static Analysis", "status": "pending", "details": null, "durationMs": null },
    "layer2": { "name": "Runtime Behavior", "status": "pending", "details": null, "durationMs": null },
    "layer3": { "name": "System-Level Integration", "status": "pending", "details": null, "durationMs": null }
  },
  "verificationCommands": [],
  "errors": [],
  "summary": null
}
EOF

  echo "$TRACE_FILE"
}

# Record an event in the trace
record_event() {
  local event_type="$1"
  local event_data="${2:-}"
  if [ -z "$event_data" ]; then event_data="{}"; fi
  local trace_file="${TRACE_FILE:-$(ls -t ${TRACE_DIR}/trace-*.json 2>/dev/null | head -1)}"

  if [ -z "$trace_file" ] || [ ! -f "$trace_file" ]; then
    echo "No trace file found. Run 'init' first." >&2
    return 1
  fi

  # Use a temp file for atomic update
  local tmp_file="${trace_file}.tmp"

  # Read current events array, append new event
  node -e "
const fs = require('fs');
const data = JSON.parse(fs.readFileSync('$trace_file', 'utf8'));
data.events.push({
  timestamp: '$(iso_timestamp)',
  type: '$event_type',
  data: $event_data
});
fs.writeFileSync('$tmp_file', JSON.stringify(data, null, 2));
" 2>/dev/null || {
    # Fallback if node is not available (shouldn't happen in this project)
    echo "Warning: node not available for trace recording" >&2
    return 0
  }

  mv "$tmp_file" "$trace_file"
}

# Record layer validation result
record_layer() {
  local layer_num="$1"
  local layer_status="$2"
  local layer_details="${3:-null}"
  local duration_ms="${4:-null}"
  local trace_file="${TRACE_FILE:-$(ls -t ${TRACE_DIR}/trace-*.json 2>/dev/null | head -1)}"

  if [ -z "$trace_file" ] || [ ! -f "$trace_file" ]; then
    echo "No trace file found. Run 'init' first." >&2
    return 1
  fi

  local tmp_file="${trace_file}.tmp"

  node -e "
const fs = require('fs');
const data = JSON.parse(fs.readFileSync('$trace_file', 'utf8'));
data.layers['layer${layer_num}'] = {
  name: data.layers['layer${layer_num}'].name,
  status: '$layer_status',
  details: ${layer_details},
  durationMs: ${duration_ms}
};
fs.writeFileSync('$tmp_file', JSON.stringify(data, null, 2));
" 2>/dev/null || true

  if [ -f "$tmp_file" ]; then
    mv "$tmp_file" "$trace_file"
  fi
}

# Record a verification command result
record_verification() {
  local description="$1"
  local command="$2"
  local status="$3"
  local output="${4:-}"
  local trace_file="${TRACE_FILE:-$(ls -t ${TRACE_DIR}/trace-*.json 2>/dev/null | head -1)}"

  if [ -z "$trace_file" ] || [ ! -f "$trace_file" ]; then
    return 1
  fi

  local tmp_file="${trace_file}.tmp"
  local safe_desc=$(echo "$description" | sed 's/"/\\"/g')
  local safe_cmd=$(echo "$command" | sed 's/"/\\"/g')
  local safe_out=$(echo "$output" | sed 's/"/\\"/g' | head -c 2000)

  node -e "
const fs = require('fs');
const data = JSON.parse(fs.readFileSync('$trace_file', 'utf8'));
data.verificationCommands.push({
  timestamp: '$(iso_timestamp)',
  description: '$safe_desc',
  command: '$safe_cmd',
  status: '$status',
  output: '$safe_out'
});
fs.writeFileSync('$tmp_file', JSON.stringify(data, null, 2));
" 2>/dev/null || true

  if [ -f "$tmp_file" ]; then
    mv "$tmp_file" "$trace_file"
  fi
}

# Record an error
record_error() {
  local error_msg="$1"
  local error_context="${2:-}"
  local trace_file="${TRACE_FILE:-$(ls -t ${TRACE_DIR}/trace-*.json 2>/dev/null | head -1)}"

  if [ -z "$trace_file" ] || [ ! -f "$trace_file" ]; then
    return 1
  fi

  local tmp_file="${trace_file}.tmp"
  local safe_msg=$(echo "$error_msg" | sed 's/"/\\"/g' | head -c 1000)
  local safe_ctx=$(echo "$error_context" | sed 's/"/\\"/g' | head -c 1000)

  node -e "
const fs = require('fs');
const data = JSON.parse(fs.readFileSync('$trace_file', 'utf8'));
data.errors.push({
  timestamp: '$(iso_timestamp)',
  message: '$safe_msg',
  context: '$safe_ctx'
});
fs.writeFileSync('$tmp_file', JSON.stringify(data, null, 2));
" 2>/dev/null || true

  if [ -f "$tmp_file" ]; then
    mv "$tmp_file" "$trace_file"
  fi
}

# Finalize trace
finalize_trace() {
  local final_status="${1:-completed}"
  local trace_file="${TRACE_FILE:-$(ls -t ${TRACE_DIR}/trace-*.json 2>/dev/null | head -1)}"

  if [ -z "$trace_file" ] || [ ! -f "$trace_file" ]; then
    echo "No trace file found." >&2
    return 1
  fi

  local tmp_file="${trace_file}.tmp"

  # Count pass/fail per layer
  node -e "
const fs = require('fs');
const data = JSON.parse(fs.readFileSync('$trace_file', 'utf8'));
data.endedAt = '$(iso_timestamp)';
data.status = '$final_status';

const layerResults = Object.values(data.layers);
const passedLayers = layerResults.filter(l => l.status === 'passed').length;
const failedLayers = layerResults.filter(l => l.status === 'failed').length;
const pendingLayers = layerResults.filter(l => l.status === 'pending').length;

const passedVerifications = data.verificationCommands.filter(v => v.status === 'passed').length;
const failedVerifications = data.verificationCommands.filter(v => v.status === 'failed').length;

data.summary = {
  totalLayers: layerResults.length,
  passedLayers,
  failedLayers,
  pendingLayers,
  totalVerifications: data.verificationCommands.length,
  passedVerifications,
  failedVerifications,
  totalErrors: data.errors.length,
  totalEvents: data.events.length
};

fs.writeFileSync('$tmp_file', JSON.stringify(data, null, 2));
" 2>/dev/null || true

  if [ -f "$tmp_file" ]; then
    mv "$tmp_file" "$trace_file"
  fi

  echo "Trace finalized: $trace_file"
  echo ""
  echo "Summary:"
  node -e "
const data = JSON.parse(require('fs').readFileSync('$trace_file', 'utf8'));
const s = data.summary;
console.log('  Feature:        ' + data.featureId);
console.log('  Status:         ' + data.status);
console.log('  Layers:         ' + s.passedLayers + '/' + s.totalLayers + ' passed');
console.log('  Verifications:  ' + s.passedVerifications + '/' + s.totalVerifications + ' passed');
console.log('  Errors:         ' + s.totalErrors);
console.log('  Duration:       ' + (new Date(data.endedAt) - new Date(data.startedAt)) + 'ms');
" 2>/dev/null || cat "$trace_file" | grep -E '"status"|"featureId"'
}

# Main command dispatcher
case "${1:-}" in
  init)
    init_trace "${2:-unknown}"
    ;;
  record)
    record_event "${2:-unknown}" "${3:-}"
    ;;
  layer)
    record_layer "${2:-0}" "${3:-pending}" "${4:-null}" "${5:-null}"
    ;;
  verify)
    record_verification "${2:-}" "${3:-}" "${4:-}" "${5:-}"
    ;;
  error)
    record_error "${2:-}" "${3:-}"
    ;;
  finalize)
    finalize_trace "${2:-completed}"
    ;;
  *)
    echo "Harness Trace Recorder — Runtime Observability for Agent Sessions"
    echo ""
    echo "Usage:"
    echo "  harness-trace.sh init <feature-id>              Start a new trace"
    echo "  harness-trace.sh record <event> [data]          Record an event"
    echo "  harness-trace.sh layer <0-3> <status> [details] Record layer result"
    echo "  harness-trace.sh verify <desc> <cmd> <status>   Record verification result"
    echo "  harness-trace.sh error <message> [context]      Record an error"
    echo "  harness-trace.sh finalize [status]              End trace and output summary"
    echo ""
    echo "Examples:"
    echo '  TRACE_FILE=$(bash scripts/harness-trace.sh init F004)'
    echo '  bash scripts/harness-trace.sh record "code_change" "{\"files\": [\"a.ts\"]}"'
    echo '  bash scripts/harness-trace.sh layer 0 "passed"'
    echo '  bash scripts/harness-trace.sh finalize'
    ;;
esac
