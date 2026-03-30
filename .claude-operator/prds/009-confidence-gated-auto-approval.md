# PRD-009: Confidence-Gated Auto-Approval

## Objective

Add an "auto" mode to the operator that auto-approves PRDs whose backlog priority score meets or exceeds a user-defined threshold, while routing lower-scored PRDs through the interactive collaborate phase. This creates a practical middle ground between force mode (approve everything) and default mode (approve nothing without asking).

## User Problem

Users currently face a binary choice: either approve every PRD manually (default mode, high friction) or approve nothing (force mode, no oversight). Users who trust the operator for routine improvements but want oversight on speculative or risky changes have no option that fits. They either abandon the tool due to friction or run force mode and accept changes they'd prefer to review.

## Target User

Engineers using Claude Operator in default mode who find the per-cycle approval overhead excessive for high-confidence items, but aren't comfortable with fully autonomous force mode.

## Value

The operator's stated problem is eliminating idle time. Default mode reintroduces idle time by blocking on user approval. Auto mode keeps the operator running for well-understood work while preserving human-in-the-loop for novel or risky proposals — directly aligned with the product's core value proposition.

## Scope (V1)

- Add `"auto"` as a valid mode in `state.json` alongside `"default"` and `"force"`
- Add `auto_threshold` field to `state.json` (default: `0.75`)
- Modify the Propose Phase transition logic: when mode is `"auto"`, compare the candidate backlog item's `priority_score` to `auto_threshold` and route accordingly
- Accept `auto` and `auto <threshold>` as arguments (e.g., `/decide auto`, `/decide auto 0.8`)
- Update `state-templates.md` to document new mode and field
- Update `launcher.sh` to accept `--auto` and `--auto=<threshold>` flags

## Out of Scope

- Dynamic threshold adjustment based on past cycle outcomes (future iteration, see BL-030)
- Per-category thresholds (e.g., different threshold for security vs. UX items)
- UI for changing threshold mid-session (user can edit state.json directly)
- Onboarding changes — auto mode is an opt-in runtime switch, not an onboarding question

## Requirements

1. `state.json` accepts `mode: "auto"` without error. The phase router treats it as a valid mode.
2. `state.json` accepts an `auto_threshold` field with a float value between 0.0 and 1.0. Default is 0.75 if not specified.
3. When mode is `"auto"` and the candidate backlog item's `priority_score >= auto_threshold`, the Propose Phase transitions directly to Execute Phase (skipping Collaborate), with open questions resolved as in force mode.
4. When mode is `"auto"` and the candidate backlog item's `priority_score < auto_threshold`, the Propose Phase transitions to Collaborate Phase for user review.
5. Running `/decide auto` sets mode to `"auto"` with default threshold 0.75.
6. Running `/decide auto 0.8` sets mode to `"auto"` with threshold 0.80.
7. The `launcher.sh` script accepts `--auto` and `--auto=N` flags, setting mode and threshold accordingly.
8. `state-templates.md` documents the `"auto"` mode and `auto_threshold` field.
9. When auto-approving, output includes: `"Auto-approved (priority [score] >= threshold [threshold]). Skipping collaboration."`
10. When routing to collaborate, output includes: `"Priority [score] < threshold [threshold]. Routing to collaboration."`

## Technical Approach

### Files to modify:
- `skills/decide/SKILL.md` — Phase Router (arg parsing), Propose Phase (transition logic)
- `skills/decide/prompts/state-templates.md` — state.json schema documentation
- `skills/decide/scripts/launcher.sh` — `--auto` flag parsing
- `.claude-operator/state.json` — runtime state (updated by operator)

### Implementation:
1. **Arg parsing (Phase Router Step 0)**: Extend the existing force mode check to also detect "auto" and optional threshold. Parse `/decide auto 0.8` → set mode to "auto", set auto_threshold to 0.80.
2. **Propose Phase Step 4 (Transition)**: Add a third branch alongside "force" and "default":
   - If mode is "auto" AND priority_score >= auto_threshold: resolve open questions (same as force), transition to execute.
   - If mode is "auto" AND priority_score < auto_threshold: transition to collaborate.
3. **state-templates.md**: Add "auto" to mode enum, add auto_threshold field with description and default.
4. **launcher.sh**: Add --auto/--auto=N argument parsing alongside existing --force.

### Patterns to follow:
- Mirror the existing force mode arg parsing pattern
- Keep the threshold in state.json (not memory.json) since it's a runtime preference, not a product fact

## Risks

- Users may set threshold too low (e.g., 0.1) effectively making it force mode with extra steps. Mitigated by documenting recommended range (0.6-0.9).
- Priority scores are operator-assigned and may not reflect actual risk. This is a known limitation of the scoring system, not introduced by this feature.
- Auto mode may silently accumulate unreviewed changes over many cycles. Mitigated by: users chose auto mode knowingly, and can switch to default at any time. Future BL-030 (satisfaction signal) could add a periodic review checkpoint.

## Open Questions

None — the design is straightforward and follows existing mode patterns.

## Experiment Plan

N/A — this is a baseline feature, not an experiment. Success can be measured by tracking auto-approved vs. collaborate-routed cycles in cycle logs (future enhancement). Qualitatively, success = users who previously ran default mode switch to auto mode and maintain higher cycle throughput without regretting unreviewed changes.

## Backlog Reference

- Source: BL-029
- Research agents that flagged this: customer-value, experimentation
- Priority score: 0.72

## Outcome (Cycle 9)

- **Status**: completed
- **Requirements**: 10 of 10 passed
- **Approach deviations**: None
- **Lessons learned**: None
