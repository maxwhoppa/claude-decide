# Fix Force Mode Launcher Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rewrite the force mode launcher to eliminate a shell injection vulnerability, ensure the operator runs with full SKILL.md guardrails, add paused state handling, and add a --max-cycles safety limit.

**Architecture:** Single bash script rewrite. The secure prompt is written to a temp file via single-quoted heredoc (no shell expansion possible), then passed to `claude -p` via `cat`. The prompt instructs the operator to read SKILL.md from disk rather than inlining it, so the operator gets the same phase router code path as interactive `/decide force`.

**Tech Stack:** Bash, claude CLI

---

### Task 1: Rewrite launcher.sh

**Files:**
- Modify: `skills/decide/scripts/launcher.sh` (full rewrite, lines 1-75)

- [ ] **Step 1: Write the new launcher script**

Replace the entire contents of `skills/decide/scripts/launcher.sh` with:

```bash
#!/bin/bash
# Claude Decide Launcher (Force Mode Only)
# Runs the autonomous operator loop with no user interaction.
# For default mode (interactive), run /decide in Claude Code.
#
# Usage: bash skills/decide/scripts/launcher.sh --force [--max-cycles N]
#
# Default mode: Run /decide in Claude Code

set -euo pipefail

# --- Argument Parsing ---
FORCE_MODE=false
MAX_CYCLES=50

while [[ $# -gt 0 ]]; do
  case "$1" in
    --force)
      FORCE_MODE=true
      shift
      ;;
    --max-cycles)
      if [[ -z "${2:-}" ]] || ! [[ "$2" =~ ^[0-9]+$ ]]; then
        echo "Error: --max-cycles requires a positive integer argument."
        exit 1
      fi
      MAX_CYCLES="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

if [[ "$FORCE_MODE" != "true" ]]; then
  echo "Claude Decide Launcher"
  echo ""
  echo "This launcher is for --force mode (fully autonomous, no user interaction)."
  echo ""
  echo "For default mode (interactive), run /decide in Claude Code."
  echo ""
  echo "Usage:"
  echo "  bash skills/decide/scripts/launcher.sh --force [--max-cycles N]"
  echo ""
  echo "Options:"
  echo "  --force           Run in fully autonomous mode (required)"
  echo "  --max-cycles N    Maximum number of cycles to run (default: 50)"
  exit 0
fi

# --- Temp File Setup (secure) ---
umask 077
PROMPT_FILE=$(mktemp /tmp/claude-decide-prompt.XXXXXX)

cleanup() {
  rm -f "$PROMPT_FILE"
}
trap cleanup EXIT

# Trap signals so Ctrl+C kills the whole loop, not just the inner process
trap "echo ''; echo 'Operator stopped.'; cleanup; exit 0" SIGINT SIGTERM

# --- Write Prompt to Temp File (no shell expansion due to single-quoted delimiter) ---
cat > "$PROMPT_FILE" <<'PROMPT_EOF'
You are Claude Operator running in force mode (fully autonomous, no user interaction).

Your instructions are in the file skills/decide/SKILL.md — read that file now for the full phase router, guardrails, and constraints.

Your current state is in .claude-operator/state.json — read that file now.

Execute the phase router exactly as documented in SKILL.md:
1. Check if .claude-operator/ exists. If not, run the Onboarding Phase (set mode to "force" during initialization).
2. Check if .claude-operator/stuck.json exists. If so, since this is force mode and there is no user to interact with, exit immediately so the launcher can handle it.
3. Read .claude-operator/state.json and execute the phase specified there.
4. Set mode to "force" in state.json for this cycle (auto-approve PRDs, skip user collaboration).
5. When the phase is complete, update state.json and exit.

IMPORTANT: Follow ALL guardrails from SKILL.md — no duplicates, no thrashing, no overbuilding, respect constraints, no mid-execution pivots. You have the same responsibilities as an interactive /decide force invocation.
PROMPT_EOF

echo "Claude Operator starting in FORCE mode (fully autonomous)..."
echo "Max cycles: ${MAX_CYCLES}"
echo "Press Ctrl+C to stop immediately."
echo "Run 'touch .claude-operator/stop' from another terminal to stop after the current cycle."
echo ""

CYCLE_COUNT=0

while true; do
  # Check max cycles limit
  if [[ "$CYCLE_COUNT" -ge "$MAX_CYCLES" ]]; then
    echo "Max cycles (${MAX_CYCLES}) reached. Operator stopped."
    exit 0
  fi

  # Check for graceful stop signal
  if [ -f .claude-operator/stop ]; then
    echo "Stop signal detected. Operator stopped gracefully."
    rm -f .claude-operator/stop
    exit 0
  fi

  # Check if operator is stuck
  if [ -f .claude-operator/stuck.json ]; then
    echo ""
    echo "============================================"
    echo "  OPERATOR IS STUCK"
    echo "  Open Claude Code to review and unblock."
    echo "============================================"
    echo ""
    # Wait until stuck.json is removed
    while [ -f .claude-operator/stuck.json ]; do
      sleep 5
      # Also check for stop signal while waiting
      if [ -f .claude-operator/stop ]; then
        echo "Stop signal detected while stuck. Operator stopped."
        rm -f .claude-operator/stop
        exit 0
      fi
    done
    echo "Unblocked. Resuming operator loop..."
    continue
  fi

  # Check if operator is paused
  if [ -f .claude-operator/state.json ]; then
    PAUSED_STATUS=$(python3 -c "import json; d=json.load(open('.claude-operator/state.json')); print(d.get('status',''))" 2>/dev/null || true)
    if [[ "$PAUSED_STATUS" == "paused" ]]; then
      echo "Operator is paused. Resume by editing state.json or re-running onboarding."
      exit 0
    fi
  fi

  # Run one operator cycle (non-interactive, secure prompt from temp file)
  CYCLE_COUNT=$((CYCLE_COUNT + 1))
  echo "--- Cycle ${CYCLE_COUNT} of ${MAX_CYCLES} ---"

  claude -p "$(cat "$PROMPT_FILE")"

  echo ""
  echo "Cycle ${CYCLE_COUNT} complete. Starting next cycle..."
  echo ""
done
```

