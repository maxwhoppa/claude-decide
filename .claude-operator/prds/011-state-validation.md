# PRD-011: State Validation Before Phase Routing

## Objective

Add validation of `state.json` fields in the Phase Router before executing any phase. Check that `phase` is a recognized enum value, `mode` is valid, and `current_prd` (when set) points to a file within `.claude-operator/prds/`. This prevents undefined behavior from corrupted state, typos, or malicious state manipulation.

## User Problem

If `state.json` contains an unrecognized phase value (e.g., a typo like "reserach" or a leftover "validate" from an old schema), the operator silently does nothing — no error, no recovery. If `current_prd` contains a path traversal string (e.g., "../../secrets.md"), the operator could read or write outside the expected directory. These are both bugs waiting to happen.

## Target User

All operator users. This is defensive infrastructure — it protects everyone silently.

## Value

The operator's state machine is entirely trust-based. A single corrupted field can cause silent failure or security issues. Validation is the minimum safety net needed before the operator grows more features. Multiple research agents flagged this: security + code auditor convergence.

## Scope (V1)

- Add a validation step to the Phase Router (between Step 3 and Step 4) that checks phase, mode, and current_prd
- On invalid phase: output error, set phase to "research", continue
- On invalid mode: output warning, default to "default", continue
- On invalid current_prd: output error, clear current_prd, set phase to "research", continue

## Out of Scope

- JSON schema validation (checking all field types, required fields)
- State file migration between schema versions (BL-005)
- Cycle number validation (always positive integer — not worth checking)

## Requirements

1. After checking for stuck.json (Phase Router Step 3) and before executing the phase (Step 4), validate state.json fields.
2. `phase` must be one of: "research", "propose", "collaborate", "execute", "update_memory". If not, output `"Warning: unrecognized phase '[value]'. Resetting to research."`, set phase to "research", and continue.
3. `mode` must be one of: "default", "force", "auto". If not, output `"Warning: unrecognized mode '[value]'. Defaulting to 'default'."`, set mode to "default", and continue.
4. If `current_prd` is set (not null), it must match the pattern `NNN-*.md` (digits, dash, alphanumeric/dash characters, .md extension) and must NOT contain path separators (`/` or `\`). If invalid, output `"Warning: invalid current_prd '[value]'. Clearing and resetting to research."`, clear current_prd, set phase to "research", and continue.
5. Validation must be documented in `SKILL.md` as Phase Router Step 3b.

## Technical Approach

### Files to modify:
- `skills/decide/SKILL.md` — Add Phase Router Step 3b between existing Step 3 (stuck check) and Step 4 (execute phase)

### Implementation:
1. **Phase Router Step 3b**: Insert validation instructions between the stuck.json check and the phase execution. Three checks: phase enum, mode enum, current_prd format. Each has a graceful fallback (reset to safe defaults) rather than halting.

### Patterns to follow:
- Warnings, not errors — the operator self-heals rather than stopping
- Follows the existing Phase Router numbering (3b, like the 5b pattern from satisfaction signal)

## Risks

- Validation instructions add ~15 lines to an already long SKILL.md. Acceptable — this is safety-critical.
- The current_prd regex pattern must be specific enough to catch traversal but not reject valid filenames. The `NNN-*.md` pattern with no path separators is safe.

## Open Questions

None.

## Experiment Plan

N/A — this is defensive infrastructure, not an experiment.

## Backlog Reference

- Source: BL-010
- Research agents that flagged this: security, code-auditor
- Priority score: 0.70

## Outcome (Cycle 11)

- **Status**: completed
- **Requirements**: 5 of 5 passed
- **Approach deviations**: None
- **Lessons learned**: None
