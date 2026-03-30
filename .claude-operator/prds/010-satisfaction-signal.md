# PRD-010: Post-Execution Satisfaction Signal

## Objective

Add a lightweight satisfaction signal to the operator's default and auto modes that lets users rate cycle output after execution. Store ratings in cycle logs and use them to adjust backlog priority scoring over time. This closes the feedback loop — the operator can learn which types of improvements users value most.

## User Problem

The operator has no way to know whether its output was valuable. It picks the highest-priority backlog item each cycle, but priority scores are assigned by research agents — never validated by the user. Over many cycles, the operator may drift toward producing changes the user doesn't care about while ignoring what they actually want. There's no learning signal.

## Target User

Engineers running the operator in default or auto mode who want the operator to get better at picking valuable work over time.

## Value

Priority scoring is the operator's core decision-making mechanism. Without a feedback signal, scores are guesses that never improve. Adding satisfaction ratings creates a calibration loop: high-rated cycles inform what "good work" looks like, low-rated cycles signal misalignment. This is foundational for smarter autonomous operation.

## Scope (V1)

- Add a satisfaction prompt at the end of the Update Memory phase (default and auto modes only; force mode skips)
- Accept a 1-5 rating with optional free-text comment
- Store the rating in the cycle log
- Add a `satisfaction_history` array to `memory.json` to track ratings across cycles
- (Future: use ratings to adjust research synthesis scoring — not in V1)

## Out of Scope

- Per-requirement ratings (rating individual PRD requirements instead of the whole cycle)
- Automatic threshold adjustment based on ratings (future iteration)
- Retroactive rating of past cycles
- Dashboard or visualization of ratings (use /decide stats in the future)
- Rating prompts in force mode (fully autonomous = no interaction)

## Requirements

1. After the Update Memory phase commits, if mode is "default" or "auto", output a satisfaction prompt: `"Rate this cycle's output (1-5, or skip): "` and wait for user input.
2. Accept integer 1-5, "skip", or empty (treated as skip). Invalid input re-prompts once, then treats as skip.
3. If a rating is provided, store it in the cycle log as `"satisfaction": { "rating": N, "comment": "..." }`. If skipped, store `"satisfaction": { "rating": null, "comment": null }`.
4. Add a `satisfaction_history` array to `memory.json` with entries: `{ "cycle": N, "rating": N|null, "prd": "filename" }`.
5. The satisfaction prompt MUST NOT appear in force mode. Force mode cycles store `"satisfaction": { "rating": null, "comment": "force mode — skipped" }` in the cycle log automatically.
6. In the decide-loop (`/decide-loop`), satisfaction prompts are skipped (force mode behavior) since the loop is non-interactive.

## Technical Approach

### Files to modify:
- `skills/decide/SKILL.md` — Update Memory Phase (add satisfaction prompt after Step 5 commit)
- `skills/decide/prompts/state-templates.md` — Add satisfaction fields to cycle log schema and satisfaction_history to memory.json schema

### Implementation:
1. **Update Memory Phase**: After Step 5 (commit), add Step 5b: if mode is "default" or "auto", output the satisfaction prompt and collect input. Store in cycle log. Append to satisfaction_history in memory.json.
2. **state-templates.md**: Add satisfaction field to cycle log schema. Add satisfaction_history to memory.json schema.

### Patterns to follow:
- Mirror the existing collaborate phase's user interaction pattern
- Keep ratings simple (1-5 integer) to minimize friction
- Store data alongside existing cycle log structure

## Risks

- Users may skip ratings consistently, making the feature useless. Mitigated by keeping the prompt minimal (one line, optional).
- Adding interaction to the Update Memory phase changes its character from "bookkeeping" to "interactive". Acceptable because it's gated on non-force modes.

## Open Questions

None.

## Experiment Plan

N/A — this is a baseline feature. Success = users provide ratings in at least 50% of default/auto cycles after 10+ cycles. The satisfaction_history data itself enables future analysis.

## Backlog Reference

- Source: BL-030
- Research agents that flagged this: customer-value, experimentation
- Priority score: 0.72

## Outcome (Cycle 10)

- **Status**: completed
- **Requirements**: 6 of 6 passed
- **Approach deviations**: None
- **Lessons learned**: None
