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
AUTO_MODE=false
AUTO_THRESHOLD="0.75"
MAX_CYCLES=50

while [[ $# -gt 0 ]]; do
  case "$1" in
    --force)
      FORCE_MODE=true
      shift
      ;;
    --auto)
      AUTO_MODE=true
      shift
      ;;
    --auto=*)
      AUTO_MODE=true
      AUTO_THRESHOLD="${1#--auto=}"
      if ! [[ "$AUTO_THRESHOLD" =~ ^0(\.[0-9]+)?$|^1(\.0+)?$ ]]; then
        echo "Error: --auto threshold must be a number between 0.0 and 1.0 (got: $AUTO_THRESHOLD)"
        exit 1
      fi
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

if [[ "$FORCE_MODE" != "true" ]] && [[ "$AUTO_MODE" != "true" ]]; then
  echo "Claude Decide Launcher"
  echo ""
  echo "This launcher is for --force or --auto mode (no default/interactive mode)."
  echo ""
  echo "For default mode (interactive), run /decide in Claude Code."
  echo ""
  echo "Usage:"
  echo "  bash skills/decide/scripts/launcher.sh --force [--max-cycles N]"
  echo "  bash skills/decide/scripts/launcher.sh --auto[=THRESHOLD] [--max-cycles N]"
  echo ""
  echo "Options:"
  echo "  --force           Run in fully autonomous mode"
  echo "  --auto            Run in auto-approval mode (threshold 0.75)"
  echo "  --auto=N          Run in auto-approval mode with custom threshold (0.0-1.0)"
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
if [[ "$AUTO_MODE" == "true" ]]; then
  PROMPT_MODE="auto"
  PROMPT_MODE_INSTRUCTION="Set mode to \"auto\" and auto_threshold to ${AUTO_THRESHOLD} in state.json for this cycle. PRDs with priority_score >= ${AUTO_THRESHOLD} are auto-approved; lower-scored PRDs route to collaboration (but since this is a non-interactive launcher, resolve collaboratively by auto-approving with a note)."
else
  PROMPT_MODE="force"
  PROMPT_MODE_INSTRUCTION="Set mode to \"force\" in state.json for this cycle (auto-approve PRDs, skip user collaboration)."
fi

cat > "$PROMPT_FILE" <<PROMPT_EOF
You are Claude Operator running in ${PROMPT_MODE} mode.

Your instructions are in the file skills/decide/SKILL.md — read that file now for the full phase router, guardrails, and constraints.

Your current state is in .claude-operator/state.json — read that file now.

Execute the phase router exactly as documented in SKILL.md:
1. Check if .claude-operator/ exists. If not, run the Onboarding Phase (set mode to "${PROMPT_MODE}" during initialization).
2. Check if .claude-operator/stuck.json exists. If so, since this is a non-interactive launcher, exit immediately so the launcher can handle it.
3. Read .claude-operator/state.json and execute the phase specified there.
4. ${PROMPT_MODE_INSTRUCTION}
5. When the phase is complete, update state.json and exit.

IMPORTANT: Follow ALL guardrails from SKILL.md — no duplicates, no thrashing, no overbuilding, respect constraints, no mid-execution pivots. You have the same responsibilities as an interactive /decide ${PROMPT_MODE} invocation.
PROMPT_EOF

if [[ "$AUTO_MODE" == "true" ]]; then
  echo "Claude Operator starting in AUTO mode (threshold: ${AUTO_THRESHOLD})..."
else
  echo "Claude Operator starting in FORCE mode (fully autonomous)..."
fi
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
