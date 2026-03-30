# PRD-013: /decide rollback Command

## Objective

Add a "rollback" argument to the operator that reverts the most recent cycle's changes using git. This gives users an undo button when the operator produces an unwanted change — critical for building trust, especially in auto and force modes where changes happen without per-cycle approval.

## User Problem

When the operator makes a change the user doesn't want, there's no built-in way to undo it. Users must manually find the commit hash in cycle logs, run `git revert`, and update the backlog. This is error-prone and requires knowledge of the operator's internal state structure.

## Target User

All operator users, especially those running auto or force mode who may discover unwanted changes after the fact.

## Value

Undo is a fundamental operation for any tool that modifies code autonomously. Without it, users must trust every cycle or manually manage git themselves. Rollback lowers the risk of using autonomous modes and directly addresses "what if it breaks something?" anxiety.

## Scope (V1)

- Add "rollback" as a recognized argument in the Phase Router
- Read the most recent cycle log to find the commit hash
- Offer `git revert` of that commit
- Mark the corresponding backlog item as "rejected" with a rollback note
- Update the cycle log with rollback status

## Out of Scope

- Rolling back multiple cycles at once
- Rolling back to a specific cycle number (only most recent)
- Undoing the rollback (use git for that)
- Rolling back if the commit has already been pushed to a remote

## Requirements

1. Running `/decide rollback` triggers the rollback flow instead of the normal phase router.
2. Read the most recent cycle log from `.claude-operator/logs/` to find the commit hash.
3. If no cycle logs exist, output `"Nothing to roll back — no completed cycles found."` and exit.
4. Show the user what will be reverted: `"Rolling back cycle [N]: [PRD title] (commit [hash]). This will git revert the commit. Proceed? (yes/no)"`. In force mode, skip confirmation.
5. Run `git revert --no-edit [commit_hash]`. If the revert fails (e.g., conflicts), output the error and suggest manual resolution.
6. After successful revert, mark the corresponding backlog item as "rejected" with note "Rolled back in cycle [current]".
7. The rollback argument is documented in SKILL.md Phase Router Step 0 alongside force, auto, and reset.

## Technical Approach

### Files to modify:
- `skills/decide/SKILL.md` — Phase Router Step 0 (arg parsing for "rollback"), new Rollback Phase section

### Implementation:
1. **Phase Router Step 0**: Add check for "rollback" arg. If found, jump to Rollback Phase.
2. **Rollback Phase**: New section in SKILL.md. Reads latest cycle log, extracts commit hash, confirms with user (unless force), runs git revert, updates backlog.

## Risks

- Reverting a commit that modified `.claude-operator/` state files may leave state inconsistent. Mitigated by: the revert restores the previous state files too, since operator commits include all state.
- Merge conflicts during revert if subsequent commits modified the same files. Mitigated by: outputting the error and suggesting manual resolution rather than trying to auto-fix.

## Open Questions

None.

## Experiment Plan

N/A — this is a baseline feature, not an experiment.

## Backlog Reference

- Source: BL-031
- Research agents that flagged this: product-gap, customer-value
- Priority score: 0.68

## Outcome (Cycle 13)

- **Status**: completed
- **Requirements**: 7 of 7 passed
- **Approach deviations**: None
- **Lessons learned**: None
