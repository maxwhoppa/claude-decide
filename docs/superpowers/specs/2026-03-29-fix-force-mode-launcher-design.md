# Fix Force Mode Launcher - Design Spec

## Problem

The force mode launcher (`skills/decide/scripts/launcher.sh`) has two critical issues:

1. **Shell injection vulnerability**: `SKILL_CONTENTS=$(cat skills/decide/SKILL.md)` followed by `"${SKILL_CONTENTS}"` inside a `claude -p` string means any shell metacharacters in SKILL.md (backticks, `$()`, `$(())`) execute as shell commands.
2. **Bypassed guardrails**: The inline prompt wraps SKILL.md in a bare "execute the current phase" instruction that sidesteps the phase router's guardrails, stuck recovery, and stagnation checks.

Additionally:
- No handling for `"status": "paused"` in state.json (causes infinite loop)
- No cycle limit (unbounded execution)

## Design

### Argument Parsing

Replace the simple `$1 == "--force"` check with a loop that parses:
- `--force` (required to run)
- `--max-cycles N` (optional, default 50)

Show usage help if `--force` is not present.

### Secure Prompt Construction

Use a temp file approach:

```
umask 077
PROMPT_FILE=$(mktemp /tmp/claude-decide-prompt.XXXXXX)
trap cleanup EXIT SIGINT SIGTERM
```

Write the prompt using a heredoc with **single-quoted delimiter** (`<<'PROMPT_EOF'`) to prevent all shell expansion. The prompt instructs the operator to:
1. Read `skills/decide/SKILL.md` for full instructions
2. Read `.claude-operator/state.json` for current phase
3. Execute the phase router logic with mode set to "force"
4. Update state.json and exit when phase is complete

This keeps the prompt small (no SKILL.md inlining) and secure (no variable interpolation).

### Cycle Execution

Pass prompt to claude via: `claude -p "$(cat "$PROMPT_FILE")"`

The `cat` output is safely quoted. The prompt file itself contains no shell metacharacters because it was written via single-quoted heredoc.

Track cycle count with a counter variable. After each cycle, increment and check against max_cycles.

### Paused State Check

Inside the main loop, after the stop file and stuck.json checks, read state.json and check for `"status": "paused"`. If found, print message and exit 0.

### Preserved Functionality

All existing features are kept:
- Ctrl+C handling (SIGINT/SIGTERM trap)
- Graceful stop via `.claude-operator/stop` file
- Stuck detection and wait loop for `.claude-operator/stuck.json`

### Cleanup

The trap function removes the temp file on any exit path (normal, signal, error).

## Files Changed

- `skills/decide/scripts/launcher.sh` - full rewrite of the script

## Testing

- `bash -n` syntax check
- `shellcheck` static analysis
- Verify `--force` flag is required
- Verify usage output without `--force`
- Verify no unquoted `${VAR}` interpolation in any string passed to `claude -p`
- Verify heredoc uses single-quoted delimiter
