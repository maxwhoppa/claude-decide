# PRD-015: Backlog Inspection Commands

## Objective

Add "status" and "backlog" arguments to the operator that let users inspect the current state and backlog without reading JSON files directly. This gives users visibility into what the operator knows, what it's done, and what's queued — critical for building trust.

## User Problem

Users can't see what the operator knows or has done without opening JSON files in `.claude-operator/`. There's no quick way to check: what cycle are we on? What's in the backlog? What was the last thing built? This opacity undermines trust, especially for users evaluating whether to use force/auto mode.

## Target User

All operator users who want a quick status check or want to review queued work.

## Value

Transparency is the foundation of trust. Users who can easily see operator state are more likely to use autonomous modes. This is the "what's going on?" command every CLI tool needs.

## Scope (V1)

- Add "status" argument: shows current cycle, phase, mode, last completed timestamp, and recent PRD
- Add "backlog" argument: shows all queued items sorted by priority
- Both are read-only — no state changes

## Out of Scope

- Editing backlog items from the command (use `/decide-loop edit` for that)
- Showing full cycle history (use `/decide stats` in the future, BL-034)
- Filtering backlog by status

## Requirements

1. Running `/decide status` outputs: cycle number, current phase, mode, last completed timestamp, current PRD (if any), and count of queued/completed/rejected backlog items.
2. Running `/decide backlog` outputs: all queued items as a priority-sorted table with ID, priority, and idea title (truncated to 60 chars).
3. Both commands exit without modifying any state files.
4. If `.claude-operator/` doesn't exist, output "Operator not initialized. Run /decide to start." and exit.
5. Both commands are documented in SKILL.md Phase Router Step 0 alongside force, auto, reset, and rollback.

## Technical Approach

### Files to modify:
- `skills/decide/SKILL.md` — Phase Router Step 0 (arg parsing), new Status Phase and Backlog Phase sections

### Implementation:
1. **Phase Router Step 0**: Add checks for "status" and "backlog" args. Both jump to their respective phases and skip normal routing.
2. **Status Phase**: Read state.json and backlog.json, output formatted summary.
3. **Backlog Phase**: Read backlog.json, filter to queued, sort by priority, output table.

## Risks

None — read-only commands.

## Open Questions

None.

## Experiment Plan

N/A.

## Backlog Reference

- Source: BL-008
- Research agents that flagged this: product-gap, customer-value
- Priority score: 0.65

## Outcome (Cycle 15)

- **Status**: completed
- **Requirements**: 5 of 5 passed
- **Approach deviations**: None
- **Lessons learned**: None
