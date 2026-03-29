# PRD-002: Fix Force Mode Launcher — Secure Shell Handling and Full Instruction Loading

## Objective

Rewrite the force mode launcher script (`skills/decide/scripts/launcher.sh`) to eliminate a critical shell injection vulnerability and ensure the operator runs with full SKILL.md instructions, guardrails, and constraints. Currently, force mode is both insecure (shell metacharacters in SKILL.md execute as commands) and structurally broken (the prompt framing bypasses the phase router's guardrails). This fix makes force mode safe to run unattended.

## User Problem

Users running `bash skills/decide/scripts/launcher.sh --force` for fully autonomous operation are exposed to two critical issues: (1) arbitrary command execution via shell injection if SKILL.md or any interpolated content contains shell metacharacters like backticks or `$()`, and (2) the operator running without proper guardrails because the launcher's prompt framing doesn't trigger the SKILL.md phase router correctly — it wraps instructions in a bare "execute the current phase" prompt that sidesteps constraints, stuck recovery, and stagnation checks.

## Target User

Developers using force mode for unattended autonomous operation — the power users who would run the operator overnight or on a schedule.

## Value

Force mode is a key differentiator (autonomous product improvement without user interaction) but is currently unusable in production. A critical shell injection vulnerability means running the launcher is a security risk. Fixing this unblocks safe autonomous operation and is prerequisite to marketplace publishing and broader adoption. 4 research agents flagged the structural issue in cycle 1; the security audit in cycle 2 elevated it to critical.

## Scope (V1)

- Replace unsafe `${SKILL_CONTENTS}` interpolation in `claude -p` with a heredoc using single-quoted delimiter (`<<'PROMPT_EOF'`) to prevent shell expansion
- Restructure the prompt to invoke `/decide force` via Claude Code's skill system rather than inlining SKILL.md contents, so the operator gets the same code path as interactive mode
- If direct skill invocation from `claude -p` is not feasible, use a temporary file approach: write the prompt to a temp file and pass it via `claude -p "$(cat /tmp/claude-decide-prompt-$$)"` with proper quoting and cleanup
- Add `umask 077` before writing any temp files to prevent other users from reading the prompt
- Handle the `paused` state in the launcher loop — if `state.json` status is `paused`, print a message and exit instead of re-invoking infinitely (fixes the infinite loop bug from BL-012)
- Add a `max_cycles` safety limit (default: 50) with a `--max-cycles N` flag to prevent unbounded execution

## Out of Scope

- Rewriting the launcher in a different language (stays as bash) — unnecessary complexity for V1
- Adding cost tracking to the launcher (BL-004) — separate concern
- Adding log rotation (mentioned by security audit) — low severity, separate item
- State file integrity checking / checksums (mentioned by security audit) — separate concern
- Stop file TOCTOU race condition (low severity, acceptable risk for V1)

## Requirements

1. The launcher MUST NOT use unquoted variable interpolation (`${VAR}`) inside any string passed to `claude -p`
2. Shell metacharacters in SKILL.md content (backticks, `$()`, `$(())`, double quotes) MUST NOT be interpreted by the shell during prompt construction
3. The operator invoked by the launcher MUST execute the same phase router logic as `/decide force` in Claude Code — same guardrails, same stuck detection, same stagnation checks
4. If `state.json` contains `"status": "paused"`, the launcher MUST print "Operator is paused. Resume by editing state.json or re-running onboarding." and exit with code 0
5. The launcher MUST accept `--max-cycles N` flag (default 50) and stop after N cycles with message "Max cycles (N) reached. Operator stopped."
6. Temporary files created during prompt construction MUST be created with mode 600 (owner read/write only) and cleaned up on exit via trap
7. The launcher MUST pass `force` as an argument so the operator sets mode to "force" in state.json
8. All existing functionality MUST be preserved: Ctrl+C handling, graceful stop via stop file, stuck detection and wait loop

## Technical Approach

**Option A (preferred): Use heredoc with single-quoted delimiter**

Replace the current approach:
```bash
# CURRENT (vulnerable)
SKILL_CONTENTS=$(cat skills/decide/SKILL.md)
claude -p "...${SKILL_CONTENTS}..."
```

With a heredoc that prevents all shell expansion:
```bash
# FIXED
claude -p "$(cat <<'PROMPT_EOF'
You are Claude Operator running in force mode. Execute /decide force.
Read .claude-operator/state.json and execute the current phase.
Mode: force (auto-approve PRDs, skip user collaboration).
When the phase is complete, update state.json and exit.

Full instructions follow:
PROMPT_EOF
cat skills/decide/SKILL.md
)"
```

Actually, the cleanest approach is to have the launcher write a temp file:
```bash
PROMPT_FILE=$(mktemp /tmp/claude-decide-prompt.XXXXXX)
trap "rm -f '$PROMPT_FILE'" EXIT
umask 077
cat > "$PROMPT_FILE" <<'PROMPT_EOF'
You are Claude Operator running in force mode.
[static preamble]
PROMPT_EOF
cat skills/decide/SKILL.md >> "$PROMPT_FILE"
cat >> "$PROMPT_FILE" <<'PROMPT_EOF'
[static postamble with phase routing instructions]
PROMPT_EOF
claude -p "$(cat "$PROMPT_FILE")"
```

**Files to modify:**
- `skills/decide/scripts/launcher.sh` — rewrite the cycle execution block (lines 62-69), add paused state check, add max_cycles flag parsing

**Patterns to follow:**
- Same bash style as existing script (set -euo pipefail, trap, etc.)
- Keep the launcher self-contained — no external dependencies beyond `claude` CLI

## Risks

1. **`claude -p` prompt length limit** — SKILL.md is large. If there's a character limit on `claude -p` input, this approach fails. Mitigation: test with current SKILL.md size; if too large, use `claude -p < file` stdin approach.
2. **Prompt framing may not trigger skill system** — If `claude -p` doesn't have access to installed skills/superpowers, the operator may not be able to invoke brainstorming/planning skills during execution. Mitigation: the prompt should include the full SKILL.md instructions directly rather than relying on `/decide` invocation.
3. **Temp file cleanup on crash** — If the script is killed with SIGKILL (not SIGTERM/SIGINT), the trap won't fire and temp files remain. Mitigation: use `/tmp` which is cleaned periodically; use unique filenames with PID.

## Open Questions

None — all technical uncertainties can be resolved during implementation by testing `claude -p` behavior with large prompts.

## Experiment Plan

N/A — this is a security fix and structural correction, not an experiment. Success is binary: the launcher runs safely without shell injection and the operator follows the same code path as interactive mode.

## Backlog Reference

- Source: BL-007 (structural launcher fix, cycle 1) + BL-021 (shell injection, cycle 2)
- Research agents that flagged this: code-auditor (c1+c2), security (c1+c2), product-gap (c1), customer-value (c1) — 4 unique agents across 2 cycles
- Priority score: 0.90

---

## Critique Log

```json
{
  "prd_version": "v2",
  "iterations": [
    { "lens": "product_critic", "change": "Confirmed this is necessary — force mode is a key differentiator that is currently both insecure and broken. Value claim is specific and grounded in research findings across 2 cycles." },
    { "lens": "scope_optimizer", "change": "Removed 'add structured logging to launcher' from scope — not essential for security fix. Kept max_cycles as it prevents unbounded execution which is related to safe autonomous operation. Moved log rotation, cost tracking, and integrity checks to Out of Scope." },
    { "lens": "risk_analyzer", "change": "Added risk about claude -p prompt length limits. Added risk about temp file cleanup on SIGKILL. Added risk about skill system availability in claude -p mode." },
    { "lens": "feasibility", "change": "Refined Technical Approach to use temp file pattern instead of complex heredoc nesting, which is more robust. Confirmed approach aligns with existing bash patterns in the codebase." },
    { "lens": "experimentation", "change": "No change — this is a security fix, not an experiment. Correctly marked as N/A." }
  ]
}
```
