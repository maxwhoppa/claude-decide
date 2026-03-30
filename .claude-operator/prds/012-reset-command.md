# PRD-012: /decide reset Command

## Objective

Add a "reset" argument to the operator that removes `.claude-operator/` and re-triggers onboarding, giving users a clean way to start fresh. Optionally preserves the backlog so previously discovered work isn't lost.

## User Problem

There's no way to uninstall, reset, or start fresh with the operator. If onboarding captured wrong information, or if a user wants to point the operator at a different project context, the only option is manually deleting `.claude-operator/`. Users shouldn't need to know the internal directory structure to reset.

## Target User

Users who need to re-onboard due to changed project context, corrupted state, or wanting a fresh start.

## Value

Basic CRUD completeness — the operator has Create (onboarding) but no Delete. This is table stakes for any tool that writes persistent state. Without it, users who encounter issues lose confidence and may abandon the tool.

## Scope (V1)

- Add "reset" as a recognized argument in the Phase Router
- When invoked, confirm with user (unless force mode), then remove `.claude-operator/`
- Offer to preserve backlog before deletion
- After removal, the next `/decide` invocation triggers onboarding naturally

## Out of Scope

- Selective reset (e.g., reset only memory but keep backlog and logs)
- Backup/export of state before reset
- Reset via launcher.sh (use `/decide reset` in Claude Code only)

## Requirements

1. Running `/decide reset` triggers the reset flow instead of the normal phase router.
2. In default/auto mode, confirm with user: `"This will delete .claude-operator/ and all operator state (memory, backlog, logs, PRDs). Proceed? (yes/no)"`. Only proceed on explicit "yes".
3. Before deletion, ask: `"Preserve the current backlog? (yes/no)"`. If yes, save backlog.json contents, delete .claude-operator/, recreate the directory during next onboarding, and restore backlog.json.
4. In force mode, skip confirmation — delete immediately. Do not preserve backlog (force reset = clean slate).
5. After deletion, output: `"Operator reset complete. Run /decide to start fresh onboarding."` and exit.
6. The reset argument is documented in SKILL.md Phase Router Step 0 alongside force and auto.

## Technical Approach

### Files to modify:
- `skills/decide/SKILL.md` — Phase Router Step 0 (arg parsing for "reset"), new Reset Phase section

### Implementation:
1. **Phase Router Step 0**: Add check for "reset" arg. If found, jump to Reset Phase (skip all other routing).
2. **Reset Phase**: New section in SKILL.md between Onboarding Phase and Research Phase. Handles confirmation, optional backlog preservation, deletion, and exit.

## Risks

- Accidental reset in force mode deletes everything without confirmation. Acceptable — force mode is explicitly "no interaction, full autonomy". Users chose this.
- Preserved backlog may reference stale PRDs or memory that no longer exists after reset. Acceptable — backlog items are self-contained ideas, not dependent on PRDs.

## Open Questions

None.

## Experiment Plan

N/A — this is a baseline feature, not an experiment.

## Backlog Reference

- Source: BL-028
- Research agents that flagged this: product-gap
- Priority score: 0.70

## Outcome (Cycle 12)

- **Status**: completed
- **Requirements**: 6 of 6 passed
- **Approach deviations**: None
- **Lessons learned**: None
