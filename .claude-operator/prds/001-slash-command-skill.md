# PRD-001: Make Claude Operator a /decide Slash Command

## Objective

Make Claude Operator invocable as `/decide` from within any Claude Code session, so the entire operator experience — onboarding, research, PRD collaboration, and cycle management — lives natively inside Claude Code without requiring a separate terminal launcher for default mode.

## User Problem

Users cannot currently use Claude Operator as intended. The SKILL.md exists but the skill is named `claude-operator`, which means users would need to type `/claude-operator` — unintuitive and not what they expect. There's no clear entry point. Users must either guess the right phrase to trigger the skill or run a bash launcher from the terminal. This breaks the core promise: a seamless, always-available autonomous operator within Claude Code.

## Target User

Engineers and vibe coders who have installed the claude-decide plugin and want to run the operator on their projects from within Claude Code.

## Value

This is the #1 user-stated priority and the sole blocker to launch. Without a working slash command, the product cannot be distributed through the Claude Code skills ecosystem — the primary go-to-market channel. Every other backlog item is blocked by or diminished without this.

## Scope (V1)

- Rename the skill from `claude-operator` to `decide` so it registers as `/decide`
- `/decide` loads SKILL.md and runs one operator cycle (reads state, executes current phase)
- `/decide force` enables force mode for that cycle (auto-approve PRDs)
- Ensure the skill triggers on natural language like "decide", "run the operator", "what should we build next"
- Add end-of-cycle messaging: "Cycle N complete. Run /decide to start the next cycle."

## Out of Scope

- `/decide stop` — unnecessary in default mode since user re-invokes manually between cycles (deferred)
- `/decide status` — separate feature, BL-008 in backlog
- Continuous loop within Claude Code — user re-invokes between cycles by design
- Force mode continuous loop — remains in launcher.sh for terminal use
- Backlog management commands (BL-008)

## Requirements

1. The skill directory is renamed from `skills/claude-operator/` to `skills/decide/`
2. SKILL.md frontmatter `name` field is `decide`
3. Running `/decide` in Claude Code loads the full SKILL.md coordinator and executes the current phase based on state.json
4. If `.claude-operator/` does not exist, `/decide` enters the onboarding flow
5. `/decide force` sets the mode to "force" for that cycle (skips collaboration, auto-approves PRD)
6. The skill `description` field contains trigger keywords: "decide", "operator", "autonomous", "improve", "codebase", "what to build"
7. After each cycle completes, the operator outputs: "Cycle N complete. Run /decide to start the next cycle."
8. All prompt file references within SKILL.md use the new path `skills/decide/prompts/`
9. Plugin manifest `skills` path still resolves correctly after rename
10. launcher.sh is updated to reference the new skill path

## Technical Approach

1. **Rename skill directory:** `mv skills/claude-operator skills/decide`

2. **Update SKILL.md frontmatter:**
   ```yaml
   ---
   name: decide
   description: Use when the user wants to decide what to build next, run the autonomous operator, improve a codebase, or asks 'what should we build'. Researches, generates PRDs, and executes improvements autonomously.
   ---
   ```

3. **Add argument handling at top of Phase Router:**
   - Check if args contain "force" → set mode to "force" for this cycle
   - Then proceed to normal phase routing

4. **Update all internal prompt references** in SKILL.md from `skills/claude-operator/prompts/` to `skills/decide/prompts/`

5. **Update launcher.sh** path reference and fix the `claude -p` invocation to load SKILL.md contents as context rather than a bare string

6. **Add end-of-cycle output** in Update Memory Phase Step 4

## Risks

- Renaming the directory may break git history for individual files (acceptable — the files are new and have no meaningful blame history)
- The skill description matching is probabilistic — `/decide` slash command provides deterministic invocation as fallback
- Users who previously referenced `claude-operator` by name will need to use `decide` instead (no existing users yet, so not a real risk)

## Open Questions

None.

## Experiment Plan

N/A — this is a baseline feature required for launch, not an experiment.

## Backlog Reference

- Source: BL-001
- Research agents that flagged this: All 7 (pre-existing top priority confirmed by every research agent)
- Priority score: 0.95

## Critique Log

```json
{
  "prd_version": "v2",
  "iterations": [
    { "lens": "scope_optimizer", "change": "Removed --status and --stop flags from V1 scope — --status is a separate feature (BL-008), --stop is unnecessary in default mode since user re-invokes manually" },
    { "lens": "risk_analyzer", "change": "Revised technical approach: skill name determines slash command, so renaming to 'decide' is required for /decide to work. Added risk about skill description matching being probabilistic." },
    { "lens": "feasibility", "change": "Changed --force flag to 'force' as natural language arg since skills receive args as strings. Updated technical approach to be rename-based rather than command-registry-based." }
  ]
}
```
