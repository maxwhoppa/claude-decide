#!/bin/bash
# Claude Operator Launcher
# Manages the self-restart loop between operator cycles.
# Usage: bash launcher.sh [--force]

set -euo pipefail

MODE="default"
if [[ "${1:-}" == "--force" ]]; then
  MODE="force"
fi

# Trap signals so Ctrl+C kills the whole loop, not just the inner process
trap "echo ''; echo 'Operator stopped.'; exit 0" SIGINT SIGTERM

echo "Claude Operator starting in ${MODE} mode..."
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
    echo "  Run 'claude decide' to review and unblock."
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

  # Run one operator cycle
  if [[ "$MODE" == "force" ]]; then
    claude -p "You are Claude Operator. Read .claude-operator/state.json and execute the current phase. Mode: force (auto-approve PRDs, skip user collaboration). When the phase is complete, update state.json and exit."
  else
    claude -p "You are Claude Operator. Read .claude-operator/state.json and execute the current phase. Mode: default (pause for user collaboration at PRD stage). When the phase is complete, update state.json and exit."
  fi

  echo ""
  echo "Cycle complete. Starting next cycle..."
  echo ""
done
