#!/bin/bash
# Claude Operator Launcher (Force Mode Only)
# Runs the autonomous operator loop with no user interaction.
# For default mode (interactive), run from Claude Code directly.
#
# Usage: bash launcher.sh --force
#
# Default mode: Open Claude Code in your project and say "run the operator"

set -euo pipefail

if [[ "${1:-}" != "--force" ]]; then
  echo "Claude Operator Launcher"
  echo ""
  echo "This launcher is for --force mode (fully autonomous, no user interaction)."
  echo ""
  echo "For default mode (interactive), open Claude Code in your project and say:"
  echo "  > run the operator"
  echo ""
  echo "For force mode:"
  echo "  bash launcher.sh --force"
  exit 0
fi

# Trap signals so Ctrl+C kills the whole loop, not just the inner process
trap "echo ''; echo 'Operator stopped.'; exit 0" SIGINT SIGTERM

echo "Claude Operator starting in FORCE mode (fully autonomous)..."
echo "Press Ctrl+C to stop immediately."
echo "Run 'touch .claude-operator/stop' from another terminal to stop after the current cycle."
echo ""

while true; do
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

  # Run one operator cycle (non-interactive)
  claude -p "You are Claude Operator. Read .claude-operator/state.json and execute the current phase. Mode: force (auto-approve PRDs, skip user collaboration). When the phase is complete, update state.json and exit."

  echo ""
  echo "Cycle complete. Starting next cycle..."
  echo ""
done
