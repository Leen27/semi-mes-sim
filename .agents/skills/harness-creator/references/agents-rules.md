# AGENTS.md WIP=1 Rules Template

Copy these sections into the project's `AGENTS.md`.

## Hard Constraints (append to existing list)

```markdown
15. **WIP = 1** —— Any moment only one feature may be `active`. Finish one before starting the next.
16. **Completion evidence must be executable** —— A feature is not "code looks fine"; it is all `verificationCommand`s in `feature_list.json` passing.
17. **VCR < 1.0 blocks new activation** —— When Verified Completion Rate is below 100%, no new task may be activated until the active task reaches `passing`.
```

## Work Rules (WIP=1)

```markdown
## Work Rules (WIP=1)

> Source: Lecture 07 — Draw Clear Task Boundaries for Agents

- **Work on one feature at a time** —— Only one `active` entry in `feature_list.json`
- **Pass verification before moving on** —— All `completionEvidence.verificationCommand`s must exit 0
- **No refactoring detours** —— If feature B needs changes while implementing A, note it, do not change it
- **Dependencies must be `passing`** —— Check `feature_list.json` `dependencies` array before activation
- **Update scope surface at session end** —— Record status, passed evidence, and blockers in `feature_list.json` and `PROGRESS.md`
```

## Cross-Session Handoff (update Clock In/Out)

```markdown
**Clock In:**
1. Read `PROGRESS.md`
2. Read `DECISIONS.md`
3. Read `feature_list.json` — confirm `activeFeatureId` and completion evidence
4. Run `make check` to verify repository state
5. Continue `active` task or select next `not_started` per WIP=1 rules

**Clock Out:**
1. Update `feature_list.json` — task status, completed evidence, VCR
2. Update `PROGRESS.md` — progress, verification status, blockers
3. New decisions append to `DECISIONS.md`
4. Run `make check`
5. Atomic commit all work
```

## Key Terms (append to existing table)

| Term | Definition |
|------|------------|
| **Scope Surface** | Task DAG in `feature_list.json` recording states and dependencies |
| **VCR** | Verified Completion Rate = passing / (passing + active + blocked) |
| **Completion Evidence** | Executable verification command proving a feature is done |