- [ ] **Step 2: Syntax check the script**

Run: `bash -n skills/decide/scripts/launcher.sh`
Expected: No output (clean syntax)

- [ ] **Step 3: Run shellcheck**

Run: `shellcheck skills/decide/scripts/launcher.sh`
Expected: No errors. Warnings about `python3 -c` are acceptable.

- [ ] **Step 4: Verify --force is required**

Run: `bash skills/decide/scripts/launcher.sh 2>&1`
Expected: Output contains "This launcher is for --force mode" and exits 0.

- [ ] **Step 5: Verify --max-cycles parsing**

Run: `bash skills/decide/scripts/launcher.sh --force --max-cycles abc 2>&1`
Expected: Output contains "Error: --max-cycles requires a positive integer argument." and exits 1.

- [ ] **Step 6: Verify no unquoted variable interpolation in prompt**

Run: `grep -n '\${' skills/decide/scripts/launcher.sh`
Expected: All `${VAR}` occurrences are either (a) inside the argument parsing section, (b) in echo statements, or (c) in the `claude -p "$(cat "$PROMPT_FILE")"` line. NONE are inside the heredoc between `<<'PROMPT_EOF'` and `PROMPT_EOF`.

- [ ] **Step 7: Verify heredoc uses single-quoted delimiter**

Run: `grep "PROMPT_EOF" skills/decide/scripts/launcher.sh`
Expected: The opening delimiter is `<<'PROMPT_EOF'` (single-quoted), not `<<PROMPT_EOF`.

- [ ] **Step 8: Commit**

```bash
git add skills/decide/scripts/launcher.sh
git commit -m "feat: fix force mode launcher security and instruction loading (PRD-002)"
```
