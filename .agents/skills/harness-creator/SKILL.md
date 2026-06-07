---
name: harness-creator
description: Initialize and maintain Harness Engineering controls for AI agent projects. Enforces WIP=1 workflow, scope surface (machine-readable task state), completion evidence (executable verification commands), and VCR (Verified Completion Rate) monitoring. Use when (1) setting up agent behavior constraints for a new project, (2) converting an existing project's task tracking to a machine-readable scope surface with completion evidence, (3) updating agent harness rules to prevent overreach and under-finish, (4) a project needs explicit WIP limits and verified completion criteria for AI agents, or (5) modifying feature_list.json, AGENTS.md, or PROGRESS.md to add WIP=1 controls.
---

# Harness Creator

Prevent agent overreach and under-finish by enforcing WIP=1, completion evidence, and scope surface persistence.

## When to Apply

Apply this skill when any of these conditions are met:
- The project lacks a machine-readable task state file with completion evidence
- Agents are working on multiple features simultaneously without end-to-end verification
- Task tracking is only in human-readable markdown with no executable verification commands
- `feature_list.json` exists but has no `verificationCommand`, `dependencies`, or state machine
- `AGENTS.md` does not mention WIP limits or completion evidence
- VCR (Verified Completion Rate) is not tracked

## Core Concepts

| Concept | Definition |
|---------|------------|
| **WIP=1** | Only one task in `active` state at any time |
| **Scope Surface** | Machine-readable task DAG in `feature_list.json` with states and dependencies |
| **Completion Evidence** | Executable `verificationCommand` that must pass for a task to be `passing` |
| **VCR** | Verified Completion Rate = `passing` / (`passing` + `active` + `blocked`) |
| **Overreach** | Activating more tasks than optimal in a single session |
| **Under-finish** | Tasks written but verification fails |

## State Machine

Tasks in `feature_list.json` must use exactly these states:

| State | Meaning | Transitions |
|-------|---------|-------------|
| `not_started` | Waiting for dependencies | → `active`, `blocked` |
| `active` | Currently being implemented | → `passing`, `blocked` |
| `blocked` | Dependencies not met or external blocker | → `active` |
| `passing` | All completion evidence verified | → (none, terminal) |

## Workflow

### 1. Diagnose Current State

Check if the project already has Harness Engineering controls:

```bash
# Check for existing scope surface
test -f feature_list.json && echo "Has feature_list.json" || echo "Missing feature_list.json"

# Check for WIP=1 rule
grep -qi "wip.*=.*1\|WIP=1" AGENTS.md 2>/dev/null && echo "Has WIP=1" || echo "Missing WIP=1"

# Check for completion evidence
grep -q "verificationCommand" feature_list.json 2>/dev/null && echo "Has completion evidence" || echo "Missing completion evidence"
```

### 2. Initialize or Upgrade

**If starting from scratch:**
1. Create `feature_list.json` from the template in [references/feature-list-template.json](references/feature-list-template.json)
2. Update `AGENTS.md` with WIP=1 hard constraints (see [references/agents-rules.md](references/agents-rules.md))
3. Update `docs/workflow.md` with WIP=1 execution flow
4. Update `PROGRESS.md` with VCR tracking section

**If upgrading existing `feature_list.json`:**
1. Read the existing file to understand current features
2. Add `scopeSurface` metadata block with `wipLimit`, `activeFeatureId`, `vcr`
3. Convert each feature's `status` to the four-state model
4. Add `dependencies` arrays to each feature
5. Add `completionEvidence` arrays with `description` and `verificationCommand`

**If upgrading `AGENTS.md`:**
1. Add hard constraint: "WIP = 1 — only one active task at any time"
2. Add hard constraint: "Completion evidence must be executable"
3. Add hard constraint: "VCR < 1.0 blocks new task activation"
4. Add "Work Rules (WIP=1)" section

### 3. Define Completion Evidence

For each feature, write 2-4 `verificationCommand` entries. Commands must:
- Exit with code 0 on success
- Be executable from the project root
- Verify behavior, not just code existence

**Good examples:**
```bash
# Verify behavior
cd packages/core && npx vitest run src/engine/event-queue.test.ts

# Verify type exports exist
grep -q 'export class SimulationEngine' packages/core/src/engine/simulation-engine.ts

# Verify build passes
cd packages/web && pnpm lint && pnpm type-check && pnpm build
```

**Bad examples:**
```bash
# Too vague — checks nothing specific
ls packages/core/src/

# Not executable — human judgment required without fallback
" visually inspect the code "
```

### 4. Calculate and Monitor VCR

After every session, update `feature_list.json`:

```json
"scopeSurface": {
  "wipLimit": 1,
  "activeFeatureId": null,
  "vcr": {
    "activated": 3,
    "passing": 2,
    "rate": 0.67
  }
}
```

Block new task activation when `rate < 1.0`.

### 5. Maintain Across Sessions

**Clock In:**
1. Read `feature_list.json` — identify `activeFeatureId` and completion evidence
2. Read `PROGRESS.md` — check VCR and blockers
3. Run `make check` or equivalent to verify repository state
4. Continue `active` task, or pick next `not_started` with all dependencies `passing`

**Clock Out:**
1. Update `feature_list.json` — task status, completed evidence, VCR
2. Update `PROGRESS.md` — progress, verification status, blockers
3. Run `make check` to confirm self-consistency
4. Atomic commit all changes

## File Templates

See [references/feature-list-template.json](references/feature-list-template.json) for the canonical `feature_list.json` structure.

See [references/agents-rules.md](references/agents-rules.md) for `AGENTS.md` WIP=1 rules template.

## Validation Checklist

Before considering the harness complete, verify:

- [ ] `feature_list.json` is valid JSON and parseable
- [ ] Exactly 0 or 1 features have `status: "active"`
- [ ] Every feature has at least one `completionEvidence` entry
- [ ] Every `verificationCommand` exits 0 when run
- [ ] `AGENTS.md` contains "WIP = 1" or "WIP=1"
- [ ] `AGENTS.md` contains "completion evidence" or "verificationCommand"
- [ ] `AGENTS.md` contains "VCR" or "Verified Completion Rate"
- [ ] `PROGRESS.md` tracks VCR numerically
